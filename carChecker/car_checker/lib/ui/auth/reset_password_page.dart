import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../url.dart';
import 'find_email_check_page.dart';
import 'find_email_page.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const ResetPasswordPage({super.key, required this.data});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  TextEditingController password = TextEditingController();
  TextEditingController passwordCheck = TextEditingController();

  bool pwCheck = false;
  late final String _front_url;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    // print(widget.data);
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 비밀번호변경 함수
  Future<void> resetPassword() async {
    if (_formKey.currentState!.validate() && pwCheck) {
      var uri = Uri.parse(_front_url+"/api/v1/users/update-password");

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };

      Map data = {
        "userId": widget.data['userId'],
        "newPassword": password.value.text
      };

      var body = json.encode(data);
      // print(body);
      var response = await http.put(uri, headers: headers, body: body);
      // print(response.body);

      var resultData = jsonDecode(response.body);
      // print(resultData);
      if (resultData['code'] == 1) {
        // 비밀번호변경 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호변경 성공')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // 비밀번호변경 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호변경 실패')),
        );
      }
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
                  margin: EdgeInsets.fromLTRB(16, 5, 0, 0),
                  child: Text('비밀번호 찾기',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
                ),
                Container(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                      resetPassword();
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(builder: (context) => LoginPage()),
                      // );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '비밀번호 재설정 완료하기',
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