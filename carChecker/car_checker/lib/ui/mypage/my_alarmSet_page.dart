import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../url.dart';

class MyAlarmsetPage extends StatefulWidget {
  const MyAlarmsetPage({super.key});

  @override
  State<MyAlarmsetPage> createState() => _MyAlarmsetPageState();
}

class _MyAlarmsetPageState extends State<MyAlarmsetPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  dynamic userId = '';
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
  }

  // 푸시알람 함수
  Future<void> pushAlarm() async {
    userId = await storage.read(key: 'userId');
    var uri = Uri.parse(_front_url+'/api/v1/notifications/$userId/toggle-push');

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };

    var response = await http.put(uri, headers: headers);

    var resultData = jsonDecode(response.body);
    if (resultData['code'] == 1) {
      // 푸시알람 성공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('푸시알람 성공')),
      );
    } else {
      // 푸시알람 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('푸시알람 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // 시스템 pop 허용
      onPopInvokedWithResult: (didPop, result) {
        // 시스템이 pop을 하지 않은 경우 (예: 루트 페이지)
        if (!didPop && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // 이전 페이지로 이동
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Container(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back,
                  size: 35,
                  weight: 700,
                  color: Colors.black,
                )),
          ),
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(16, 5, 0, 30),
                child: Text('알람 설정',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('푸시 수신', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),),
                        SizedBox(height: 5,),
                        Text('나의 필터 정보를 실시간으로 받아보세요.', style: TextStyle(fontSize: 13, color: Color(0xff404040)),),
                      ],
                    ),
                    CupertinoSwitch(
                      value: _isChecked,
                      activeColor: CupertinoColors.activeGreen,
                      onChanged: (bool? value) {
                        pushAlarm();
                        setState(() {
                          _isChecked = value ?? false;
                        });
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}