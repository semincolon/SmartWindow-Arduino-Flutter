import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:smart_window/flutterLocalNotification.dart';

import '../chat_message.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({super.key});

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreen();
}

class _DeviceControlScreen extends State<DeviceControlScreen> with TickerProviderStateMixin {
  BluetoothDevice? connectedDevice; // 현재 연결되어 있는 기기 정보를 저장
  late StreamSubscription<OnConnectionStateChangedEvent> _connectionStateSubscription; // 블루투스 연결 상태 감지

  StreamSubscription<List<int>>? messageSubscription;
  late BluetoothCharacteristic characteristic;
  bool isOpened = false; // 창문의 열림, 닫힘 상태를 나타냄
  bool isAuto = false; // 환기 모드의 On, Off 상태를 나타냄
  bool responseReceived = false; // 아두이노로부터 응답을 받았는지를 나타냄
  Timer? responseTimer; // 응답을 기다리는 타이머

  // 입력한 메시지를 저장하는 리스트
  final List<ChatMessage> _message = <ChatMessage>[];

  // 텍스트필드 제어용 컨트롤러
  final TextEditingController _textController = TextEditingController();

  // 텍스트필드에 입력된 데이터의 존재 여부
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    // 현재 연결된 기기가 있다면? => connectedDevice에 저장 + 데이터 읽기 쓰기 준비
    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
      connectedDevice = FlutterBluePlus.connectedDevices.first;
      discoverServices();

      print("**연결된 기기 정보**");
      print(connectedDevice);
      print("");
    }

    // 연결 상태에 대한 구독 설정
    _connectionStateSubscription = FlutterBluePlus.events.onConnectionStateChanged.listen((state) {
      print("**연결 해제됨**");
      print(state.device);
      print(state.connectionState);
      print(state.device.platformName);
      print('');
      setState(() {
        connectedDevice = null;
      });
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    messageSubscription?.cancel();
    for (ChatMessage message in _message) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  // 메시지 전송할 때 호출되는 함수
  void handleSubmitted(String text) {
    writeData(text);
    _textController.clear();
    _isComposing = false;
    print("message: ");
    for (ChatMessage message in _message) {
      print(message.text);
    }

    ChatMessage message = ChatMessage(
      text: text,
      animationController: AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )
    );

    setState(() {
      _message.insert(0, message);
    });

    message.animationController.forward();
  }

  // 메시지 입력창 만드는 위젯
  Widget buildMessageInputField(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {
            print("키보드 내리기 버튼");
            FocusManager.instance.primaryFocus?.unfocus();
          },
          icon: const Icon(Icons.keyboard_hide),
        ),
        Flexible(
          child: TextField(
            controller: _textController,
            onChanged: (text) {
              _isComposing = text.isNotEmpty;
            },
            onSubmitted: _isComposing ? handleSubmitted : null,
            decoration: const InputDecoration(
              hintText: '여기에 입력',
              border: InputBorder.none,
            ),
          ),
        ),
        IconButton(
            onPressed: () {
              print("전송 버튼");
              _isComposing ? handleSubmitted(_textController.text) : null;
            },
            icon: Icon(Icons.send)),
      ],
    );
  }

  // 메시지 출력창 만드는 위젯
  Widget buildMessageOutputField(BuildContext context) {
    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        reverse: true,
        itemCount: _message.length,
        itemBuilder: (BuildContext context, int index) => _message[index]
      ),
    );
  }

  // 연결된 기기 정보 보여주는 위젯
  Widget buildDeviceInfo(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: true,
      body: Container(
        padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(connectedDevice!.platformName,
              style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,

            )),
            Text(connectedDevice!.isConnected ? "연결됨" : "연결안됨",
              style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.normal,
              )
            ),
            const SizedBox(height: 50.0),
            const Divider(height: 1.0),

            // buildMessageOutputField(context),
            // const Divider(height: 1.0),
            // buildMessageInputField(context),
            buildOpenCloseButton(context),
            const Divider(height: 1.0),
            buildAutoModeButton(context),
          ],
        ),
      )
    );
  }

  // 자동 모드 버튼
  Widget buildAutoModeButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
                "자동 모드",
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
            ),
            IconButton(
                onPressed: () async {
                  if (isAuto == true) {
                    if (await showOkCancelDialog("경고", "자동 개폐 모드가 비활성화됩니다. 계속하시겠습니까?")) {
                      // 확인을 누른 경우에만 비활성화
                      writeData("OFF");
                    }
                  } else {
                    writeData("ON");
                  }
                },
                icon: Icon(
                  Icons.power_settings_new,
                  color: isAuto ? Colors.green : Colors.red,
                  size: 44.0,
                )),
          ],
        ),
      )
    );
  }

  // 창문 열기, 닫기 버튼
  Widget buildOpenCloseButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text("창문 상태 : ${isOpened ? '열림' : '닫힘'}",
              style: const TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () async {
                    if (isOpened == false) {
                      if (isAuto == true) {
                        if (await showOkCancelDialog("경고", "수동 조작할 경우 자동 모드가 꺼집니다. 계속하시겠습니까?")) {
                          writeData("OPEN");
                        }
                      } else {
                        writeData("OPEN");
                      }
                    } else {
                      showMyDialog("오류", "창문이 이미 열려있습니다");
                    }
                  },
                  child: const Text(
                    "OPEN"
                  ),
              ),
              const SizedBox(width: 20.0,),
              ElevatedButton(
                  onPressed: () async {
                    if (isOpened == true) {
                      if (isAuto == true) {
                        if (await showOkCancelDialog("경고", "수동 조작할 경우 자동 모드가 꺼집니다. 계속하시겠습니까?")) {
                          writeData("CLOSE");
                        }
                      } else {
                        writeData("CLOSE");
                      }
                    } else {
                      showMyDialog("오류", "창문이 이미 닫혀있습니다");
                    }
                  },
                  child: const Text(
                    "CLOSE"
                  )
              )
            ],
          ),
        ],
      ),
    );
  }

  // 아두이노와 통신을 위한 서비스를 찾고, 그 안의 특성을 등록하는 함수
  Future<void> discoverServices() async {
    List<BluetoothService> services = await connectedDevice!.discoverServices();
    characteristic = services[0].characteristics.first;
    writeData("OK+CONN");
    messageSubscription = characteristic.onValueReceived.listen((value) {
      // print("Received Data: ${String.fromCharCodes(value)}"); Byte -> String 변환 코드
      print("Received Data(original): $value");
      responseReceived = true;
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // 다이얼로그 닫기
      }
      switch(value[0]) {
        case 1:
          print("UNO R3 >> 연결되었습니다");
          showToastMessage(true, "동기화 완료");
          break;
        case 10:
          print("UNO R3 >> 창문을 열었습니다");
          showToastMessage(true, "창문을 열었습니다");
          FlutterLocalNotification.showNotification('스마트 창문', '창문을 열었습니다');
          break;
        case 11:
          print("UNO R3 >> 창문을 열었습니다(실내 대기질 나쁨)");
          showToastMessage(true, "실내 대기질이 좋지 않습니다. 창문을 엽니다");
          FlutterLocalNotification.showNotification('스마트 창문', "실내 대기질이 좋지 않습니다. 창문을 엽니다");
          break;
        case 12:
          print("UNO R3 >> 창문을 열었습니다(화재 발생)");
          showToastMessage(true, "화재가 발생했습니다. 창문을 엽니다");
          FlutterLocalNotification.showNotification('스마트 창문', "화재가 발생했습니다. 창문을 엽니다");
          break;
        case 20:
          print("UNO R3 >> 창문을 닫았습니다");
          showToastMessage(true, "창문을 닫았습니다");
          FlutterLocalNotification.showNotification('스마트 창문', '창문을 닫았습니다');
          break;
        case 21:
          print("UNO R3 >> 창문을 닫았습니다(비내림)");
          showToastMessage(true, "비가 내리고 있습니다. 창문을 닫습니다");
          FlutterLocalNotification.showNotification('스마트 창문', "비가 내리고 있습니다. 창문을 닫습니다");
          break;
        case 22:
          print("UNO R3 >> 창문을 닫았습니다(미세먼지 나쁨)");
          showToastMessage(true, "미세먼지가 많습니다. 창문을 닫습니다");
          FlutterLocalNotification.showNotification('스마트 창문', "미세먼지가 많습니다. 창문을 닫습니다");
          break;
        case 30:
          print("UNO R3 >> 자동모드 ON");
          showToastMessage(true, "자동 모드가 켜졌습니다");
          FlutterLocalNotification.showNotification('스마트 창문', "자동 모드가 켜졌습니다");
          break;
        case 31:
          print("UNO R3 >> 자동모드 OFF");
          showToastMessage(true, "자동 모드가 꺼졌습니다");
          FlutterLocalNotification.showNotification('스마트 창문', "자동 모드가 꺼졌습니다");
          break;
        case 40:
          print("UNO R3 >> 수동으로 창문 OPEN");
          showToastMessage(true, "수동으로 창문이 열렸습니다.");
          FlutterLocalNotification.showNotification('스마트 창문', '수동으로 창문이 열렸습니다');
          break;
        case 41:
          print("UNO R3 >> 수동으로 창문 CLOSE");
          showToastMessage(true, "수동으로 창문이 닫혔습니다.");
          FlutterLocalNotification.showNotification('스마트 창문', '수동으로 창문이 닫혔습니다');
          break;
        default:
          FlutterLocalNotification.showNotification('스마트 창문', 'Uno R3 sends something');
      }
      setState(() {
        isOpened = value[1] == 1;
        isAuto = value[2] == 1;
      });
    });

    // 연결이 해제되면 메시지 수신 구독도 해제함
    connectedDevice!.cancelWhenDisconnected(messageSubscription!);

    // 아두이노 -> 스마트폰으로의 데이터 전송을 감지하는 것을 활성화
    await characteristic.setNotifyValue(true);
  }

  // 스마트폰 -> 아두이노 데이터 전송 함수
  void writeData(String data) {
    showDialog(
        context: context,
        builder: (BuildContext context) => const Dialog(
          child: Padding(
            padding: EdgeInsets.all(70.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ),
        )
    );
    responseReceived = false;
    print("Send Data: $data");
    characteristic.write(data.codeUnits);

    // 5초 동안 응답이 없으면 다이얼로그 닫기 및 메시지 출력
    responseTimer = Timer(const Duration(seconds: 5), () {
      if (!responseReceived) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // 다이얼로그 닫기
        }
        showToastMessage(false, "응답이 없습니다. 다시 시도해주세요.");
      }
    });
  }

  // AlertDialog 띄우는 함수
  void showMyDialog(String title, String text) {
    showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(text),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
    );
  }

  // 확인, 취소 Dialog 띄우는 함수
  Future<bool> showOkCancelDialog(String title, String text) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(text),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('취소'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text('확인'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        }
    ).then((value) => value ?? false);
  }

  // ToastMessage 띄우는 함수
  void showToastMessage(bool type, String text) {
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: type ? Colors.green : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (connectedDevice == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const Text("연결된 기기가 없습니다.", style: TextStyle(color: Colors.red),),
              ElevatedButton(onPressed: () {
                DefaultTabController.of(context).animateTo(0);
              }, child: const Text("기기 연결 화면으로 이동")),
            ],
          ),
        ),
      );
    } else {
      return buildDeviceInfo(context);
    }
  }
}

