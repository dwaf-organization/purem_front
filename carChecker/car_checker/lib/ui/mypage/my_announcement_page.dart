import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../url.dart';

import '../main/home_page.dart';

class MyAnnouncementPage extends StatefulWidget {
  const MyAnnouncementPage({super.key});

  @override
  State<MyAnnouncementPage> createState() => _MyAnnouncementPageState();
}

class _MyAnnouncementPageState extends State<MyAnnouncementPage> {
  late final String _front_url;
  bool isLoading = true;
  int noticeId = 0;
  List<Map<String, dynamic>> noticeInfo = [];

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
  }

  Future<void> loadData() async {
    await getNotice();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getNotice() async {
    var result = await http.get(Uri.parse(_front_url+'/api/v1/notice'));
    var resultData = jsonDecode(result.body);
    noticeInfo = List<Map<String, dynamic>>.from(resultData['data']);
    // print(noticeInfo);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return PopScope(
      canPop: true, // 시스템 pop 허용
      onPopInvokedWithResult: (didPop, result) {
        // 시스템이 pop을 하지 않은 경우 (예: 루트 페이지)
        if (!didPop && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // 이전 페이지로 이동
        }
      },
      child:
      Scaffold(
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
                child: Text('공지사항',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
              ),
              Container(
                height: 600,
                child: ListView.builder(
                  itemCount: noticeInfo.length,
                  itemBuilder: (context, index) {
                    final notice = noticeInfo[index];
                    DateTime parsedDate = DateTime.parse(notice['createdAt']).toLocal();
                    final date = parsedDate.toString().split(' ')[0];
                    final time = parsedDate.toString().split(' ')[1].substring(0, 5);
                    return ExpansionTile(
                      title: Text(notice['title']),
                      subtitle: Row(
                        children: [
                          Text(
                            date,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          SizedBox(width: 5),
                          Text(
                            time,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: double.infinity,
                            color: Color(0xffF4F4F4),
                            padding: EdgeInsets.only(left: 25),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Html(
                                  data: notice['content'],
                                  style: {
                                    "body": Style(
                                      fontSize: FontSize(13),
                                      margin: Margins.all(0),
                                    ),
                                  }
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

