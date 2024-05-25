import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.adapterState}) : super(key: key);

  final BluetoothAdapterState? adapterState;

  // 블루투스 꺼짐 아이콘 위젯
  Widget buildBluetoothOffIcon(BuildContext context) {
    return const Icon(
      Icons.bluetooth_disabled,
      size: 200.0,
      color: Colors.blueGrey,
    );
  }

  // 블루투스 상태 설명 텍스트 위젯
  Widget buildTitle(BuildContext context) {
    String? state = adapterState?.toString().split(".").last;
    return Text(
      state != null ? '설정에서 블루투스를 켜주세요' : '블루투스를 이용할 수 없습니다',
      style: Theme.of(context).primaryTextTheme.titleSmall?.copyWith(color: Colors.black),
    );
  }

  // 기기가 안드로이드라면 블루투스 켬 버튼 위젯
  Widget buildTurnOnButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: ElevatedButton(
        child: const Text('TURN ON'),
        onPressed: () async {
          try {
            if (Platform.isAndroid) {
              await FlutterBluePlus.turnOn();
            }
          } catch (e) {
            // Snackbar.show(ABC.a, prettyException("Error Turning On:", e), success: false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildBluetoothOffIcon(context),
            buildTitle(context),
            const SizedBox(height: 100.0,),
            if (Platform.isAndroid) buildTurnOnButton(context),
          ],
        ),
      )
    );
  }
}