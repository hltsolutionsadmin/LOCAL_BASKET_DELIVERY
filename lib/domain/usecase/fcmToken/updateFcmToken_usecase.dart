import 'dart:io' show Platform;

import 'package:localbasket_delivery_partner/data/model/fcmToken/updateFcmToken_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/fcmToken/updateFcmToken_repository.dart';

class UpdateFcmTokenUseCase {
  final UpdateFcmTokenRepository repository;

  UpdateFcmTokenUseCase({required this.repository});

  Future<UpdateFcmTokenModel> call(String fcmToken, {String? deviceType}) {
    return repository.updateFcmToken(
      fcmToken,
      deviceType ?? _currentDeviceType(),
    );
  }

  String _currentDeviceType() {
    if (Platform.isAndroid) return 'ANDROID';
    if (Platform.isIOS) return 'IOS';
    return 'WEB';
  }
}
