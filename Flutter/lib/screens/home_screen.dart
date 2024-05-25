import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  @override
  Widget build(BuildContext context) {



    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Text('Smart Window'),
        centerTitle: true,

        // leading: IconButton(
        //   onPressed: () {
        //     // 뒤로가기
        //   },
        //   icon: Icon(
        //     Icons.menu,
        //   ),
        // ),
      ),
      drawer: Drawer( // Drawer를 위해선 appBar에 leading 코드가 없어야 함
        child: ListView(
          padding: EdgeInsets.zero, // SafeArea까지 Drawer가 모두 채워지도록 설정

          children: [
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.lightBlue,
              ),
              accountName: Text('박세민'),
              accountEmail: Text('tpals1127@naver.com'),

              // style
              decoration: BoxDecoration(
                color: Colors.lightBlue[200],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.0),
                  bottomRight: Radius.circular(10.0),
                ),
              ),
            ),

            // ListTile
            ListTile(
              leading: Icon(Icons.settings),
              iconColor: Colors.lightBlue,
              focusColor: Colors.lightBlue,
              title: Text(
                  '설정'
              ),
              onTap: () {},
            )
          ],
        ),
      ),

      body: SafeArea(
        top: true,

        child: Container(
          child: Center(
            child: Text('연결된 기기가 없습니다'),
          ),
        )
      ),
    );
  }
}