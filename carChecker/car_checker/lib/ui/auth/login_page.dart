import 'dart:convert';
import 'dart:io';
import 'package:car_checker/api/KakaoLoginApi.dart';
import 'package:car_checker/ui/auth/set_phone_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'package:car_checker/ui/auth/signin_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../api/login_platform.dart';
import '../../controller/UserController.dart';
import '../../url.dart';
import '../main/home_page.dart';
import 'car_regi/auth_car_registration_page.dart';
import 'find_email_page.dart';
import 'find_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  static final storage = FlutterSecureStorage();
  dynamic userInfo = '';
  dynamic userAlarm = '';
  late final String _front_url;
  LoginPlatform _loginPlatform = LoginPlatform.none;
  String? token; // FCM 토큰 저장 변수
  Map<String, dynamic> loginGoogle = {};

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    _storageUser();
    getToken();
    requestNotificationPermission();
  }

  // 스토리지에 유저정보가 있으면 HOME으로 가기
  _storageUser() async {
    // read 함수로 key값에 맞는 정보를 불러오고 데이터타입은 String 타입
    // 데이터가 없을때는 null을 반환
    userInfo = await storage.read(key: 'userId');
    userAlarm = await storage.read(key: 'alarmCheck');
    // user의 정보가 있다면 로그인 후 들어가는 첫 페이지로 넘어가게 합니다.
    if (userInfo != null) {
      // print("로그인 필요x");
      //Navigator.pushNamed(context, '/main');
      if(userAlarm != null && userAlarm == '1') {
        var uri = Uri.parse(_front_url+'/api/v1/notifications/$userInfo/toggle-push');

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
      // 로그인 성공
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // print('로그인이 필요합니다');
      // 여기서 회원가입된 정보가 있다면
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


  Future<void> logIn() async {
    var uri = Uri.parse(_front_url+"/api/v1/auth/login");

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };
    Map data = {
      "email": email.value.text,
      "password": password.value.text,
    };

    var body = json.encode(data);
    // print(body);
    var response = await http.post(uri, headers: headers, body: body);
    print('1');
    print(response.body);

    var resultData = jsonDecode(response.body);
    print('2');
    print(resultData);
    if (resultData['code'] == 1) {
      await storage.write(key: 'userId', value: resultData['data']['userId'].toString());
      await storage.write(key: 'platform', value: _loginPlatform.toString());
      // print("유저아이디저장");
      // print(resultData['data']['userId'].toString());
      // 로그인 성공
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // 로그인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패')),
      );
    }
  }


  Future<void> requestNotificationPermission() async {
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 알람권한 허용시 유저테이블에 alarm여부 체크 요청을 보내야함
      // print('알림 권한이 허용되었습니다.');
      await storage.write(key: 'alarmCheck', value: '1');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // print('알림 권한이 거부되었습니다.');
      await storage.write(key: 'alarmCheck', value: '0');
    }
  }

  void signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    // print('google Login');

    if (googleUser == null) return;

    final email = googleUser.email;

    // 먼저 로그인 시도
    var uri = Uri.parse(_front_url+"/api/v1/auth/login");

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };
    Map data = {
      "email": email,
      "password": email,
    };

    var body = json.encode(data);
    // print(body);
    var response = await http.post(uri, headers: headers, body: body);
    // print(response.body);

    var resultData = jsonDecode(response.body);
    // print(resultData);
    if (resultData['code'] == 1) {
      await storage.write(key: 'userId', value: resultData['data']['userId'].toString());
      await storage.write(key: 'platform', value: _loginPlatform.toString());
      // 로그인 성공
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // 로그인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패')),
      );
      // 회원가입 시도
      // print(googleUser);
      // print('name = ${googleUser.displayName}');
      // print('email = ${googleUser.email}');
      // print('id = ${googleUser.id}');

      // 받은 정보를 통해서 회원가입처리하고 로그인처리까지 완료해야함
      // 회원가입
      loginGoogle = {
        "email": googleUser.email,
        "password": googleUser.email,
        "name": googleUser.displayName,
        "fcmToken": token
      };

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetPhonePage(loginGoogle: loginGoogle)),
      );
    }
  }

  void signInWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      try {
        await UserApi.instance.loginWithKakaoTalk();
        // print('카카오톡으로 로그인 성공');
        User user = await UserApi.instance.me();
        signinKakao(user);
      } catch (error) {
        // print('카카오톡으로 로그인 실패 $error');
        // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();
          // print('카카오계정으로 로그인 성공');
          User user = await UserApi.instance.me();
          signinKakao(user);
        } catch (error) {
          // print('카카오계정으로 로그인 실패 $error');
        }
      }
    } else {
      try {
        await UserApi.instance.loginWithKakaoAccount();
        // print('카카오계정으로 로그인 성공');
        User user = await UserApi.instance.me();
        signinKakao(user);
      } catch (error) {
        // print('카카오계정으로 로그인 실패 $error');
      }
    }
  }

  void signinKakao(User user) async {
    try {
      // print(user);
      // print('사용자 정보 요청 성공'
      //     '\n회원번호: ${user.id}'
      //     '\n닉네임: ${user.kakaoAccount?.profile?.nickname}'
      //     '\n이메일: ${user.kakaoAccount?.email}');

      final email = user.kakaoAccount?.email;
      // 먼저 로그인 시도
      var uri = Uri.parse(_front_url+"/api/v1/auth/login");

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };
      Map data = {
        "email": email,
        "password": email,
      };

      var body = json.encode(data);
      // print(body);
      var responseK = await http.post(uri, headers: headers, body: body);
      // print(responseK.body);

      var resultData = jsonDecode(responseK.body);
      // print(resultData);
      if (resultData['code'] == 1) {
        await storage.write(key: 'userId', value: resultData['data']['userId'].toString());
        await storage.write(key: 'platform', value: _loginPlatform.toString());
        // 로그인 성공
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // 로그인 실패
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패')),
        );

        // 받은 정보를 통해서 회원가입처리하고 로그인처리까지 완료해야함
        // 회원가입
        loginGoogle = {
          "email": user.kakaoAccount?.email,
          "password": user.kakaoAccount?.email,
          "name": user.kakaoAccount?.profile?.nickname,
          "fcmToken": token
        };

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SetPhonePage(loginGoogle: loginGoogle)),
        );
      }


      setState(() {
        _loginPlatform = LoginPlatform.kakao;
      });

    } catch (error) {
      // print('카카오톡으로 로그인 실패 $error');
    }
  }


  void signInWithApple() async {
    final result = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: WebAuthenticationOptions(
        // TODO: Firebase에서 제공하는 redirectUri를 입력하세요.
        redirectUri: Uri.parse('https://carcheck-6aa9e.firebaseapp.com/__/auth/handler'),
        // TODO: Apple 개발자 콘솔의 Service ID를 입력하세요.
        clientId: 'carChecker.purem.com',
      ),
    );

    final email = result.email;
    final String? familyName = result.familyName;
    final String? givenName = result.givenName;
    final String? fullName = (givenName != null && familyName != null)
        ? '$givenName $familyName'
        : null;

    // 먼저 로그인 시도
    var uri = Uri.parse(_front_url+"/api/v1/auth/login");

    Map<String, String> headers = {
      "Content-Type": "application/json"
    };
    Map data = {
      "email": email,
      "password": email,
    };

    var body = json.encode(data);
    // print(body);
    var response = await http.post(uri, headers: headers, body: body);
    // print(response.body);

    var resultData = jsonDecode(response.body);
    // print(resultData);
    if (resultData['code'] == 1) {
      await storage.write(key: 'userId', value: resultData['data']['userId'].toString());
      await storage.write(key: 'platform', value: _loginPlatform.toString());
      // 로그인 성공
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // 로그인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패')),
      );
      // 받은 정보를 통해서 회원가입처리하고 로그인처리까지 완료해야함
      // 회원가입
      loginGoogle = {
        "email": result.email,
        "password": result.email,
        "name": fullName,
        "fcmToken": token
      };

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SetPhonePage(loginGoogle: loginGoogle)),
      );
    }
  }


  void signOut() async {
    switch (_loginPlatform) {
      case LoginPlatform.google:
        await GoogleSignIn().signOut();
        break;
      case LoginPlatform.kakao:
        break;
      case LoginPlatform.apple:
        break;
      case LoginPlatform.none:
        break;
    }

    setState(() {
      _loginPlatform = LoginPlatform.none;
    });
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
          onWillPop: () async {
            Navigator.pop(context);
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              leading: Container(
            //     padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            //     child: IconButton(
            //         onPressed: () {
            //           Navigator.pop(context);
            //         },
            //         icon: Icon(
            //           Icons.arrow_back,
            //           size: 35,
            //           weight: 700,
            //           color: Colors.black,
            //         )),
              ),
            ),
            body: SingleChildScrollView(
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 5, 0, 20),
                      child: Text('로그인',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
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
                                    style: TextStyle(decorationThickness: 0),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: "이메일을 입력해주세요.",
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
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 0, 7, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                    onPressed: (){
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => FindEmailPage()),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(0, 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      splashFactory: NoSplash.splashFactory,
                                    ),
                                    child: Text('이메일 / ',style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xffD0D0D0)),)
                                ),
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
                                    child: Text('비밀번호 찾기',style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xffD0D0D0)),)
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                              onPressed: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => SigninPage()),
                                );
                              },
                              child: Text('회원가입',style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.black,))
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
                        onPressed: () async {
                          logIn();
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => HomePage()),
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
                            '로그인',
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
                      margin: EdgeInsets.only(top: 20),
                      child: Center(
                        child: Text('간편로그인',style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xffD0D0D0)),)
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 20),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: signInWithGoogle,
                              child: Image.asset(
                                'assets/images/Google_web.png',
                                width: 60,
                                height: 60,
                              ),
                            ),
                            SizedBox(width: 25,),
                            GestureDetector(
                              onTap: signInWithKakao,
                              child: Image.asset(
                                'assets/images/kakao_logo.png',
                                width: 60,
                                height: 60,
                              ),
                            ),
                            SizedBox(width: 25,),
                            ClipOval(
                              child: SizedBox(
                                width: 60,
                                height: 60,
                                // SignInWithAppleButton 위젯을 사용합니다.
                                child: SignInWithAppleButton(
                                  onPressed: () async {
                                    signInWithApple();
                                  },
                                  style: SignInWithAppleButtonStyle.black,
                                  // 원형 버튼에 맞게 스타일을 조절합니다.
                                  // style: SignInWithAppleButtonStyle(
                                  //   icon_size: 24, // 아이콘 크기
                                  //   buttonColor: Colors.black, // 버튼 색상
                                  // ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
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
