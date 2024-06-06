import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:smart_window/screens/bluetooth_off_screen.dart';
import 'package:smart_window/screens/device_control_screen.dart';
import 'package:smart_window/screens/home_screen.dart';
import 'package:smart_window/screens/scan_screen.dart';

import 'flutterLocalNotification.dart';


Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 블루투스가 지원되지 않는 디바이스라면 앱이 종료됨
  // 블루투스 권한 요청 팝업은 이 부분을 실행하면서 나타나게 됨
  if (await FlutterBluePlus.isSupported == false) {
    print("Bluetooth not supported by this device");
    return;
  }

  // 안드로이드 기기의 블루투스가 꺼져있다면 켜도록 변경
  // turn on bluetooth ourself if we can
  // for iOS, the user controls bluetooth enable/disable
  if (Platform.isAndroid) {
    print("Here is ANDROID");
    await FlutterBluePlus.turnOn();
  }

  runApp(const SmartWindowApp());
}

class SmartWindowApp extends StatefulWidget {
  const SmartWindowApp({super.key});

  @override
  State<SmartWindowApp> createState() => _SmartWindowAppState();
}

class _SmartWindowAppState extends State<SmartWindowApp> {
  BluetoothAdapterState _adapterState = FlutterBluePlus.adapterStateNow;

  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;

  @override
  void initState() {
    FlutterLocalNotification.init();
    FlutterLocalNotification.requestNotificationPermission();

    FocusManager.instance.primaryFocus?.unfocus();
    _adapterStateStateSubscription = FlutterBluePlus.adapterState.listen((state) {
          _adapterState = state;
          if (mounted) {
            setState(() => {});
          }
        });

    super.initState();
  }

  @override
  void dispose() {
    _adapterStateStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget screens = _adapterState == BluetoothAdapterState.on ? const ScanScreen() : BluetoothOffScreen(adapterState: _adapterState);

    FlutterNativeSplash.remove();

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: DefaultTabController(
          initialIndex: 1,
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.lightBlue,
              title: const Text('Smart Window'),
              // leading: IconButton( <**뒤로가기 버튼**>
              //   icon: const Icon(Icons.arrow_back_ios),
              //   onPressed: () {
              //     Navigator.pop(context);
              //   },
              // ),
              centerTitle: true,
              bottom: const TabBar(
                  tabs: <Widget>[
                    Tab(
                      icon: Icon(Icons.bluetooth),
                    ),
                    Tab(
                      icon: Icon(Icons.cloud_outlined),
                    )
                  ]),
            ),

            body: TabBarView(
                children: [
                  screens,
                  const DeviceControlScreen(),
                ]),
          ),
        ),
      ),
    );
  }
}

