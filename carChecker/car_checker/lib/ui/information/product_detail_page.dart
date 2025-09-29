import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../url.dart';

class ProductDetailPage extends StatefulWidget {
  final int productNum;
  const ProductDetailPage({super.key, required this.productNum});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final String _front_url;
  int _productNum = 0;
  bool isLoading = true;
  Map<String, dynamic> productDetail = {};

  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    _productNum = widget.productNum;
    loadData();
  }

  Future<void> loadData() async {
    await getFilter(_productNum);
    setState(() {
      isLoading = false;
    });
  }

  // 필터이력 확인 함수
  Future<void> getFilter(int num) async {
    var result = await http.get(Uri.parse(_front_url+'/api/v1/information/new-filter/$num'));
    var resultData = jsonDecode(result.body);
    productDetail = resultData['data'];
    // print(resultData);
    // print(productDetail);
    if (resultData['code'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제품 단건 조회 성공')),
      );
    } else {
      // 필터이력 확인 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('제품 단건 조회 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(16, 5, 0, 10),
                  child: Text('제품 상세 페이지',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(10, 0, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제품사진
                      Container(
                        width: 360,
                        height: 360,
                        child: Image.network(
                          productDetail['image'], // 이미지 링크
                          width: 360,
                          height: 360,
                          fit: BoxFit.contain,
                        ),
                        // child: Image.asset('/assets/image/G70_filter.png', width: 360, height: 360,fit: BoxFit.contain,),
                      ),
                      SizedBox(height: 10,),
                      // 제품 제목
                      Container(
                        child: Text(productDetail['productName'],
                          style: TextStyle(fontSize: 18,fontWeight: FontWeight.w600, color: Colors.black),
                        ),
                      ),
                      SizedBox(height: 10,),
                      // 제품 설명
                      Container(
                        child: Html(
                            data: productDetail['content'] ?? '',
                            style: {
                              "body": Style(
                                fontSize: FontSize(17),
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            }
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                        width: 362,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xff2A7FFF),
                          borderRadius: BorderRadius.zero,
                        ),
                        child: TextButton(
                          onPressed: () async {
                            // final Uri url = Uri.parse('https://www.clarte.store/');
                            final Uri url = Uri.parse(productDetail['link']); // 추후 변경필요
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
                              '제품으로 이동',
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}