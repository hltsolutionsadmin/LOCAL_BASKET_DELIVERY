import 'package:localbasket_delivery_partner/data/model/orders/acceptOrder/acceptOrder_model.dart';

abstract class AcceptOrderRepository {
  Future<AcceptOrderModel> acceptOrder(String orderId, String deliveryPartnerId);
}
