import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:localbasket_delivery_partner/core/constants/api_constants.dart';
import 'package:localbasket_delivery_partner/data/model/reports/reports_model.dart';

abstract class ReportsRemoteDataSource {
  Future<ReportsModel> reports(
      String frequency, String from, String to, String format);
  Future<List<int>> downloadExcel(
      String frequency, String from, String to);
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  final Dio client;

  ReportsRemoteDataSourceImpl({required this.client});

  @override
  Future<ReportsModel> reports(
      String frequency, String from, String to, String format) async {
    try {
      final response = await client.request(
        '$baseUrl${reportsUrl(frequency, from, to, format)}',
        options: Options(method: 'GET'),
      );
      if (response.statusCode == 200) {
        print('responce of Reports:: $response');
        return ReportsModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load Reports data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load Reports data: ${e.toString()}');
    }
  }

  @override
  Future<List<int>> downloadExcel(
      String frequency, String from, String to) async {
    try {
      final response = await client.request(
        '$baseUrl${reportsUrl(frequency, from, to, 'excel')}',
        options: Options(
          method: 'GET',
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200 && response.data is List<int>) {
        return List<int>.from(response.data as List);
      } else if (response.statusCode == 200 && response.data is Uint8List) {
        return (response.data as Uint8List).toList();
      } else {
        throw Exception(
            'Failed to download Excel: ${response.statusCode ?? 'unknown'}');
      }
    } catch (e) {
      throw Exception('Failed to download Excel: ${e.toString()}');
    }
  }
}
