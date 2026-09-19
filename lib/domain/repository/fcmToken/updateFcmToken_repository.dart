import 'package:localbasket_delivery_partner/data/model/fcmToken/updateFcmToken_model.dart';

abstract class UpdateFcmTokenRepository {
  Future<UpdateFcmTokenModel> updateFcmToken(String fcmToken, String deviceType);
}
