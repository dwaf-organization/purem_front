import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'car_num_registration_page.dart';

class CarModelRegistrationPage extends StatefulWidget {
  final Map<String, dynamic> dataList;
  const CarModelRegistrationPage({super.key, required this.dataList});

  @override
  State<CarModelRegistrationPage> createState() => _CarModelRegistrationPageState();
}

class _CarModelRegistrationPageState extends State<CarModelRegistrationPage> {

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

  List<String>? modelNames;

  @override
  void initState() {
    super.initState();
    // print(widget.dataList);
    getModel();
    // print(modelNames);
  }

  getModel() async {
    List<String>? result;
    switch (widget.dataList['model']) {
      case 'Genesis G90':
        result = G90ModelNames;
        break;
      case 'Genesis G80':
        result = G80ModelNames;
        break;
      case 'Genesis GV80':
        result = GV80ModelNames;
        break;
      case 'Genesis G70':
        result = G70ModelNames;
        break;
      case 'Genesis GV70':
        result = GV70ModelNames;
        break;
      case 'Genesis GV60':
        result = GV60ModelNames;
        break;
      case 'Genesis EQ900':
        result = EQ900ModelNames;
        break;
    }

    setState(() {
      modelNames = result ?? [];
    });
  }
  @override
  Widget build(BuildContext context) {
    if (modelNames == null) {
      return const Center(child: CircularProgressIndicator());
    }
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
                  itemCount: modelNames!.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        // print('${modelNames![index]} 클릭됨');
                        widget.dataList['modelDetail'] = modelNames![index];
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CarNumRegistrationPage(dataList: widget.dataList,)),
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
                              modelNames![index],
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