import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../chat_message.dart';

class DeviceControlScreen extends StatefulWidget {
  const DeviceControlScreen({Key? key}) : super(key: key);

  @override
  State<DeviceControlScreen> createState() => _DeviceControlScreen();
}

class _DeviceControlScreen extends State<DeviceControlScreen> with TickerProviderStateMixin {
  BluetoothDevice? connectedDevice; // 현재 연결되어 있는 기기 정보를 저장
  late StreamSubscription<OnConnectionStateChangedEvent> _connectionStateSubscription; // 블루투스 연결 상태 감지

  // 입력한 메시지를 저장하는 리스트
  final List<ChatMessage> _message = <ChatMessage>[];

  // 텍스트필드 제어용 컨트롤러
  final TextEditingController _textController = TextEditingController();

  // 텍스트필드에 입력된 데이터의 존재 여부
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();

    // 현재 연결된 기기가 있다면? => connectedDevice에 저장
    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
      connectedDevice = FlutterBluePlus.connectedDevices.first;
      print("**연결된 기기 정보**");
      print(connectedDevice);
      print("");
    }

    // 연결 상태에 대한 구독 설정
    _connectionStateSubscription = FlutterBluePlus.events.onConnectionStateChanged.listen((state) {
      print("**구독 정보**");
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
    for (ChatMessage message in _message) {
      message.animationController.dispose();
    }
    super.dispose();
  }

  // 메시지 전송할 때 호출되는 함수
  void handleSubmitted(String text) {
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
        duration: Duration(milliseconds: 700),
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
          icon: Icon(Icons.keyboard_hide),
        ),
        Flexible(
          child: TextField(
            controller: _textController,
            onChanged: (text) {
              _isComposing = text.isNotEmpty;
            },
            onSubmitted: _isComposing ? handleSubmitted : null,
            decoration: InputDecoration(
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
        padding: EdgeInsets.all(8.0),
        reverse: true,
        itemCount: _message.length,
        itemBuilder: (BuildContext context, int index) => _message[index]
      ),
    );
  }

  // 연결된 기기 정보 보여주는 위젯
  Widget buildDeviceInfo(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(connectedDevice!.platformName,
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,

            )),
            Text(connectedDevice!.isConnected ? "연결됨" : "연결안됨",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.normal,
              )
            ),
            SizedBox(height: 50.0),
            Text("Serial Terminal",
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 20.0,  // shadow blur
                    color: Colors.lightBlue, // shadow color
                    offset: Offset(2.0,2.0), // how much shadow will be shown
                  ),
                ],
              )
            ),
            Divider(height: 1.0),

            buildMessageOutputField(context),
            Divider(height: 1.0),
            buildMessageInputField(context),

          ],
        ),
      )
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
      // return const Scaffold(
      //   body: Center(
      //     child: Text("기기가 연결된 상태입니다.", style: TextStyle(color: Colors.green),),
      //   ),
      // );
      return buildDeviceInfo(context);
    }

  }
}