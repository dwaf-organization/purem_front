import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../url.dart';
import 'car_regi/auth_car_registration_page.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController passwordCheck = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController phoneCheck = TextEditingController();

  bool pwCheck = false;
  bool phoneVal = false;
  String? token; // FCM 토큰 저장 변수
  late final String _front_url;
  bool dupCheck = false;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    getToken();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 회원가입 함수
  Future<void> signIn() async {
    if (_formKey.currentState!.validate() && pwCheck && dupCheck) {
      var uri = Uri.parse(_front_url+"/api/v1/auth/sign-up");

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };
      Map data = {
        "email": email.value.text,
        "password": password.value.text,
        "name": name.value.text,
        "phone": phone.value.text,
        "fcmToken": token,
        "code": phoneCheck.value.text
      };

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
      "name": name.value.text,
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

  // FCM 토큰 가져오기
  Future<void> getToken() async {
    try {
      token = await FirebaseMessaging.instance.getToken();
      // print("FCM Token: $token");
    } catch (e) {
      // print("FCM Token Error: $e");
    }
  }

  // 이메일중복체크
  Future<void> setDupCheck() async {
    String dupEmail = email.value.text;
    var result = await http.get(Uri.parse(_front_url+'/api/v1/auth/duplication-check?email=$dupEmail'));
    var resultData = jsonDecode(result.body);
    setState(() {
      dupCheck = resultData!['data'];
      // print(dupCheck);
      if(dupCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('중복 확인 완료')),
        );
      }else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미 가입된 이메일입니다.')),
        );
      }
    });
  }

  // 이메일 정규식
  final emailRegExp = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,4}$');

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
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(16, 5, 0, 0),
                  child: Text('회원가입',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
                ),
                Container(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '이메일',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: email,
                                      style: TextStyle(decorationThickness: 0),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "이메일을 입력해주세요.",
                                        hintStyle: TextStyle(
                                          color: Color(0xffD0D0D0),
                                          fontSize: 16,
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xffD0D0D0)),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Color(0xffD0D0D0), width: 2),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (dupCheck) {
                                          setState(() {
                                            dupCheck = false;
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "이메일은 필수 입력 항목입니다.";
                                        }
                                        if (!emailRegExp.hasMatch(value)) {
                                          return "올바른 이메일 형식이 아닙니다.";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: dupCheck
                                        ? null
                                        : () {
                                      setDupCheck();
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
                                      dupCheck ? '확인완료' : '중복확인',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
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
                                '비밀번호',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400),
                              ),
                              TextFormField(
                                controller: password,
                                style: TextStyle(decorationThickness: 0),
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "비밀번호를 입력해주세요.",
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
                                    return "비밀번호는 필수 입력 항목입니다.";
                                  }
                                  return null;
                                },
                              ),
                            ],
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
                                '비밀번호 재확인',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400),
                              ),
                              TextFormField(
                                controller: passwordCheck,
                                style: TextStyle(decorationThickness: 0),
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "비밀번호를 재입력해주세요.",
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
                                    return "비밀번호 재확인은 필수 입력 항목입니다.";
                                  }
                                  if (value != password.text) {
                                    return "비밀번호가 일치하지 않습니다.";
                                  }
                                  setState(() {
                                    pwCheck = true;
                                  });
                                  return null;
                                },
                              ),
                            ],
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
                                '이름',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400),
                              ),
                              TextFormField(
                                controller: name,
                                style: TextStyle(decorationThickness: 0),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "이름을 입력해주세요.",
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
                                    return "이름은 필수 입력 항목입니다.";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
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
                      ],
                    ),
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
                      signIn();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '회원가입 완료하기',
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


void _showConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text('정말 탈퇴 하시겠습니까?',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffD0D0D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text('탈퇴', style: TextStyle(fontWeight: FontWeight.w400,color: Colors.black),),
              ),
              ElevatedButton(
                onPressed: () {
                  // print('선택됨');
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff2A7FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text('취소', style: TextStyle(fontWeight: FontWeight.w400,color: Colors.white),),
              ),
            ],
          ),
        ],
      );
    },
  );
}
