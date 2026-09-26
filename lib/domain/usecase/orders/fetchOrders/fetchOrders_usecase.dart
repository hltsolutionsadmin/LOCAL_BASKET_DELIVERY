import 'package:localbasket_delivery_partner/data/model/orders/FetchOrders/fetchOrders_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/orders/fetchOrders/fetchOrders_repository.dart';

class FetchOrdersUseCase {
  final FetchOrdersRepository repository;

  FetchOrdersUseCase({required this.repository});

  Future<FetchOrdersModel> call(Map<String, dynamic> params) async {
    return await repository.fetchOrders(params);
  }
}

/// Single order (`api/orders/{id}`) — full shipping address, store and
/// customer details shown once the partner accepts the order.
class FetchOrderDetailsUseCase {
  final FetchOrdersRepository repository;

  FetchOrderDetailsUseCase({required this.repository});

  Future<Content> call(String orderId) async {
    return await repository.fetchOrderDetails(orderId);
  }
}
