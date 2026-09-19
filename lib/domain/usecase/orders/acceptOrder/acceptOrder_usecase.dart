import 'package:localbasket_delivery_partner/data/model/orders/acceptOrder/acceptOrder_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/orders/acceptOrder/acceptOrder_repository.dart';

class AcceptOrderUseCase {
  final AcceptOrderRepository repository;

  AcceptOrderUseCase({required this.repository});

  Future<AcceptOrderModel> call(String orderId, String deliveryPartnerId) {
    return repository.acceptOrder(orderId, deliveryPartnerId);
  }
}
