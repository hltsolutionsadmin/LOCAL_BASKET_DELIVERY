import 'package:dio/dio.dart';
import 'package:localbasket_delivery_partner/core/constants/api_constants.dart';
import 'package:localbasket_delivery_partner/data/model/orders/acceptOrder/acceptOrder_model.dart';

abstract class AcceptOrderRemoteDataSource {
  Future<AcceptOrderModel> acceptOrder(String orderId, String deliveryPartnerId);
}

class AcceptOrderRemoteDataSourceImpl implements AcceptOrderRemoteDataSource {
  final Dio client;

  AcceptOrderRemoteDataSourceImpl({required this.client});

  @override
  Future<AcceptOrderModel> acceptOrder(
      String orderId, String deliveryPartnerId) async {
    try {
      final response = await client.post(
        '$baseUrl${acceptOrderUrl(orderId)}',
        data: {'deliveryPartnerId': deliveryPartnerId},
      );

      print('AcceptOrder Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AcceptOrderModel.fromJson(response.data);
      } else {
        throw Exception(
            'Failed to AcceptOrder. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('AcceptOrder Error: $e');
      throw Exception('AcceptOrder failed: ${e.toString()}');
    }
  }
}
