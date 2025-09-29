import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../url.dart';
import 'find_email_check_page.dart';
import 'find_password_page.dart';

class FindEmailPage extends StatefulWidget {
  const FindEmailPage({super.key});

  @override
  State<FindEmailPage> createState() => _FindEmailPageState();
}

class _FindEmailPageState extends State<FindEmailPage> {
  TextEditingController name = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController phoneCheck = TextEditingController();

  Map<String, dynamic> foundEmail = {};
  late final String _front_url;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 이메일찾기 함수
  Future<void> findEmail() async {
    if (_formKey.currentState!.validate()) {
      var uri = Uri.parse(_front_url+"/api/v1/users/find-email");

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };

      Map data = {
        "name": name.value.text,
        "phone": phone.value.text
      };

      var body = json.encode(data);
      // print(body);
      var response = await http.post(uri, headers: headers, body: body);
      // print(response.body);

      var resultData = jsonDecode(response.body);
      // print(resultData);
      if (resultData['code'] == 1) {
        // 테스트 데이터
        foundEmail = resultData['data'];
        // foundEmail = {
        //   "email": "hong@example.com"
        // };
        // 이메일찾기 성공
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일찾기 성공')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FindEmailCheckPage(data: foundEmail)),
        );
      } else {
        // 이메일찾기 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일찾기 실패')),
        );
      }
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
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(16, 5, 0, 0),
                  child: Text('이메일 찾기',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
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
                              // Row(
                              //   mainAxisAlignment: MainAxisAlignment.end,
                              //   children: [
                              //     OutlinedButton(
                              //       onPressed: () {
                              //         // 버튼 클릭 시 동작
                              //       },
                              //       style: OutlinedButton.styleFrom(
                              //         backgroundColor: Colors.white,
                              //         side: BorderSide(color: Color(0xffD0D0D0)),
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.zero,
                              //         ),
                              //         padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                              //       ),
                              //       child: Text(
                              //         '인증번호전송',
                              //         style: TextStyle(
                              //           color: Colors.black,
                              //           fontWeight: FontWeight.w700,
                              //         ),
                              //       ),
                              //     )
                              //   ],
                              // ),
                            ],
                          ),
                        ),
                        // Container(
                        //   margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                        //   padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
                        //   width: double.infinity,
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Text(
                        //         '인증번호',
                        //         style: TextStyle(
                        //             fontSize: 15,
                        //             fontWeight: FontWeight.w400),
                        //       ),
                        //       TextFormField(
                        //         controller: phoneCheck,
                        //         style: TextStyle(decorationThickness: 0),
                        //         obscureText: true,
                        //         decoration: InputDecoration(
                        //           border: InputBorder.none,
                        //           hintText: "인증번호를 입력해주세요.",
                        //           hintStyle: TextStyle(
                        //             color: Color(0xffD0D0D0),
                        //             fontSize: 16,
                        //           ),
                        //           enabledBorder: UnderlineInputBorder(
                        //             borderSide: BorderSide(color: Color(0xffD0D0D0),),
                        //           ),
                        //           focusedBorder: UnderlineInputBorder(
                        //             borderSide: BorderSide(color: Color(0xffD0D0D0), width: 2),
                        //           ),
                        //         ),
                        //         validator: (value) {
                        //           if (value == null || value.isEmpty) {
                        //             return "인증번호는 필수 입력 항목입니다.";
                        //           }
                        //           return null;
                        //         },
                        //       ),
                        //     ],
                        //   ),
                        // ),
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
                      findEmail();
                      // 테스트 데이터
                      // foundEmail = {
                      //   "email": "hong@gmail.com"
                      // };
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FindEmailCheckPage(data: foundEmail)),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '이메일 찾기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(16, 15, 7, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text('비밀번호를 잊으셨나요? ',style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xffD0D0D0)),),
                            TextButton(
                                onPressed: (){
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FindPasswordPage()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  splashFactory: NoSplash.splashFactory,
                                ),
                              child: Text(
                                '비밀번호 찾기',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.black,
                                  decorationThickness: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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