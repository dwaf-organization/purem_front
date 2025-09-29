import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../url.dart';
import 'car_regi/auth_car_registration_page.dart';
import 'find_email_check_page.dart';
import 'find_password_page.dart';

class SetPhonePage extends StatefulWidget {
  final Map<String, dynamic> loginGoogle;
  const SetPhonePage({super.key, required this.loginGoogle});

  @override
  State<SetPhonePage> createState() => _SetPhonePageState();
}

class _SetPhonePageState extends State<SetPhonePage> {
  TextEditingController phone = TextEditingController();
  TextEditingController phoneCheck = TextEditingController();
  late final String _front_url;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 이메일찾기 함수
  Future<void> loginGoogle() async {
    // print(widget.loginGoogle);
    if (_formKey.currentState!.validate()) {
      var uri = Uri.parse(_front_url+"/api/v1/auth/sign-up");

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };

      Map data = {
        "email": widget.loginGoogle['email'],
        "password": widget.loginGoogle['password'],
        "name": widget.loginGoogle['name'],
        "phone": phone.value.text,
        "fcmToken": widget.loginGoogle['fcmToken'],
        "code": phoneCheck.value.text
      };
      // print(data);
      var body = json.encode(data);
      // print(body);
      var response = await http.post(uri, headers: headers, body: body);
      // print(response.body);

      var resultData = jsonDecode(response.body);
      // print(resultData);
      if (resultData['code'] == 1) {
        int userCode = resultData['data'];
        // 회원가입 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 성공')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AuthCarRegistrationPage(userCode: userCode,)),
        );
      } else {
        // 회원가입 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입 실패')),
        );
      }
    }
  }

  // 인증번호 요청 함수
  Future<void> reqCode() async {
    var uri = Uri.parse(_front_url+"/api/v1/verification/send-code");

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };

    Map data = {
      "name": widget.loginGoogle['name'],
      "phone": phone.value.text,
      "type": "sign-up"
    };

    var body = json.encode(data);
    // print(body);
    var response = await http.post(uri, headers: headers, body: body);
    // print(response.body);

    var resultData = jsonDecode(response.body);
    // print(resultData);
    if (resultData['code'] == 1) {
      // 인증번호 성공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증번호 성공')),
      );
    } else {
      // 인증번호 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증번호 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(context);
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
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(16, 5, 0, 0),
                  child: Text('소셜로그인(추가정보입력)',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
                ),
                Container(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                          padding: EdgeInsets.fromLTRB(16, 5, 16, 0),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '핸드폰 번호',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400),
                              ),
                              TextFormField(
                                controller: phone,
                                style: TextStyle(decorationThickness: 0),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "핸드폰 번호를 입력해주세요. ('-'없이 입력)",
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
                                    return "핸드폰 번호는 필수 입력 항목입니다.";
                                  }
                                  return null;
                                },
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      // 버튼 클릭 시 동작
                                      reqCode();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: Color(0xffD0D0D0)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                                    ),
                                    child: Text(
                                      '인증번호전송',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '인증번호',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w400),
                      ),
                      TextFormField(
                        controller: phoneCheck,
                        style: TextStyle(decorationThickness: 0),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "인증번호를 입력해주세요.",
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
                            return "인증번호는 필수 입력 항목입니다.";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(16, 30, 16, 0),
                  width: 362,
                  height: 57,
                  decoration: BoxDecoration(
                    color: Color(0xff2A7FFF),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: TextButton(
                    onPressed: () {
                      loginGoogle();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '가입하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
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
      ),
    );
  }
}