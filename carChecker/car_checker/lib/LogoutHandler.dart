import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'api/login_platform.dart';

class LogoutHandler {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> logout() async {
    try {
      // 특정 키 'login' 삭제
      await _storage.delete(key: 'login');
      await _storage.delete(key: 'userId');
      await _storage.write(key: 'platform', value: LoginPlatform.none.toString());
      await _storage.delete(key: 'alarmCheck');

      await GoogleSignIn().signOut();
      // 카카오 토큰이 있는지 먼저 확인합니다.
      // 토큰이 있을 때만 로그아웃을 수행하여, 유효하지 않은 토큰으로 인한 에러를 방지합니다.
      if (await AuthApi.instance.hasToken()) {
        await UserApi.instance.logout();
      } else {
        // 토큰이 없으므로 로그아웃 로직을 건너뜁니다.
        // print('카카오 토큰이 없어 로그아웃을 건너뜁니다.');
      }
      // 로그아웃 후 필요한 추가 작업 수행
      // print('로그아웃 완료: login 키 삭제됨');
    } catch (e) {
      // print('로그아웃 중 에러 발생: $e');
    }
  }
}