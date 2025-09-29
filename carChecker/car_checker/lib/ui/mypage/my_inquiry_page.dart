import 'package:flutter/material.dart';

class MyInquiryPage extends StatelessWidget {
  const MyInquiryPage({super.key});

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
                margin: EdgeInsets.fromLTRB(16, 5, 0, 40),
                child: Text('고객센터',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(32, 0, 32, 0),
                padding: EdgeInsets.fromLTRB(30, 60, 10, 10),
                decoration: BoxDecoration(
                  color: Color(0xffF4F4F4),
                  borderRadius: BorderRadius.circular(100),
                ),
                height: 485,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.call,size: 40,color: Color(0xff2A7FFF),),
                              Text('고객센터',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text('051-972-5222',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w400),),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(Icons.email,size: 40,color: Color(0xff2A7FFF),),
                              Text('이메일',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text('joeunfiltech@joeunfiltech.co.kr',style: TextStyle(fontSize: 17,fontWeight: FontWeight.w400),),
                        ],
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/Inquiry.png')
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
