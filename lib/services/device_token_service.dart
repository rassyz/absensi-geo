import 'dart:io';

import 'base_api_service.dart';

class DeviceTokenService extends BaseApiService {
  Future<void> saveToken(String fcmToken) async {
    if (fcmToken.trim().isEmpty) {
      return;
    }

    await postJson(
      '/device-tokens',
      body: {
        'token': fcmToken,
        'platform': Platform.isAndroid ? 'android' : 'unknown',
        'device_name': Platform.operatingSystemVersion,
      },
    );
  }

  Future<void> deleteToken(String fcmToken) async {
    if (fcmToken.trim().isEmpty) {
      return;
    }

    await deleteJson('/device-tokens', body: {'token': fcmToken});
  }
}
