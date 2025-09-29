import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'auth_car_model_registration_page.dart';

class AuthCarRegistrationPage extends StatefulWidget {
  final int userCode;
  const AuthCarRegistrationPage({super.key, required this.userCode});

  @override
  State<AuthCarRegistrationPage> createState() => _AuthCarRegistrationPageState();
}

class _AuthCarRegistrationPageState extends State<AuthCarRegistrationPage> {
  late Map<String, dynamic> dataList;
  final List<String> carNames = [
    'Genesis G90',
    'Genesis G80',
    'Genesis GV80',
    'Genesis G70',
    'Genesis GV70',
    'Genesis GV60',
    'Genesis EQ900',
  ];

  @override
  void initState() {
    super.initState();

    dataList = {
      "userCode": widget.userCode, // 여기서 접근!
    };
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
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(16, 5, 0, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('차량을',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.black),),
                    Text('선택해주세요.',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Colors.black),),
                  ],
                ),
              ),
              Container(
                height: 450,
                margin: EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: carNames.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // print('${carNames[index]} 클릭됨');
                        dataList['model'] = carNames[index];
                        // print(dataList);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AuthCarModelRegistrationPage(dataList: dataList,)),
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
                              carNames[index],
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