import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../model/authentication/signin_model.dart';

abstract class SignInRemoteDataSource {
  Future<SignInModel> signIn(String mobileNumber, String otp, String fullName);
}

class SignInRemoteDataSourceImpl implements SignInRemoteDataSource {
  final Dio client;

  SignInRemoteDataSourceImpl({required this.client});

  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('DEVICE_ID');
    if (deviceId == null || deviceId.isEmpty) {
      final random = Random();
      deviceId =
          'device-${DateTime.now().millisecondsSinceEpoch}-${random.nextInt(999999)}';
      await prefs.setString('DEVICE_ID', deviceId);
    }
    return deviceId;
  }

  @override
  Future<SignInModel> signIn(String mobileNumber, String otp, String fullName) async {
    final deviceId = await _getDeviceId();
    final payload = {
      "otp": otp,
      "primaryContact": mobileNumber,
      "fullName": fullName,
      "deviceId": deviceId,
    };

    try {
      print('Sending payload: $payload');

      final signinBaseUrl = baseUrl.replaceFirst('/api/', '');
      final response = await client.request(
        '$signinBaseUrl$SigninUrl',
        options: Options(
          method: 'POST',
          headers: {'X-Skillrat-Tenant': 'default'},
        ),
        data: payload,
      );

      print('Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Response data: ${response.data}');
        return SignInModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load OTP data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load OTP data: ${e.toString()}');
    }
  }
}
