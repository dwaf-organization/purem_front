import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleProvider with ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  String _connectionStatus = '연결된 필터 없음';

  BluetoothDevice? get connectedDevice => _connectedDevice;
  String get connectionStatus => _connectionStatus;

  // BLE 장치 연결 로직
  Future<void> connectToDevice(BluetoothDevice device) async {
    _connectionStatus = '연결 중...';
    notifyListeners();

    // 기존 연결이 있다면 해제
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }

    try {
      await device.connect();
      _connectedDevice = device;
      _connectionStatus = '연결됨: ${device.platformName}';
      // print('연결 성공: ${device.platformName}');
      // TODO: 연결 성공 후 데이터 수신 로직 시작 (여기에 _listenToBleData() 호출)

    } catch (e) {
      // print('연결 실패: $e');
      _connectedDevice = null;
      _connectionStatus = '연결 실패';
    } finally {
      notifyListeners();
    }
  }

  // 연결 해제 로직
  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _connectionStatus = '연결된 필터 없음';
      notifyListeners();
      // print('연결 해제됨');
    }
  }

// TODO: 여기에 _listenToBleData(), _dataStreamSubscription 등 추가
}