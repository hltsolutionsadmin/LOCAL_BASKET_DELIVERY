import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../model/authentication/trigger_otp_model.dart';

abstract class TriggerOtpRemoteDataSource {
  Future<TriggerOtpModel> fetchOtp(String mobileNumber);
}

class TriggerOtpRemoteDataSourceImpl implements TriggerOtpRemoteDataSource {
  final Dio client;

  TriggerOtpRemoteDataSourceImpl({required this.client});

  @override
  Future<TriggerOtpModel> fetchOtp(String mobileNumber) async {
    final payload = {
      "primaryContact": mobileNumber,
    };
    print('payload: $payload');
    try {
      final otpBaseUrl = baseUrl.replaceFirst('/api/', '');
      final response = await client.request(
        '$otpBaseUrl$TriggerOtp',
        options: Options(
          method: 'POST',
          headers: {'X-Skillrat-Tenant': 'default'},
        ),
        data: payload,
      );

      if (response.statusCode == 200) {
        return TriggerOtpModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load OTP data: ${response.statusCode}');
      }
    } catch (e) {
      print('error is otp data source::$e');
      throw Exception('Failed to load OTP data: ${e.toString()}');
    }
  }
}
