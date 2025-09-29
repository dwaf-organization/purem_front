import 'dart:convert';

import 'package:car_checker/api/KakaoLoginApi.dart';
import 'package:car_checker/controller/UserController.dart';
import 'package:car_checker/ui/BleProvider.dart';
import 'package:car_checker/ui/auth/login_page.dart';
import 'package:car_checker/ui/main/home_page.dart';
import 'package:car_checker/url.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

import 'package:http/http.dart' as http;

final logger = Logger();
final storage = FlutterSecureStorage();

Future<void> sendPostRequestToMyDatabase(Map<String, dynamic> data) async {
  final url = Uri.parse("http://api.clarte.store:8080/api/v1/notifications/periodic");

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      logger.i('DB INSERT 성공: ${response.body}');
    } else {
      logger.e('DB INSERT 실패: ${response.statusCode}');
    }
  } catch (e) {
    logger.e('POST 요청 중 에러 발생: $e');
  }
}

// 👉 알림 페이로드를 처리하는 공통 함수
Future<void> _handleMessage(RemoteMessage message) async {
  final data = Map<String, dynamic>.from(message.data);
  String? userId = await storage.read(key: 'userId');
  if (userId != null) {
    data['userId'] = userId; // 가져온 userId를 데이터 맵에 추가합니다.
  }

  if (message.notification != null) {
    data['notificationTitle'] = message.notification!.title;
    data['notificationBody'] = message.notification!.body;
  }

  // 알림에 특정 데이터가 포함되어 있는지 확인
  if (data.containsKey('action') && data['action'] == 'update_db') {
    // 수정된 data 맵을 POST 요청 함수에 전달
    sendPostRequestToMyDatabase(data);
  }
}

// 👉 앱이 백그라운드나 종료 상태일 때 알림을 수신하면 실행되는 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i("Handling a background message: ${message.messageId}");
  // Firebase.initializeApp()을 다시 호출해야 백그라운드 핸들러에서 Firebase 서비스를 사용할 수 있습니다.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _handleMessage(message);
}

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👉 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.notification != null) {
      logger.e("onMessageOpenedApp title: ${message.notification!.title}");
      logger.e("onMessageOpenedApp body: ${message.notification!.body}");
      logger.e("click_action: ${message.data['click_action']}");
    }
  });

  FirebaseMessaging.instance
      .getInitialMessage()
      .then((RemoteMessage? message) {
    if (message != null) {
      if (message.notification != null) {
        logger.e(message.notification!.title);
        logger.e(message.notification!.body);
        logger.e(message.data["click_action"]);
      }
    }
  });

  KakaoSdk.init(nativeAppKey: '6b3954427a8446751ff66ba80394e5ed');

  // ⭐️ MultiProvider를 사용하여 여러 프로바이더를 등록합니다. ⭐️
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserController(
            kakaoLoginApi: KakaoLoginApi(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => BleProvider(),
        ),
      ],
      child: const Car(),
    ),
  );
}

class Car extends StatelessWidget {
  const Car({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserController(
        kakaoLoginApi: KakaoLoginApi(),
      ),
      child: MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white, // 기본 배경색 흰색
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white, // 앱바 배경색 흰색
          ),
        ),
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: NoGlowScrollBehavior(), // 스크롤 효과 제거
            child: child!,
          );
        },
        home: MainPage(),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final String _front_url;
  final PageController _controller = PageController();
  int _currentPage = 0;
  static final storage = FlutterSecureStorage();
  dynamic userInfo = '';
  dynamic userAlarm = '';

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    _storageUser();

    // ⭐️ 포그라운드 메시지 리스너를 여기에 등록합니다. ⭐️
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('포그라운드에서 메시지 수신: ${message.messageId}');
      _handleMessage(message);

      // ⭐️ 알림이 있을 때만 다이얼로그를 띄웁니다. ⭐️
      if (message.notification != null) {
        showInAppMessageDialog(
          context,
          message.notification!.title,
          message.notification!.body,
        );
      }
    });
  }

  // ⭐️ 인앱 메시지 다이얼로그 함수를 _MainPageState 클래스 내부에 정의합니다. ⭐️
  void showInAppMessageDialog(BuildContext context, String? title, String? body) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? '알림'),
          content: Text(body ?? '내용 없음'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그를 닫습니다.
              },
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
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

  final List<Widget> pages = [
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "블루투스연결을 통해",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "나의 ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              "필터상태",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff2A7FFF)),
              textAlign: TextAlign.center,
            ),
            Text(
              "를 확인하세요.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        SizedBox(height: 10,),
        Image.asset('assets/images/onboarding1.png', width: 350, height: 274),
      ],
    ),
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "알림 설정을 하면",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "나의 ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              "필터 교체 주기",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff2A7FFF)),
              textAlign: TextAlign.center,
            ),
            Text(
              "를 알려줘요.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        SizedBox(height: 10,),
        Image.asset('assets/images/onboarding2.png', width: 350, height: 274),
      ],
    ),
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "로그인 후",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff2A7FFF)),
          textAlign: TextAlign.center,
        ),
        Text(
          "서비스를 이용해 보세요.",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff2A7FFF)),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10,),
        Image.asset('assets/images/onboarding3.png', width: 350, height: 274),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: pages,
          ),
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.blue
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 30,
            right: 30,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage < pages.length - 1) {
                  _controller.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut);
                } else {
                  // 시작하기 눌렀을 때 다음 화면 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2A7FFF),
                minimumSize: Size(335, 57),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
              child: Text(
                _currentPage == pages.length - 1 ? "시작하기" : "다음",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NextScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text("다음 화면")),
    );
  }
}

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}