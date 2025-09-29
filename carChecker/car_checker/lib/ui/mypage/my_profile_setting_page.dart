import 'package:car_checker/ui/auth/login_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../url.dart';

class MyProfileSettingPage extends StatefulWidget {
  const MyProfileSettingPage({super.key});

  @override
  State<MyProfileSettingPage> createState() => _MyProfileSettingPageState();
}

class _MyProfileSettingPageState extends State<MyProfileSettingPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  dynamic userId = '';
  Map<String, dynamic> data = {};
  bool pwCheck = false;

  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController passwordCheck = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    userId = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/me/$userId'));
    var resultData = jsonDecode(result.body);
    setState(() {
      data = resultData!['data'];
      // print(data);
    });
  }

  // 회원수정 함수
  Future<void> updateUser() async {
    if (_formKey.currentState!.validate() && pwCheck) {
      var uri = Uri.parse(_front_url+"/api/v1/auth/update");

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };
      Map data = {
        "userId": userId,
        "email": email.value.text,
        "password": password.value.text,
        "name": name.value.text,
        "phone": phone.value.text
      };

      var body = json.encode(data);
      // print(body);
      var response = await http.put(uri, headers: headers, body: body);
      // print(response.body);

      var resultData = jsonDecode(response.body);
      // print(resultData);
      if (resultData['code'] == 1) {
        // 회원정보 수정 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원정보 수정 성공')),
        );
      } else {
        // 회원정보 수정 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원정보 수정 실패')),
        );
      }
    }
  }

  Future<void> deleteFirebaseUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firebase 사용자 계정 삭제
        await user.delete();
        // print("Firebase 계정이 성공적으로 삭제되었습니다.");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // 최근 로그인이 필요하다는 오류가 발생하면,
        // 사용자에게 다시 로그인하도록 안내해야 합니다.
        // print('Firebase 계정 삭제 실패: 최근 로그인이 필요합니다. 다시 로그인해주세요.');
      } else {
        // print('Firebase 계정 삭제 중 오류 발생: $e');
      }
    } catch (e) {
      // print('알 수 없는 오류 발생: $e');
    }
  }

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
                  margin: EdgeInsets.fromLTRB(16, 5, 0, 30),
                  child: Text('내 프로필 보기',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
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
                              TextFormField(
                                controller: email,
                                readOnly: true,
                                style: TextStyle(decorationThickness: 0),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: data['email'] ?? '',
                                  hintStyle: TextStyle(
                                    color: Colors.black,
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
                                    return "이메일은 필수 입력 항목입니다.";
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
                                  hintText: "변경할 비밀번호를 입력해주세요.",
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
                                  hintText: "변경할 비밀번호를 재입력해주세요.",
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
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: data['name'] ?? '',
                                  hintStyle: TextStyle(
                                    color: Colors.black,
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
                                obscureText: true,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: data['phone'] ?? '',
                                  hintStyle: TextStyle(
                                    color: Colors.black,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: (){
                          _showConfirmationDialog(context);
                        },
                        child: Text('회원 탈퇴',style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Color(0xffD0D0D0)),)
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(16, 30, 16, 0),
                  width: 362,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xff2A7FFF),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: TextButton(
                    onPressed: () {
                      // updateUser();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '수정 완료',
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
      ),
    );
  }
}


void _showConfirmationDialog(BuildContext context) async {
  final storage = FlutterSecureStorage();
  final String _front_url;
  dynamic userId = await storage.read(key: 'userId');
  _front_url = UrlConfig.serverUrl.toString();

  // 회원탈퇴 함수
  Future<void> deleteUser() async {
    var uri = Uri.parse(_front_url+"/api/v1/me/$userId/status");

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };
    Map data = {
      "userId": userId
    };

    var body = json.encode(data);
    // print(body);
    var response = await http.put(uri, headers: headers, body: body);
    // print(response.body);

    var resultData = jsonDecode(response.body);
    // print(resultData);
    if (resultData['code'] == 1) {
      // 회원탈퇴 성공
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원탈퇴 성공')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      // 회원탈퇴 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원탈퇴 실패')),
      );
    }
  }

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
                  deleteUser();
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
