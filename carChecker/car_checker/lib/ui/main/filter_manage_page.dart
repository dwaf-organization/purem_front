import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../url.dart';

class FilterManagePage extends StatefulWidget {
  const FilterManagePage({super.key});

  @override
  State<FilterManagePage> createState() => _FilterManagePageState();
}

class _FilterManagePageState extends State<FilterManagePage> {
  static final storage = FlutterSecureStorage();
  late final String _front_url;
  dynamic userId = '';
  bool isLoading = true;
  bool _isAutoReconnecting = false;
  String _currentCommand = '';
  bool _isWaitingForResponse = false;
  int page = 1;
  Map<String, dynamic> userCar = {};

  Map<String, dynamic> filterInfo = {};

  // BLE 통신 관련 변수들
  BluetoothDevice? _selectedDevice;
  String _bleConnectionStatus = "연결된 필터 없음";
  // 연결 상태 스트림 구독 관리 변수
  StreamSubscription<BluetoothConnectionState>? _bleConnectionStateSubscription;
  StreamSubscription<List<int>>? _dataStreamSubscription;

  // 공장장용
  // String _receivedData = '31 2E 35 2C 31 2E 35 2C 31 30 30 0D 31 2E 35 2C 31 2E 35 2C 31 30 30 0D 31 2E 35 2C 31 2E 35 2C 31 30 30 0D 45 4E 44';
  // 일반용
  String _receivedData = '';

  String _writeLog = '';
  String _notificationLog = '';
  String _decodedData = '';


  @override
  void initState() {
    super.initState();
    _front_url = UrlConfig.serverUrl.toString();
    loadData();
    _loadLastConnectedDevice(); // 앱 시작 시 마지막 연결 장치 정보 불러오기
  }

  // 이전에 연결되었던 장치 정보 불러오기 및 자동 연결 시도 로직 추가
  Future<void> _loadLastConnectedDevice() async {
    String? lastDeviceId = await storage.read(key: 'lastConnectedBleDeviceId');

    if (lastDeviceId != null && lastDeviceId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _bleConnectionStatus = "이전 장치 연결 중...";
          _isAutoReconnecting = true;
        });
      }

      try {
        // 1. 이미 연결된 장치 중 해당 ID가 있는지 확인
        List<BluetoothDevice> connectedDevices = FlutterBluePlus.connectedDevices;
        BluetoothDevice? deviceToConnect = connectedDevices.firstWhereOrNull(
              (d) => d.remoteId.toString() == lastDeviceId,
        );

        if (deviceToConnect == null) {
          // 2. 시스템에 알려진 장치(페어링 이력) 중 해당 ID가 있는지 확인
          // THIS IS THE CORRECTED LINE: Await the first emission from the systemDevices stream.
          List<BluetoothDevice> systemDevices = await FlutterBluePlus.systemDevices([]);
          deviceToConnect = systemDevices.firstWhereOrNull(
                (d) => d.remoteId.toString() == lastDeviceId,
          );
        }

        if (deviceToConnect != null) {
          _selectedDevice = deviceToConnect;
          // print('이전 장치 발견: ${deviceToConnect.platformName}, 연결 시도...');
          await _connectToSelectedDevice(); // 찾은 장치에 연결 시도
        } else {
          // print('이전 연결 장치 ($lastDeviceId)를 찾을 수 없습니다.');
          if (mounted) {
            setState(() {
              _bleConnectionStatus = "연결된 필터 없음 (장치 찾기 실패)";
              _isAutoReconnecting = false;
            });
          }
        }
      } catch (e) {
        // print('이전 장치 연결 시도 중 오류 발생: $e');
        if (mounted) {
          setState(() {
            _bleConnectionStatus = "연결된 필터 없음 (자동 연결 실패)";
            _isAutoReconnecting = false;
          });
        }
      }
    } else {
      // print('저장된 마지막 연결 장치 ID가 없습니다.');
      if (mounted) {
        setState(() {
          _bleConnectionStatus = "연결된 필터 없음";
          _isAutoReconnecting = false;
        });
      }
    }
  }

  // 마지막으로 연결된 장치 정보 저장
  Future<void> _saveLastConnectedDevice(BluetoothDevice device) async {
    await storage.write(key: 'lastConnectedBleDeviceName', value: device.platformName);
    await storage.write(key: 'lastConnectedBleDeviceId', value: device.remoteId.toString());
  }

  Future<void> loadData() async {
    userId = await storage.read(key: 'userId');
    await getCarInfo();
    await getFilter(page);
    if (mounted) { // setState 호출 전 mounted 확인
      setState(() {
        isLoading = false;
        // 공장장용
        // _decodedData = _hexToAscii(_receivedData);
      });
    }
  }

  Future<void> getCarInfo() async {
    var result = await http.get(Uri.parse('$_front_url/api/v1/cars/$userId'));
    var resultData = jsonDecode(result.body);

    if (resultData['data'] != null) {
      userCar = resultData['data'];
    } else {
      userCar = {
        "carId": 1,
        "carNumber": "12가 1234",
        "model": "GV70",
        "modelDetail": "GV70 (JK1) F/L"
      };
    }
    // print(userCar);
  }

  // 필터이력 확인 함수
  Future<void> getFilter(int index) async {
    var result = await http.get(Uri.parse('$_front_url/api/v1/filter-history/2?page=1&size=5'));
    var resultData = jsonDecode(result.body);
    filterInfo = resultData['data'];
    // print(resultData);
    // print(filterInfo);
    if (resultData['code'] == 1) {
      // final items = resultData['data']?['items'] ?? [];
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필터이력 확인 실패')),
        );
      }
    }
  }

  // _connectToSelectedDevice 함수 리팩토링 및 connectionState 구독 관리
  Future<void> _connectToSelectedDevice() async {
    if (_selectedDevice == null) {
      // print('연결할 장치가 선택되지 않았습니다.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결할 장치가 선택되지 않았습니다.')),
        );
        setState(() {
          _bleConnectionStatus = "연결된 필터 없음";
        });
      }
      return;
    }

    try {
      final currentConnectionState = await _selectedDevice!.connectionState.first;

      if (currentConnectionState == BluetoothConnectionState.connected) {
        await _selectedDevice!.disconnect();
        // print('기존 연결 해제: ${_selectedDevice!.platformName}');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      await _selectedDevice!.connect();
      // print('${_selectedDevice!.platformName} 장치에 연결되었습니다.');

      _sendAsciiCommandAndListen();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedDevice!.platformName}에 연결되었습니다.')),
        );
        setState(() {
          _bleConnectionStatus = "연결됨: ${_selectedDevice!.platformName}"; // UI 상태 업데이트
        });
      }

      // --- 기존 구독이 있다면 취소하고 새로 구독 ---
      _bleConnectionStateSubscription?.cancel();
      _bleConnectionStateSubscription = _selectedDevice!.connectionState.listen((BluetoothConnectionState state) {
        if (state == BluetoothConnectionState.disconnected) {
          // print('${_selectedDevice!.platformName} 장치 연결이 끊어졌습니다.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${_selectedDevice!.platformName} 연결이 끊어졌습니다.')),
            );
            setState(() {
              _selectedDevice = null; // 연결 끊김 시 선택 장치 초기화
              _bleConnectionStatus = "연결된 필터 없음"; // UI 상태 업데이트
            });
          }
        }
      });

    } catch (e) {
      // print('장치 연결 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('장치 연결 실패: $e')),
        );
        setState(() {
          _bleConnectionStatus = "연결된 필터 없음 (연결 실패)";
          _selectedDevice = null;
        });
      }
    }
  }

  // 아스키 RAW 데이터를 사람이 읽을 수 있는 문자열로 변환하는 헬퍼 함수
  String _hexToAscii(String hexString) {
    List<String> hexList = hexString.split('-');
    String result = '';
    for (String hex in hexList) {
      if (hex.length == 2) {
        int charCode = int.parse(hex, radix: 16);

        if (charCode == 13) { // 0D(13)를 줄바꿈(\n)으로 변환
          result += '\n';
        } else if (charCode >= 32 && charCode <= 126) { // 출력 가능한 문자
          result += String.fromCharCode(charCode);
        }
        // 그 외의 제어 문자는 무시
      }
    }
    return result;
  }

  /// 명령어를 보낸 후, 알림을 활성화하고 데이터를 수신하는 로직
  Future<void> _sendAsciiCommandAndListen() async {
    if (_selectedDevice == null) {
      // print('데이터를 보낼 장치가 선택되지 않았습니다.');
      return;
    }

    final List<int> commandBytes = [0x47, 0x45, 0x54, 0x5F, 0x44, 0x41, 0x54, 0x41, 0x0D];
    final List<int> deleteBytes = [0x44, 0x45, 0x4C, 0x45, 0x54, 0x45, 0x5F, 0x41, 0x4C, 0x4C, 0x5F, 0x44, 0x41, 0x54, 0x41, 0x0D];

    // 기존 구독 취소
    _dataStreamSubscription?.cancel();

    try {
      List<BluetoothService> services = await _selectedDevice!.discoverServices();

      BluetoothCharacteristic? notifyCharacteristic;
      BluetoothCharacteristic? writeCharacteristic;

      // 서비스와 캐릭터리스틱 탐색
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.notify) {
            notifyCharacteristic = characteristic;
            // print('Notify 속성을 가진 캐릭터리스틱 발견: ${characteristic.uuid}');
          }
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            writeCharacteristic = characteristic;
            // print('Write 속성을 가진 캐릭터리스틱 발견: ${characteristic.uuid}');
          }
        }
      }

      if (notifyCharacteristic != null && writeCharacteristic != null) {
        // 1. Notification 활성화 (nRF Connect의 "Notification enabled"와 동일)
        await notifyCharacteristic.setNotifyValue(true);
        // print('Notification이 활성화되었습니다.');

        _currentCommand = 'GET_DATA';
        _isWaitingForResponse = true;

        await writeCharacteristic.write(
          commandBytes,
          withoutResponse: writeCharacteristic.properties.writeWithoutResponse,
        );

        // 3. 데이터 수신 대기 (listen)
        _dataStreamSubscription = notifyCharacteristic.lastValueStream.listen((List<int> value) async {
            try {
              if (value.isNotEmpty && _isWaitingForResponse) {

                // print('아스키 RAW 데이터: ${value.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')}');
                String rawValue = value.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join('-');

                if (_currentCommand == 'GET_DATA') {
                  // GET_DATA 응답 처리
                  setState(() {
                    _decodedData = _hexToAscii(rawValue);
                  });

                  if (!_isAutoReconnecting) {
                    try {
                      await _createFilterRequest();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                      return;
                    }
                  }

                  // 필터값 주입 요청
                  await _sendFilterValue(rawValue);

                  // 성공하면 DELETE 명령 전송
                  _currentCommand = 'DELETE_ALL_DATA';

                  // delete 잠시 주석 ///////////////
                  await writeCharacteristic?.write(deleteBytes, withoutResponse: true);

                } else if (_currentCommand == 'DELETE_ALL_DATA') {
                  // DELETE 응답 처리 (UI 업데이트 없음)
                  print('DELETE 명령 완료: $rawValue');
                  _isWaitingForResponse = false;
                  _currentCommand = '';
                }
              } else {
                // print('수신된 데이터가 비어있는 리스트입니다.');
              }
            } catch (e) {
              // print('수신된 데이터 디코딩 중 오류 발생: $e');
            }
          },
          onError: (e) => print('데이터 스트림 오류: $e'),
          onDone: () => print('스트림 종료'),
        );

      } else {
        // print('필요한 notify 또는 write 캐릭터리스틱을 찾지 못했습니다.');
      }

    } catch (e) {
      // print('BLE 통신 중 오류 발생: $e');
    }
  }

  // 필터값 전송 함수 분리
  Future<void> _sendFilterValue(String rawValue) async {
    var uri = Uri.parse(_front_url + "/api/v1/filter/value");

    Map<String, String> headers = {"Content-Type": "application/json"};
    Map data = {
      "carId": userCar['carId'],
      "filterValue": rawValue,
    };

    var response = await http.post(uri, headers: headers, body: json.encode(data));
    var resultData = jsonDecode(response.body);

    if (resultData['code'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('필터입력 성공')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('필터입력 실패')),
      );
    }
  }

  // 필터 히스토리 생성함수
  Future<void> _createFilterRequest() async {

    try {
      var uri = Uri.parse(_front_url + "/api/v1/filter-history/$userId"); // 필터 생성 엔드포인트

      Map<String, String> headers = {
        "Content-Type": "application/json"
      };

      var response = await http.post(uri, headers: headers);

      var resultData = jsonDecode(response.body);
      if (resultData['code'] == 1) {
        print('필터 생성 성공');
      } else {
        print('필터 생성 실패');
        throw Exception('필터 생성 실패');
      }
    } catch (e) {
      print('필터 생성 중 오류: $e');
      throw e; // 생성 실패 시 상위로 예외 전파
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final items = filterInfo['items'] ?? [];
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
            padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  size: 35,
                  weight: 700,
                  color: Colors.black,
                )),
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Container(
            margin: const EdgeInsets.fromLTRB(0, 5, 0, 10),
            child: const Text('나의 필터 관리',style: TextStyle(fontSize: 20,fontWeight: FontWeight.w700, color: Color(0xff2A7FFF)),),
          ),
          Column(
            children: [
              // --- 변경: 현재 연결된 필터 UI ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '현재 연결된 필터', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                    child: Text(
                      _bleConnectionStatus, // _bleConnectionStatus 변수 사용
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const Divider(
                    color: Color(0xffD0D0D0),
                    thickness: 1.5,
                  ),
                ],
              ),
              //
              // // 공장장용
              // Container(
              //   padding: const EdgeInsets.all(8.0),
              //   margin: const EdgeInsets.only(bottom: 16.0),
              //   decoration: BoxDecoration(
              //     border: Border.all(color: Colors.grey),
              //     borderRadius: BorderRadius.circular(8.0),
              //   ),
              //   child: Text(
              //     '수신된 Data: \n$_decodedData',
              //     style: const TextStyle(fontFamily: 'monospace'),
              //     textAlign: TextAlign.center,
              //   ),
              // ),
              // Container(
              //   padding: const EdgeInsets.all(8.0),
              //   margin: const EdgeInsets.only(bottom: 16.0),
              //   decoration: BoxDecoration(
              //     border: Border.all(color: Colors.grey),
              //     borderRadius: BorderRadius.circular(8.0),
              //   ),
              //   child: Text(
              //     '원본 Data: \n$_receivedData',
              //     style: const TextStyle(fontFamily: 'monospace'),
              //     textAlign: TextAlign.center,
              //   ),
              // ),

              Container(
                margin: const EdgeInsets.only(top: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '나의 필터점수를 알아보기 위해 ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '필터를 연결해주세요.',
                          style: TextStyle(fontSize: 13, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        // 독립된 BLE 스캔 다이얼로그 호출
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return _BleScanDialogContent(
                              onDeviceSelected: (device) async {
                                // 다이얼로그에서 장치 선택 시 호출될 콜백
                                if (mounted) { // 메인 페이지의 State가 mounted 상태인지 확인
                                  setState(() {
                                    _selectedDevice = device;
                                    _bleConnectionStatus = "연결됨: ${device.platformName}"; // UI 상태 업데이트
                                  });
                                }
                                await _saveLastConnectedDevice(device); // 마지막 연결 장치 저장
                                _connectToSelectedDevice(); // 선택된 장치와 연결 시도
                              },
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 310,
                        height: 145,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 10,
                              offset: const Offset(3, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '필터 교체하기',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 10),
                              Icon(Icons.replay, size: 40, color: Color(0xff2A7FFF)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 25),
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(15, 5, 15, 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xff2A7FFF),
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '나의 필터 교체 이력',
                        style: TextStyle(
                          color: Color(0xff2A7FFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '순차',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '등록일',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          items.isEmpty
                              ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80, horizontal: 10),
                            child: Center(
                              child: Text(
                                '필터 교체 이력이 없습니다.',
                                style: TextStyle(fontSize: 18, color: Colors.black),
                              ),
                            ),
                          )
                              :
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filterInfo['items'].length,
                            itemBuilder: (context, index) {
                              final item = filterInfo['items'][index];
                              final parsedDate = DateTime.parse(item['replacementDate']);
                              final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);
                              return Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(item['filterChangeHistoryId'].toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(formattedDate, style: const TextStyle(fontSize: 14),),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.close, color: Color(0xff7C7C7C), size: 20),
                                              onPressed: () async {
                                                final bool? result = await showDeleteDialog(context, item['filterChangeHistoryId']);
                                                if (result == true) { // 삭제 성공 시에만 새로고침
                                                  await getFilter(page);
                                                  if (mounted) { // setState 호출 전 mounted 확인
                                                    setState(() {}); // 삭제 후 UI 갱신을 위해 추가
                                                  }
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(color: Color(0xffD0D0D0), height: 0),
                                ],
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Color(0xffD0D0D0), size: 12),
                                onPressed: page > 1
                                    ? () {
                                  if (mounted) { // setState 호출 전 mounted 확인
                                    setState(() {
                                      page = page - 1;
                                    });
                                  }
                                  getFilter(page);
                                }
                                    : null,
                              ),
                              ...List.generate(5, (index) => TextButton(

                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(20, 10),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  if (mounted) { // setState 호출 전 mounted 확인
                                    setState(() {
                                      page = index + 1;
                                    });
                                  }
                                  getFilter(page);
                                },
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                  ),
                                ),
                              )),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios, color: Color(0xffD0D0D0) , size: 16),
                                onPressed: (filterInfo['pagination']?['hasNext'] == true)
                                    ? () {
                                  if (mounted) { // setState 호출 전 mounted 확인
                                    setState(() {
                                      page = page + 1;
                                    });
                                  }
                                  getFilter(page);
                                }
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    ),
    ),
    );
  }

  @override
  void dispose() {
    _bleConnectionStateSubscription?.cancel();
    _bleConnectionStateSubscription = null;

    _dataStreamSubscription?.cancel();
    _dataStreamSubscription = null;

    super.dispose();
  }
}

// BLE 스캔 다이얼로그의 콘텐츠를 독립적인 StatefulWidget으로 분리 (이전과 동일)
class _BleScanDialogContent extends StatefulWidget {
  final ValueChanged<BluetoothDevice> onDeviceSelected;

  const _BleScanDialogContent({Key? key, required this.onDeviceSelected}) : super(key: key);

  @override
  _BleScanDialogContentState createState() => _BleScanDialogContentState();
}

class _BleScanDialogContentState extends State<_BleScanDialogContent> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  // 새로 추가된 변수: 선택된 장치의 이름을 저장 (다이얼로그 내부에서만 사용)
  String? _selectedDeviceName;

  @override
  void initState() {
    super.initState();
    _startScanForDialog();
  }

  // 스캔 시작
  void _startScanForDialog() async {
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
    }

    if (!mounted) return;
    setState(() {
      _scanResults = [];
      _isScanning = true;
      _selectedDeviceName = null;
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          _scanResults = results;
        });
      }
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((isScanning) {
      if (mounted) {
        setState(() {
          _isScanning = isScanning;
        });
      }
      if (!isScanning) {
        // print('스캔이 완료되었습니다.');
      }
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    // print('BLE 스캔 시작...');
  }

  // 스캔 중지 (내부용)
  Future<void> _stopScanInternal() async {
    if (await FlutterBluePlus.isScanning.first) {
      await FlutterBluePlus.stopScan();
      // print('BLE 스캔 중지.');
    }
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _stopScanInternal();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          _selectedDeviceName != null
              ? '선택된 장치: $_selectedDeviceName'
              : (_isScanning ? 'BLE 장치 스캔 중...' : 'BLE 장치 선택')
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            _isScanning && _scanResults.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(10.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
                : (_scanResults.isEmpty && !_isScanning
                ? const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('발견된 장치가 없습니다.'),
            )
                : Expanded(
              child: ListView.builder(
                itemCount: _scanResults.length,
                itemBuilder: (context, index) {
                  final result = _scanResults[index];
                  String deviceName = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : '알 수 없는 장치';
                  return ListTile(
                    title: Text(deviceName),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: Text('RSSI: ${result.rssi}'),
                    onTap: () async {
                      if (mounted) {
                        setState(() {
                          _selectedDeviceName = deviceName;
                        });
                      }
                      await Future.delayed(const Duration(milliseconds: 500)); // 짧은 지연

                      if (mounted) {
                        Navigator.of(context).pop();
                        widget.onDeviceSelected(result.device);
                      }
                    },
                  );
                },
              ),
            )),
            ElevatedButton(
              onPressed: () {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 추가: List.firstWhereOrNull 확장 함수 ---
// 이 함수는 'package:collection/collection.dart' 패키지에 포함되어 있지만,
// 편의를 위해 직접 추가하거나 해당 패키지를 pubspec.yaml에 추가하고 import 할 수 있습니다.
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}

// showDeleteDialog 함수 (이전과 동일)
Future<bool?> showDeleteDialog(BuildContext context, int filterChangeHistoryId) {
  String _front_url = UrlConfig.serverUrl.toString();

  return showDialog<bool?>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: const Center(child: Text('삭제 하시겠습니까?',style: TextStyle(fontSize: 18,fontWeight: FontWeight.w700),)),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () async {
                  var uri = Uri.parse('$_front_url/api/v1/filter-history/$filterChangeHistoryId');

                  Map<String, String> headers = {
                    "Content-Type": "application/json"
                  };

                  var response = await http.delete(uri, headers: headers);
                  // print(response.body);

                  var resultData = jsonDecode(response.body);
                  // print(resultData);
                  if (resultData['code'] == 1) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('필터삭제 성공')),
                      );
                      Navigator.of(dialogContext).pop(true);
                    }
                  } else {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('필터삭제 실패')),
                      );
                      Navigator.of(dialogContext).pop(false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffD0D0D0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: const Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('삭제', style: TextStyle(fontWeight: FontWeight.w400,color: Colors.black),),
              ),
              ElevatedButton(
                onPressed: () {
                  // print('취소됨');
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2A7FFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  fixedSize: const Size(107, 25),
                  padding: EdgeInsets.zero,
                ),
                child: const Text('취소', style: TextStyle(fontWeight: FontWeight.w400,color: Colors.white),),
              ),
            ],
          ),
        ],
      );
    },
  );
}