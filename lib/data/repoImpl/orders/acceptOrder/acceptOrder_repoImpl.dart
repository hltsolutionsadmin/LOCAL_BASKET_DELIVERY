import 'package:localbasket_delivery_partner/data/dataSource/orders/acceptOrder/acceptOrder_dataSource.dart';
import 'package:localbasket_delivery_partner/data/model/orders/acceptOrder/acceptOrder_model.dart';
import 'package:localbasket_delivery_partner/domain/repository/orders/acceptOrder/acceptOrder_repository.dart';

class AcceptOrderRepositoryImpl implements AcceptOrderRepository {
  final AcceptOrderRemoteDataSource remoteDataSource;

  AcceptOrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AcceptOrderModel> acceptOrder(String orderId, String deliveryPartnerId) {
    return remoteDataSource.acceptOrder(orderId, deliveryPartnerId);
  }
}
