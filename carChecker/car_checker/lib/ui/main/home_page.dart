import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../LogoutHandler.dart';
import '../../api/login_platform.dart';
import '../../url.dart';
import '../BleProvider.dart';
import '../auth/login_page.dart';
import '../information/filter_change_page.dart';
import '../information/info_tab1.dart';
import '../information/info_tab2.dart';
import '../information/info_tab3.dart';
import '../information/info_tab4.dart';
import '../information/product_detail_page.dart';
import '../mypage/my_alarmSet_page.dart';
import '../mypage/my_announcement_page.dart';
import '../mypage/my_inquiry_page.dart';
import '../mypage/my_profile_page.dart';
import 'car_registration_page.dart';
import 'filter_manage_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // 기본 배경색 흰색
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white, // 앱바 배경색 흰색
        ),
      ),
      home: CarHomePage(),
    );
  }
}

class CarHomePage extends StatefulWidget {
  const CarHomePage({super.key});

  @override
  State<CarHomePage> createState() => _CarHomePageState();
}

class _CarHomePageState extends State<CarHomePage> {
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    Information(),
    Report(),
    Home(),
    Alarm(),
    MyPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        )
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static final storage = FlutterSecureStorage();
  dynamic userInfo = '';
  String userInfoString = '';
  late final String _front_url;
  final logger = Logger();
  Map<String, dynamic> data = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _front_url = UrlConfig.serverUrl.toString();

    loadData();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final title = message.notification!.title ?? 'No Title';
        final body = message.notification!.body ?? 'No Body';
        final clickAction = message.data['click_action'];

        logger.e('Title: $title');
        logger.e('Body: $body');
        logger.e('Click Action: $clickAction');

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('확인'),
              )
            ],
          ),
        );
      }
    });
  }

  Future<void> loadData() async {
    await _checkUserId();
    await getData();
    await getMonthData();
    setState(() {
      isLoading = false;
    });
  }


  _checkUserId() async {
    userInfo = await storage.read(key: 'userId');
    // print(userInfo);
  }

  getData() async {
    userInfo = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/cars/$userInfo'));
    var resultData = jsonDecode(result.body);

    setState(() {
      if (resultData['data'] != null) {
        data = resultData['data'];
      } else {
        // data가 null일 경우, 임의의 값 할당
        data = {
          "carId": 0,
          "carNumber": "11가 1111",
          "model": "Genesis GV70",
          "modelDetail": "GV70",
          "replacementDate": "2025-07-02T09:17:54",
          "filterScore": 75
        };
        // print('데이터가 null이어서 임의의 값으로 대체합니다.');
      }
      // print('데이터확인');
      // print(data);

      // 필터 점수가 20 이하일 때 다이얼로그 표시
      int filterScore = data['filterScore'] ?? 0;
      if (filterScore <= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showFilterReplaceDialog();
        });
      }

    });
  }

  getMonthData() async {
    userInfo = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/filter-history/expired/$userInfo'));
    var resultData = jsonDecode(result.body);

    setState(() {
      if (resultData['code'] == -1 && !resultData['data']) {
      // if (resultData['code'] == 1 && resultData['data']) {
        _showMonthFilterReplaceDialog();
      } else {
        return;
      }
    });
  }

  void _showFilterReplaceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부 터치로 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '필터를 교체해야 합니다.',
            style: TextStyle(
                fontSize: 18,fontWeight: FontWeight.w700
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 버튼을 가운데로 정렬
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2A7FFF), // 버튼 배경색 변경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    fixedSize: Size(80, 25),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.white, // 버튼 글자색 변경
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  void _showMonthFilterReplaceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부 터치로 닫기 방지
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            '필터 교체 후 6개월이 지났습니다.\n필터를 교체해야 합니다.',
            style: TextStyle(
                fontSize: 16,fontWeight: FontWeight.w600
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 버튼을 가운데로 정렬
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2A7FFF), // 버튼 배경색 변경
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    fixedSize: Size(80, 25),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    '확인',
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.white, // 버튼 글자색 변경
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if(isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final String model = data['model'];
    final String assetPath = 'assets/images/cars/$model.png';
    final String updateReplacementDate = data['replacementDate'] != null
        ? data['replacementDate'].substring(0, 10)
        : '앞으로 180일';
    // final String assetPath = 'assets/images/cars/Genesis EQ900.png';

    final bleProvider = context.watch<BleProvider>();

    int filterScore = data['filterScore'];
    String imagePath;
    String checkPath;
    String scoreText;
    String statusText;
    String performanceText;

    switch (filterScore) {
      case int score when score >= 80 && score <= 100:
        imagePath = 'assets/images/80-100.png';
        scoreText = '$filterScore점';
        statusText = '최적';
        checkPath = 'assets/images/Vector_B.png';
        performanceText = '필터가 완벽한 상태입니다.\n최고의 성능을 유지하고 있습니다.';
        break;
      case int score when score >= 60 && score < 80:
        imagePath = 'assets/images/60-79.png';
        scoreText = '$filterScore점';
        statusText = '양호';
        checkPath = 'assets/images/Vector_G.png';
        performanceText = '필터 효율이 우수합니다.\n꺠끗한 공기를 유지합니다.';
        break;
      case int score when score >= 40 && score < 60:
        imagePath = 'assets/images/40-59.png';
        scoreText = '$filterScore점';
        statusText = '적정';
        checkPath = 'assets/images/Vector_Y.png';
        performanceText = '적정 수준의 필터 상태입니다.\n일반적인 관리를 계속하세요.';
        break;
      case int score when score >= 20 && score < 40:
        imagePath = 'assets/images/20-39.png';
        scoreText = '$filterScore점';
        statusText = '관심 필요';
        checkPath = 'assets/images/Vector_O.png';
        performanceText = '필터 상태를 확인해주세요.\n곧 교체가 필요할 수 있습니다.';
        break;
      case int score when score >= 0 && score < 20:
        imagePath = 'assets/images/0-19.png';
        scoreText = '$filterScore점';
        statusText = '교체 필요';
        checkPath = 'assets/images/Vector_R.png';
        performanceText = '필터 성능이 저하되었습니다.\n최적의 공기질을 위해 교체를 권장합니다.';
        break;
      default:
        imagePath = 'assets/images/0-0.png';
        scoreText = '0점';
        statusText = '알 수 없음';
        checkPath = 'assets/images/Vector_GR.png';
        performanceText = '필터 상태를 확인할 수 없습니다.';
        break;
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(24, 56, 24, 8),
          height: 190,
          color: Color(0xff2A7FFF),
          child: Row(
            children: [
              Flexible(
                flex: 1,
                child: Container(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('차량',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w500, color: Colors.white),),
                      Text(data['model'] ?? '재입력 필요',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.white),),
                      Image.asset(assetPath, width: 190 ,height: 65,fit: BoxFit.contain,errorBuilder: (context, error, stackTrace) {
                        return const Text('이미지를 불러올 수 없습니다.');
                      },)
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 1,
                child: Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('차량번호',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w500, color: Colors.white),),
                            Text(data['carNumber'] ?? '재입력 필요',style: TextStyle(fontSize: 19,fontWeight: FontWeight.w700, color: Colors.white),),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('예상 필터 교체일',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w500, color: Colors.white),),
                            Text(updateReplacementDate ?? '앞으로 180일', style: TextStyle(fontSize: 19,fontWeight: FontWeight.w700, color: Colors.white),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 39),
                  padding: EdgeInsets.fromLTRB(15, 5, 15, 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Color(0xff2A7FFF),
                      width: 2.5,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '나의 필터 상태',
                    style: TextStyle(
                      color: Color(0xff2A7FFF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, // 모양을 원형으로 설정합니다.
                        border: Border.all(
                          color: Colors.black, // 테두리 색상을 검은색으로 설정합니다.
                          width: 1.0, // 테두리 두께를 1px로 설정합니다.
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          getData();
                        },
                        child: SvgPicture.asset(
                          'assets/icons/refresh.svg',
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 2),
                      width: 300,
                      height: 277,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 70),
                      child: Column(
                        children: [
                          Text(scoreText, style: TextStyle(color: Color(0xff2A7FFF), fontSize: 20, fontWeight: FontWeight.w500,),),
                          Text(statusText, style: TextStyle(color: Color(0xff2A7FFF), fontSize: 35, fontWeight: FontWeight.w700,),),
                          SizedBox(height: 5,),
                          Image.asset(checkPath)
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: EdgeInsets.only(top: 40),
                  child: Column(
                    children: [
                      Text(performanceText, textAlign: TextAlign.center, style: TextStyle(fontSize: 15,fontWeight: FontWeight.w600),),
                    ],
                  ),
                ),
                Container(
                  width: 119,
                  height: 31,
                  margin: EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Color(0xffD0D0D0),
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FilterManagePage()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      '나의 필터 관리',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  dynamic userId = '';
  bool isLoading = true;

  Map<String, dynamic> userData = {};

  Map<String, dynamic> carData = {};

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  Future<void> loadData() async {
    await getUserInfo();
    await getCar();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getUserInfo() async {
    userId = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/me/$userId'));
    var resultData = jsonDecode(result.body);
    userData = resultData!['data'];
    // print('mypageUser');
    // print(userData);
  }

  Future<void> getCar() async {
    userId = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/cars/$userId'));
    var resultData = jsonDecode(result.body);
    if (resultData['data'] != null) {
      carData = resultData['data'];
    } else {
      // data가 null일 경우, 임의의 값 할당
      carData = {
        "carId": 0,
        "carNumber": "11가 1111",
        "model": "Genesis GV70",
        "modelDetail": "GV70",
        "replacementDate": "2025-07-02T09:17:54",
        "filterScore": 75
      };
      // print('데이터가 null이어서 임의의 값으로 대체합니다.');
    }
    switch (carData['model']) {
      case 'GV70':
        carData['imagePath'] = 'assets/images/GV70_B.png';
        break;
      case 'GV80':
        carData['imagePath'] = 'assets/images/GV70_B.png';
        break;
      case 'G80':
        carData['imagePath'] = 'assets/images/GV70_B.png';
        break;
      default:
        carData['imagePath'] = 'assets/images/GV70_B.png';
    }

    // print('mypageCar');
    // print(carData);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final String model = carData['model'];
    final String assetPath = 'assets/images/cars/$model.png';
    // final String assetPath = 'assets/images/cars/Genesis EQ900.png';

    final bleProvider = context.watch<BleProvider>();
    // print('현재 BLE 연결 상태: ${bleProvider.connectionStatus}');
    // print('현재 BLE 연결 상태: ${bleProvider}');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Home();
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.fromLTRB(16, 60, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 이름
                Container(
                  margin: EdgeInsets.fromLTRB(25, 0, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('안녕하세요',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
                            Text('! ',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),),
                            Text(userData['name'] ?? '',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600, color: Color(0xff2A7FFF)),),
                            Text(' ',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
                            Text('님',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400),),
                          ],
                        ),
                      ),
                      Container(
                        child: TextButton(onPressed: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyProfilePage()),
                          );
                        },
                            child: Row(
                              children: [
                                Text('내 프로필 보기 ',style: TextStyle(color: Color(0xff7C7C7C)),),
                                Icon(Icons.arrow_forward,size: 14, color: Color(0xff7C7C7C),)
                              ],
                            )),
                      )
                    ],
                  ),
                ),
                //차량정보
                Container(
                  margin: EdgeInsets.only(top: 30),
                  padding: EdgeInsets.fromLTRB(25, 15, 25, 10),
                  width: 310,
                  height: 330,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 5,
                        blurRadius: 10,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 버튼
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 33,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Color(0xffD0D0D0)),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CarRegistrationPage()),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '수정',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // 내용
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(left: 35),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('차량',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400, color: Colors.black),),
                                        Text(carData['model'] ?? '',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500, color: Colors.black),),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10,),
                                  Container(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('차량번호',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w400, color: Colors.black),),
                                        Text(carData['carNumber'] ?? '',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w500, color: Colors.black),),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10,),
                                ],
                              ),
                            ),
                            // Image.asset(carData['imagePath'] ?? 'assets/images/GV70_B.png',width: 251, height: 130,)
                            Image.asset(assetPath, width: 300 ,height: 150,fit: BoxFit.contain,errorBuilder: (context, error, stackTrace) {
                              return const Text('이미지를 불러올 수 없습니다.');
                            },)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 항목들
                Container(
                  margin: EdgeInsets.only(top: 5),
                  height: 215,
                  child: ListView(
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      Divider(color: Colors.grey, height: 1),
                      ListTile(
                        leading: Icon(Icons.list,size: 25,),
                        title: Text('공지사항',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400),),
                        visualDensity: VisualDensity(vertical: -4),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyAnnouncementPage()),
                          );
                        },
                      ),
                      Divider(color: Colors.grey, height: 1),
                      ListTile(
                        leading: Icon(Icons.notifications,size: 25,),
                        visualDensity: VisualDensity(vertical: -4),
                        title: Text('알람 설정',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400),),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyAlarmsetPage()),
                          );
                        },
                      ),
                      Divider(color: Colors.grey, height: 1),
                      ListTile(
                        leading: Icon(Icons.support_agent,size: 25,),
                        visualDensity: VisualDensity(vertical: -4),
                        title: Text('고객센터',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400),),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyInquiryPage()),
                          );
                        },
                      ),
                      Divider(color: Colors.grey, height: 1),
                      ListTile(
                        leading: Icon(Icons.output,size: 25,),
                        visualDensity: VisualDensity(vertical: -4),
                        title: Text('로그아웃',style: TextStyle(fontSize: 13,fontWeight: FontWeight.w400),),
                        onTap: () {
                          _showLogOutDialog(context);
                        },
                      ),
                      Divider(color: Colors.grey, height: 1),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 10),
                  width: 362,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xff2A7FFF),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: TextButton(
                    onPressed: () async {
                      final Uri url = Uri.parse('https://www.clarte.store/');
                      // final Uri url = Uri.parse(productDetail['link']); // 추후 변경필요
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '클라떼로 이동',
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

class Alarm extends StatefulWidget {
  const Alarm({super.key});

  @override
  State<Alarm> createState() => _AlarmState();
}

class _AlarmState extends State<Alarm> {
  late final String _front_url;
  static final storage = FlutterSecureStorage();
  dynamic userInfo = '';
  List<Map<String, dynamic>> AlarmData = [
    // {
    //   "type": "알림",
    //   "content": "앱에 접속하여 필터를 확인해주세요.",
    //   "date": "2025-05-02",
    //   "time": "09:00"
    // },
    // {
    //   "type": "공지사항",
    //   "content": "새로운 공지사항을 확인해주세요.",
    //   "date": "2025-05-01",
    //   "time": "14:00"
    // },
  ];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  Future<void> loadData() async {
    // await getAlarm();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getAlarm() async {
    userInfo = await storage.read(key: 'userId');

    var result = await http.get(Uri.parse(_front_url+'/api/v1/notification/$userInfo'));
    var resultData = jsonDecode(result.body);
    AlarmData = resultData['data'];
    // print(resultData);
    // print(AlarmData);
    if (resultData['code'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('조회 성공')),
      );
    } else {
      // 필터이력 확인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('조회 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if(isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Home();
        }
      },
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 57, 16, 0),
          child: AlarmData != null && AlarmData.isNotEmpty
              ? ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: AlarmData.length,
            itemBuilder: (context, i) {
              String AlarmType = AlarmData[i]['type'];
              String imagePath;
              switch (AlarmType) {
                case String type when type == '알림':
                  imagePath = 'assets/icons/alarm_icon.png';
                  break;
                case String type when type == '공지사항':
                  imagePath = 'assets/icons/alarm_announce_icon.png';
                  break;
                default:
                  imagePath = 'assets/icons/alarm_icon.png';
                  break;
              }
              return Container(
                width: 361,
                height: 100,
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Color(0xffD0D0D0),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 10),
                    Image.asset(imagePath, width: 40, height: 40),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AlarmData[i]['type'],
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w400),
                          ),
                          SizedBox(
                            height: 5,
                          ),
                          Text(
                            AlarmData[i]['content'],
                            style: TextStyle(
                                fontSize: 15,
                                color: Colors.black,
                                fontWeight: FontWeight.w700),
                          ),
                          SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Text(
                                AlarmData[i]['date'],
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                AlarmData[i]['time'],
                                style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          )
              : SizedBox(
            height: MediaQuery.of(context).size.height - 200, // 이 부분이 핵심입니다.
            child: Center(
              child: Text(
                "새로운 알림이 없습니다.",
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  late final String _front_url;
  static final storage = FlutterSecureStorage();
  dynamic userId = '';
  dynamic carId = '';
  String date = '1w';
  String _selectButton = '1w';
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  Map<String, dynamic> carData = {};
  List<dynamic> filterData = [];

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  Future<void> loadData() async {
    await getUserInfo();
    await getCar();
    await getFilterByDate(date);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getUserInfo() async {
    userId = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/me/$userId'));
    var resultData = jsonDecode(result.body);
    userData = resultData!['data'];
    // print('reportUser');
    // print(userData);
  }

  Future<void> getCar() async {
    userId = await storage.read(key: 'userId');
    var result = await http.get(Uri.parse(_front_url+'/api/v1/cars/$userId'));
    var resultData = jsonDecode(result.body);
    if (resultData['data'] != null) {
      carData = resultData['data'];
      carId = carData['carId'];
    } else {
      // data가 null일 경우, 임의의 값 할당
      carData = {
        "carId": 0,
        "carNumber": "11가 1111",
        "model": "Genesis GV70",
        "modelDetail": "GV70",
        "replacementDate": "2025-00-00T09:17:54",
        "filterScore": 75
      };
      carId = carData['carId'];
      // print('데이터가 null이어서 임의의 값으로 대체합니다.');
    }

    // print('mypageCar');
    // print(carData);
  }

  Future<void> getFilterByDate(String date) async {
    var result = await http.get(Uri.parse(_front_url+'/api/v1/filter/value/history/$carId/$date'));
    // var result = await http.get(Uri.parse(_front_url+'/api/v1/filter/value/history/4/$date'));
    var resultData = jsonDecode(result.body);
    setState(() {
      if (resultData['data'] != null) {
        filterData = resultData['data'];
      } else {
        // data가 null일 경우, 임의의 값 할당
        filterData = [
          {
            "resistanceValue": 100.0,
            "date": "00-00"
          },
          {
            "resistanceValue": 100.0,
            "date": "00-00"
          }
        ];
      }
      _selectButton = date;
    });
    // print(filterData);
  }

  LineChartData mainData() {
    if (filterData.isEmpty) {
      return LineChartData(
        lineBarsData: [],
      );
    }

    final double maxX = (filterData.length - 1).toDouble();

    return LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: 100,
        titlesData: FlTitlesData( // 차트 레이블
          show: true,
          bottomTitles: AxisTitles( // x축 하단 표시
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25, // 레이블 공간 확보
              interval: 1,
              getTitlesWidget: bottomTitleWidget,
            ),
          ),
          leftTitles: AxisTitles( // y축 좌측표시
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: leftTitleWidget,
            ),
          ),
          topTitles: AxisTitles( // x축 상단 표시
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles( // y축 우측 표시
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData( // 차트 외부 테두리
            show: true,
            border: Border.all(color: Color(0xffD0D0D0), width: 1)
        ),
        gridData: FlGridData( // 차트 내부 그리드 선
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 12.5, // 간격
          verticalInterval: 1, // 간격
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Color(0xffD0D0D0),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Color(0xffD0D0D0),
              strokeWidth: 1,
            );
          },
        ),
        lineBarsData: [
          LineChartBarData(
            spots: filterData
                .asMap()
                .entries
                .map((entry) {
              return FlSpot(
                entry.key.toDouble(),
                entry.value['resistanceValue'],
              );
            }).toList(),
            isCurved: true,
            color: Color(0xff2A7FFF),
            barWidth: 3,
            isStrokeCapRound: false, // 차트 선의 처음과 끝을 둥글게 처리
            dotData: FlDotData( // spot마다 표시 여부
              show: false,
            ),
          ),
        ],
        lineTouchData: LineTouchData( // 차트 선 툴팁
            touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.white,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((touchedSpot) {
                    final spotIndex = touchedSpot.spotIndex;
                    if (spotIndex < 0 || spotIndex >= filterData.length) {
                      return null;
                    }
                    final dataPoint = filterData[spotIndex];
                    return LineTooltipItem(
                        "${dataPoint['date']} : ${dataPoint['resistanceValue']}점",
                        TextStyle(fontSize: 18,color: Color(0xff2A7FFF))
                    );
                  }).toList();
                }
            )
        )
    );
  }

  /// x축 하단 레이블
  Widget bottomTitleWidget(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 14,
    );
    final int index = value.toInt();
    Widget text;
    if (index >= 0 && index < filterData.length) {
      text = Text(filterData[index]['date'], style: style);
    } else {
      text = const Text('', style: style);
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 8.0,
      child: text,
    );
  }

  /// y축 좌측 레이블 위젯
  Widget leftTitleWidget(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.black,
      fontSize: 14,
    );
    String text;
    // value : 차트 상 y축 크기 당 1 value
    switch (value.toInt()) {
      case 0:
        text = '0';
        break;
      case 25:
        text = '25';
        break;
      case 50:
        text = '50';
        break;
      case 75:
        text = '75';
        break;
      case 100:
        text = '100';
        break;
      default:
        return Container();
    }
    return Text(text, style: style, textAlign: TextAlign.center);
  }

  @override
  Widget build(BuildContext context) {
    if(isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final String updateReplacementDate = carData['replacementDate'] != null
        ? carData['replacementDate'].substring(0, 10)
        : '앞으로 180일';

    int filterScore = carData['filterScore'];
    String performanceText;

    switch (filterScore) {
      case int score when score >= 80 && score <= 100:
        performanceText = '완벽한 상태입니다.';
        break;
      case int score when score >= 60 && score < 80:
        performanceText = '우수한 상태입니다.';
        break;
      case int score when score >= 40 && score < 60:
        performanceText = '적정 수준의 상태입니다.';
        break;
      case int score when score >= 20 && score < 40:
        performanceText = '성능이 저하되었습니다.';
        break;
      case int score when score >= 0 && score < 20:
        performanceText = '교체를 권장합니다.';
        break;
      default:
        performanceText = '필터 상태를 확인할 수 없습니다.';
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Home();
        }
      },
    child: SingleChildScrollView(
      child: Container(
        margin: EdgeInsets.fromLTRB(16, 78, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Container(
              child: Row(
                children: [
                  Text(userData['name'] ?? '',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
                  Text('님의 필터상태를 분석해 봤어요!',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w400, color: Colors.black),),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('차량',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500, color: Colors.black),),
                            Text(carData['model'] ?? '',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700, color: Colors.black),),
                          ],
                        ),
                      ),
                      SizedBox(height: 10,),
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('예상 필터 교체일',style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500, color: Colors.black),),
                            Text(updateReplacementDate,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700, color: Colors.black),),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 70,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('현재 점수',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700, color: Colors.black),),
                            Text('${carData['filterScore']}점' ?? '',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700, color: Colors.black),),
                          ],
                        ),
                      ),
                      SizedBox(height: 20,),
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(performanceText,style: TextStyle(fontSize: 16,fontWeight: FontWeight.w700, color: Colors.black),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 나의 필터상태 분석
            Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 10),
              padding: EdgeInsets.fromLTRB(15, 1, 15, 1),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color(0xff2A7FFF),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '나의 필터 상태 분석',
                style: TextStyle(
                  color: Color(0xff2A7FFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){
                      String date1w = '1w';
                      getFilterByDate(date1w);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectButton == '1w' ? Color(0xff2A7FFF) : Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: Text(
                      '1주일',
                      style: TextStyle(fontSize: 12, color: _selectButton == '1w' ? Color(0xff2A7FFF) : Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){
                      String date1m = '1m';
                      getFilterByDate(date1m);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectButton == '1m' ? Color(0xff2A7FFF) : Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: Text(
                      '1개월',
                      style: TextStyle(fontSize: 12, color: _selectButton == '1m' ? Color(0xff2A7FFF) : Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){
                      String date3m = '3m';
                      getFilterByDate(date3m);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectButton == '3m' ? Color(0xff2A7FFF) : Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: Text(
                      '3개월',
                      style: TextStyle(fontSize: 12, color: _selectButton == '3m' ? Color(0xff2A7FFF) : Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){
                      String date6m = '6m';
                      getFilterByDate(date6m);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectButton == '6m' ? Color(0xff2A7FFF) : Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: Text(
                      '6개월',
                      style: TextStyle(fontSize: 12, color: _selectButton == '6m' ? Color(0xff2A7FFF) : Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){
                      String date12m = '12m';
                      getFilterByDate(date12m);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: _selectButton == '12m' ? Color(0xff2A7FFF) : Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: Text(
                      '12개월',
                      style: TextStyle(fontSize: 12, color: _selectButton == '12m' ? Color(0xff2A7FFF) : Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            // 그래프
            Container(
              margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: LineChart(mainData()),
                  ),
                ),
            ),
            // 나의 필터상태 분석
            Container(
              margin: EdgeInsets.fromLTRB(0, 50, 0, 10),
              padding: EdgeInsets.fromLTRB(15, 1, 15, 1),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Color(0xff2A7FFF),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '차량 실내 공기질 분석',
                style: TextStyle(
                  color: Color(0xff2A7FFF),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: const Text(
                      '1주일',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: const Text(
                      '1개월',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: const Text(
                      '3개월',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: const Text(
                      '6개월',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 5),
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Color(0xffD0D0D0),
                          width: 1,
                        ),
                      ),
                      padding: EdgeInsets.zero,
                      minimumSize: Size(50, 25),
                    ),
                    child: const Text(
                      '12개월',
                      style: TextStyle(fontSize: 12, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            // 그래프
            Container(
              margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
              child: AspectRatio(
                aspectRatio: 3 / 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: LineChart(secondData()),
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




LineChartData secondData() {
  return LineChartData(
      minX: 0,
      maxX: 12,
      minY: 0,
      maxY: 100,
      titlesData: FlTitlesData( // 차트 레이블
        show: true,
        bottomTitles: AxisTitles( // x축 하단 표시
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 25, // 레이블 공간 확보
            interval: 1,
            getTitlesWidget: secondBottomTitleWidget,
          ),
        ),
        leftTitles: AxisTitles( // y축 좌측표시
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: secondLeftTitleWidget,
          ),
        ),
        topTitles: AxisTitles( // x축 상단 표시
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: AxisTitles( // y축 우측 표시
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData( // 차트 외부 테두리
          show: true,
          border: Border.all(color: Color(0xffD0D0D0), width: 1)
      ),
      gridData: FlGridData( // 차트 내부 그리드 선
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 12.5, // 간격
        verticalInterval: 1, // 간격
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Color(0xffD0D0D0),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Color(0xffD0D0D0),
            strokeWidth: 1,
          );
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: [
            FlSpot(0, 50),
            FlSpot(1, 37.5),
            FlSpot(2, 35),
            FlSpot(3, 37.5),
            FlSpot(4, 55),
            FlSpot(5, 74),
            FlSpot(6, 65),
            FlSpot(7, 50),
            FlSpot(8, 56),
            FlSpot(9, 61),
            FlSpot(10, 47),
            FlSpot(11, 52),
            FlSpot(12, 63),
          ],
          isCurved: true,
          color: Color(0xff2A7FFF),
          barWidth: 3,
          isStrokeCapRound: false, // 차트 선의 처음과 끝을 둥글게 처리
          dotData: FlDotData( // spot마다 표시 여부
            show: false,
          ),
        ),
      ],
      lineTouchData: LineTouchData( // 차트 선 툴팁
          touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  return LineTooltipItem("${touchedSpot.y.toInt()}",
                      TextStyle(fontSize: 18,color: Color(0xff2A7FFF))
                  );
                }).toList();
              }
          )
      )
  );
}

/// x축 하단 레이블
Widget secondBottomTitleWidget(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Colors.black,
    fontSize: 14,
  );
  Widget text;
  // value : 각 x축 값
  switch (value.toInt()) {
    case 0:
      text = const Text('0', style: style);
      break;
    case 2:
      text = const Text('1', style: style);
      break;
    case 4:
      text = const Text('2', style: style);
      break;
    case 6:
      text = const Text('3', style: style);
      break;
    case 8:
      text = const Text('4', style: style);
      break;
    case 10:
      text = const Text('5', style: style);
      break;
    case 12:
      text = const Text('6', style: style);
      break;
    default:
      text = const Text('', style: style);
      break;
  }

  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 8.0,
    child: text,
  );
}

/// y축 좌측 레이블 위젯
Widget secondLeftTitleWidget(double value, TitleMeta meta) {
  const style = TextStyle(
    color: Colors.black,
    fontSize: 14,
  );
  String text;
  // value : 차트 상 y축 크기 당 1 value
  switch (value.toInt()) {
    case 0:
      text = '0';
      break;
    case 25:
      text = '25';
      break;
    case 50:
      text = '50';
      break;
    case 75:
      text = '75';
      break;
    case 100:
      text = '100';
      break;
    default:
      return Container();
  }
  return Text(text, style: style, textAlign: TextAlign.center);
}

// 정보탭
class Information extends StatefulWidget {
  const Information({super.key});

  @override
  State<Information> createState() => _InformationState();
}

class _InformationState extends State<Information> {
  late final String _front_url;
  bool isLoading = true;

  late List<Map<String, dynamic>> filterAllData = [];

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  Future<void> loadData() async {
    await getCarInfo();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getCarInfo() async {
    var result = await http.get(Uri.parse(_front_url+'/api/v1/information/new-filter'));
    var resultData = jsonDecode(result.body);
    filterAllData = List<Map<String, dynamic>>.from(resultData['data']);
    // print(filterAllData);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return
      PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          CarHomePage();
        }
      },
      child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 78, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Container(
                child: Text('알면 더 좋은 유용한 정보들',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
              ),
              // 필터교체방법
              Container(
                margin: EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('필터 교체 방법이 궁금하신가요?',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w600),),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FilterChangePage()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        margin: EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: Color(0xffF0EFFF),
                          borderRadius: BorderRadius.circular(17),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // 오른쪽 위 화살표
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Icon(Icons.arrow_outward, size: 45, color: Colors.white,),
                            ),

                            // 왼쪽 아래 이미지 공간
                            // Positioned(
                            //   bottom: 10,
                            //   left: 10,
                            //   child: Container(
                            //     width: 50,
                            //     height: 50,
                            //     color: Colors.grey[300], // 이미지 삽입 시 이 부분 교체
                            //     child: Icon(Icons.image, color: Colors.grey),
                            //   ),
                            // ),

                            // 가운데 텍스트
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '필터 교체 ',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff3C8BFF)
                                    ),
                                  ),
                                  Text(
                                    '방법 알아보기',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff3C8BFF)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              // 필터구경
              Container(
                margin: EdgeInsets.fromLTRB(0, 25, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('클라떼의 다양한 필터 구경하기',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w600),),
                    Container(
                      height: 155,
                      margin: EdgeInsets.only(top: 5),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(filterAllData.length, (index) {
                            return Container(
                              width: 120,
                              margin: EdgeInsets.only(right: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => ProductDetailPage(productNum : filterAllData[index]['newArrivalFilterId']!)),
                                      );
                                    },
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(filterAllData[index]['image']!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    filterAllData[index]['productName']! ?? '',
                                    style: TextStyle(fontSize: 18,fontWeight: FontWeight.w400),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final Uri url = Uri.parse('https://www.clarte.store/');
                            // final Uri url = Uri.parse(productDetail['link']); // 추후 변경필요
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '더 많은 제품 보러가기',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(Icons.arrow_forward, size: 17, color: Colors.black,),
                            ],
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
              // 알고보면 쉬워요
              Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('내 차, 알고보면 쉬워요.',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w600),),
                    Container(
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        childAspectRatio: 0.6,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          // 첫 번째 박스
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InfoTab1()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xff2A7FFF),
                                borderRadius: BorderRadius.circular(27),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 13, 8, 0),
                                        child: Icon(Icons.arrow_outward,size: 40, color: Colors.white,),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(17, 5, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '자동차',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                              Text(
                                                ' 구매 전',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '반드시',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                              Text(
                                                ' 챙겨야 할 ',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '체크리스트',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/images/info1.png',
                                        width: 123,
                                        height: 123,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 두 번째 박스
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InfoTab2()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xff20DF93),
                                borderRadius: BorderRadius.circular(27),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 13, 8, 0),
                                        child: Icon(Icons.arrow_outward,size: 40, color: Colors.white,),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(17, 5, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '자동차 ',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                              Text(
                                                '초보를 ',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                              Text(
                                                '위한',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '유지보수 ',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                              Text(
                                                '루틴',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/images/info2.png',
                                        width: 123,
                                        height: 123,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // 세 번째 박스
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InfoTab3()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xffFF9D00),
                                borderRadius: BorderRadius.circular(27),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 13, 8, 0),
                                        child: Icon(Icons.arrow_outward,size: 40, color: Colors.white,),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(17, 5, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '세차는 ',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                              Text(
                                                '언제, 어떻게',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '해야 할까?',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/images/info3.png',
                                        width: 123,
                                        height: 123,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 네 번째 박스
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InfoTab4()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xff004594),
                                borderRadius: BorderRadius.circular(27),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.topRight,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 13, 8, 0),
                                        child: Icon(Icons.arrow_outward,size: 40, color: Colors.white,),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      margin: EdgeInsets.fromLTRB(17, 5, 0, 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '차량 경고등,',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '무시하면 안 되는 ',
                                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                                              ),
                                              Text(
                                                '이유',
                                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Image.asset(
                                        'assets/images/info4.png',
                                        width: 123,
                                        height: 123,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}



class BottomBar extends StatelessWidget {
  const BottomBar(
      {super.key, required this.selectedIndex, required this.onItemTapped});

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.error),
          label: '정보',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt),
          label: '분석',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: '알림',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '마이페이지',
        ),
      ],
      currentIndex: selectedIndex,
      onTap: onItemTapped,
      selectedItemColor: Color(0xff20DF93),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedLabelStyle: TextStyle(fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    );
  }
}


void _showLogOutDialog(BuildContext context) async {
  final storage = FlutterSecureStorage();

  LoginPlatform platform = LoginPlatform.none;
  String? platformString = await storage.read(key: 'platform');
  // 문자열을 enum으로 매핑
  if (platformString == LoginPlatform.google.toString()) {
    platform = LoginPlatform.google;
  } else if (platformString == LoginPlatform.kakao.toString()) {
    platform = LoginPlatform.kakao;
  }

  final LogoutHandler logoutHandler = LogoutHandler();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text('로그아웃하시겠습니까?\n(현재 플랫폼: ${platform.name})',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // 스토리지 로그아웃
                  await logoutHandler.logout();
                  // 플랫폼 로그아웃
                  platform = LoginPlatform.none;

                  // 로그아웃 후 페이지 이동
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffD0D0D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: Text('로그아웃', style: TextStyle(color: Colors.black),),
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
                child: Text('취소', style: TextStyle(color: Colors.white)),
              ),
            ],

          ),
        ],
      );
    },
  );
}
