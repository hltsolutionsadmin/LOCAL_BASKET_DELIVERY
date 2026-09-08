import 'package:localbasket_delivery_partner/data/model/orders/acceptOrder/acceptOrder_model.dart';

abstract class AcceptOrderState {}

class AcceptOrderInitial extends AcceptOrderState {}

class AcceptOrderLoading extends AcceptOrderState {}

class AcceptOrderSuccess extends AcceptOrderState {
  final AcceptOrderModel response;

  AcceptOrderSuccess(this.response);
}

class AcceptOrderFailure extends AcceptOrderState {
  final String error;

  AcceptOrderFailure(this.error);
}
