import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  BluetoothDevice? connectedDevice; // 현재 연결되어 있는 기기 정보를 저장
  late ScanResult connectedScanResult; // 현재 연결된 기기의 스캔 정보를 저장
  List<ScanResult> _scanResults = []; // 전체 기기 검색 결과를 저장
  bool _isScanning = false; // 현재 검색 중인 상태라면 true, 검색 중이 아니라면 false
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription; // 스캔 결과를 구독
  late StreamSubscription<bool> _isScanningSubscription; // 스캔 상태를 구독

  @override
  void initState() {
    super.initState();
    print("InitState()"); // DEBUG

    // 현재 연결된 기기가 있다면? => connectedDevice에 저장
    if (FlutterBluePlus.connectedDevices.isNotEmpty) {
      connectedDevice = FlutterBluePlus.connectedDevices.first;
    }

    // 블루투스 기기가 검색될 때마다 호출
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = [];
      for (ScanResult r in results) {
        if (r.device.platformName.isNotEmpty && r.advertisementData.connectable == true) {
          _scanResults.add(r);
        }
      }
      if (connectedDevice != null) {
        for (ScanResult r in _scanResults) {
          if (connectedDevice!.platformName == r.device.platformName) {
            connectedScanResult = r;
            _scanResults.remove(r);
            break;
          }
        }
      }
      if (mounted) {
        setState(() {});
      }
    });

    // 검색 <--> 중지 상태가 변할 때마다 호출
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });

  }

  @override
  void dispose() {
    print("DISPOSE@@@@@@@@@@@@@@@@@@@@");
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  // '검색' 버튼 누르면 실행되는 함수
  Future<void> onScanPressed(context) async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      Fluttertoast.showToast(
        msg: "검색 오류",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  // '중지' 버튼 누르면 실행되는 함수
  Future<void> onStopPressed(context) async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Fluttertoast.showToast(
        msg: "중지 오류",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  // '검색', '중지' 버튼
  Widget buildScanButton(BuildContext context) {
    if (_isScanning == false) {
      return ElevatedButton( // 검색 중이 아니라면? => '검색' 버튼
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
        onPressed: () {onScanPressed(context);},
        child: const Text(
          "검색",
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return ElevatedButton( // 검색 중이라면? => '중지' 버튼
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
        ),
        onPressed: () {onStopPressed(context);},
        child: const Text(
          "중지",
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.white,
          ),
        ),
      );
    }

  }

  // 현재 연결된 디바이스 보여 줄 위젯
  Widget buildConnectedDevice(BuildContext context) {
    return Column(
      children: [
        const Text(
          "연결된 기기",
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),

        connectedDevice != null ? Container(
          margin: const EdgeInsets.all(10.0),
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
          height: 100.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Colors.grey,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.bluetooth),
              const SizedBox(width: 10.0),
              SizedBox(
                width: 160.0,
                child: Text(
                  connectedDevice!.platformName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
              ),
              ElevatedButton( // '연결 해제' 버튼
                onPressed: () async {
                  await connectedDevice!.disconnect();
                  setState(() {
                    _scanResults.add(connectedScanResult);
                    print("연결 해제");
                    connectedDevice = null;
                  });
                },
                child: const Text(
                    "연결 해제"
                ),
              ),
            ],
          )
        ) : Container()
      ],
    );
  }

  // '연결' 버튼을 눌렀을 때 실행되는 함수
  Future<void> onConnectPressed(ScanResult scanResult) async {
    // '연결중' 임을 나타내는 Indicator 표시
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

    // 선택한 기기와 연결 시도
    try {
      await scanResult.device.connect(timeout: const Duration(seconds: 5));

      // 연결 성공하면 이 아래 부분이 실행됨
      Fluttertoast.showToast(
        msg: "연결에 성공하였습니다",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
      );

      // 이미 연결된 기기가 있었다면 연결 해제
      if (connectedDevice != null) {
        _scanResults.add(connectedScanResult);
        print("해재 하고 연결");
        await connectedDevice!.disconnect();
      }

      setState(() {
        // 새로운 기기로 대체
        connectedDevice = scanResult.device;
        connectedScanResult = scanResult;
        _scanResults.remove(scanResult);
      });
    } catch (e) {
      // 연결 실패하면 이 부분이 실행됨
      print(e.toString());
      Fluttertoast.showToast(
        msg: "연결에 실패하였습니다",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      Navigator.pop(context);
    }
  }

  // 연결 가능한 기기 목록 보여줄 위젯
  Widget buildScanDevices(BuildContext context) {
    return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text(
                "연결 가능한 기기",
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              buildScanButton(context),
              CircularProgressIndicator(
                strokeCap: StrokeCap.round,
                color: _isScanning ? Colors.lightBlue : Colors.transparent,
              ),
            ],
          ),

          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (BuildContext context, int index) {
                var scanResult = _scanResults[index];

                return Container(
                  margin: const EdgeInsets.all(10.0),
                  padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                  height: 100.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.grey,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.bluetooth),
                      const SizedBox(width: 10.0),
                      SizedBox(
                        width: 160.0,
                        child: Text(
                          scanResult.device.platformName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      ElevatedButton(
                          onPressed: () {
                            onConnectPressed(scanResult);
                          },
                          child: const Text(
                              "연결"
                          ),
                      ),
                    ],
                  ),
                );
              }
            )
          )
        ]
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: buildConnectedDevice(context),
          ),
          Expanded(
            flex: 3,
            child: buildScanDevices(context),
          )
        ],
      ),
    );
  }
}