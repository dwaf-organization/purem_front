import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../url.dart';
import '../login_page.dart';

class AuthCarNumRegistrationPage extends StatefulWidget {
  final Map<String, dynamic> dataList;
  const AuthCarNumRegistrationPage({super.key, required this.dataList});

  @override
  State<AuthCarNumRegistrationPage> createState() => _AuthCarNumRegistrationPageState();
}

class _AuthCarNumRegistrationPageState extends State<AuthCarNumRegistrationPage> {
  TextEditingController carNum = TextEditingController();

  static final storage = FlutterSecureStorage();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('차량 번호를',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.black),),
                    Text('입력해주세요.',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.black),),
                  ],
                ),
              ),
              Container(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 100, 0, 10),
                        padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '차량 번호 입력',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400),
                            ),
                            TextFormField(
                              controller: carNum,
                              style: TextStyle(decorationThickness: 0),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "차량 번호를 입력해주세요. 예) 11가 1111",
                                hintStyle: TextStyle(
                                  color: Color(0xffD0D0D0),
                                  fontSize: 16,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xffD0D0D0),),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Color(0xffD0D0D0), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "차량번호는 필수 입력 항목입니다.";
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(16, 20, 16, 0),
                width: 362,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xff2A7FFF),
                  borderRadius: BorderRadius.zero,
                ),
                child: TextButton(
                  onPressed: () {
                    widget.dataList['carNumber'] = carNum.value.text;
                    showRegistrationDialog(context, widget.dataList);
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '등록완료',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showRegistrationDialog(BuildContext context, Map<String, dynamic> dataList) {
  String _front_url;
  _front_url = UrlConfig.serverUrl.toString();

  final storage = FlutterSecureStorage();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text('차량을 등록하시겠습니까?',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // print('선택됨');
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffD0D0D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text('닫기', style: TextStyle(fontWeight: FontWeight.w400,color: Colors.black),),
              ),
              ElevatedButton(
                onPressed: () async {
                  // print(dataList);
                  final userCode = dataList['userCode'];
                  var uri = Uri.parse(_front_url+"/api/v1/cars/$userCode");

                  Map<String, String> headers = {
                    "Content-Type": "application/json"
                  };

                  var body = json.encode(dataList);
                  // print(body);
                  var response = await http.post(uri, headers: headers, body: body);
                  // print(response.body);

                  var resultData = jsonDecode(response.body);
                  // print(resultData);
                  if (resultData['code'] == 1) {
                    await storage.write(key: 'carId', value: resultData['data']['carId'].toString());
                    // 차량등록 성공
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  } else {
                    // 차량등록 실패
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('차량등록 실패')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2A7FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text('등록완료', style: TextStyle(fontWeight: FontWeight.w400,color: Colors.white),),
              ),
            ],
          ),
        ],
      );
    },
  );
}
