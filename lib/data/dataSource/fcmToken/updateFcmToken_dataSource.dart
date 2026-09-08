import 'package:dio/dio.dart';
import 'package:localbasket_delivery_partner/core/constants/api_constants.dart';
import 'package:localbasket_delivery_partner/data/model/fcmToken/updateFcmToken_model.dart';

abstract class UpdateFcmTokenRemoteDataSource {
  Future<UpdateFcmTokenModel> updateFcmToken(String fcmToken, String deviceType);
}

class UpdateFcmTokenRemoteDataSourceImpl
    implements UpdateFcmTokenRemoteDataSource {
  final Dio client;

  UpdateFcmTokenRemoteDataSourceImpl({required this.client});

  @override
  Future<UpdateFcmTokenModel> updateFcmToken(
      String fcmToken, String deviceType) async {
    try {
      final response = await client.put(
        '$baseUrl$updateFcmTokenUrl',
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
        },
      );

      print('UpdateFcmToken Response [${response.statusCode}]: ${response.data}');

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return UpdateFcmTokenModel.fromJson(response.data);
      }
      throw Exception('Failed to update FCM token. Status code: $code');
    } catch (e) {
      print('UpdateFcmToken Error: $e');
      throw Exception('UpdateFcmToken failed: ${e.toString()}');
    }
  }
}
