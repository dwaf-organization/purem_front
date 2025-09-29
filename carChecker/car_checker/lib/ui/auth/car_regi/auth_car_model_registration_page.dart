import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../main/car_num_registration_page.dart';
import 'auth_car_num_registration_page.dart';

class AuthCarModelRegistrationPage extends StatefulWidget {
  final Map<String, dynamic> dataList;
  const AuthCarModelRegistrationPage({super.key, required this.dataList});

  @override
  State<AuthCarModelRegistrationPage> createState() => _AuthCarModelRegistrationPageState();
}

class _AuthCarModelRegistrationPageState extends State<AuthCarModelRegistrationPage> {

  final List<String> G90ModelNames = [
    'G90 (RS4)',
    '신형 G90',
    '제네시스 G90',
  ];
  final List<String> G80ModelNames = [
    'G80 EV (RG3) F/L',
    '더 올 뉴 G80 (RG3) F/L',
    'eG80 (RG3)',
    '더 올 뉴 G80 (RG3)',
    '제네시스 G80 (DH)'
  ];
  final List<String> GV80ModelNames = [
    '제네시스 GV80'
  ];
  final List<String> G70ModelNames = [
    '더 뉴 G70 (IK)',
    '제네시스 G70'
  ];
  final List<String> GV70ModelNames = [
    'GV70 (JK1) F/L',
    'GV70 (JK1) EV F/L',
    'GV70 (JK1)',
  ];
  final List<String> GV60ModelNames = [
    'GV60 (JW) F/L',
    'GV60'
  ];
  final List<String> EQ900ModelNames = [
    'EQ900 (HI)'
  ];

  late final List<String> modelNames;

  @override
  void initState() {
    super.initState();
    // print(widget.dataList);
    getModel();
    // print(modelNames);
  }

  getModel() async {
    if(widget.dataList['model'] == 'Genesis G90') {
      modelNames = G90ModelNames;
    } else if(widget.dataList['model'] == 'Genesis G80') {
      modelNames = G80ModelNames;
    } else if(widget.dataList['model'] == 'Genesis GV80') {
      modelNames = GV80ModelNames;
    } else if(widget.dataList['model'] == 'Genesis G70') {
      modelNames = G70ModelNames;
    } else if(widget.dataList['model'] == 'Genesis GV70') {
      modelNames = GV70ModelNames;
    } else if(widget.dataList['model'] == 'Genesis GV60') {
      modelNames = GV60ModelNames;
    } else if(widget.dataList['model'] == 'Genesis EQ900') {
      modelNames = EQ900ModelNames;
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('모델을',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.black),),
                    Text('선택해주세요.',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.black),),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(16, 5, 0, 30),
                child: Text(widget.dataList['model'],style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
              ),
              Container(
                height: 450,
                margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: modelNames.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // print('${modelNames[index]} 클릭됨');
                        widget.dataList['modelDetail'] = modelNames[index];
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AuthCarNumRegistrationPage(dataList: widget.dataList,)),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 5),
                        padding: EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xffE6E6E6),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              modelNames[index],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}