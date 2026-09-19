import 'package:localbasket_delivery_partner/data/model/orders/updateOrderStatus/updateOrderStatus_model.dart';

abstract class UpdateOrderStatusState {}

class UpdateOrderStatusInitial extends UpdateOrderStatusState {}

class UpdateOrderStatusLoading extends UpdateOrderStatusState {
  /// The order currently being updated, so only its card shows a busy button.
  final String orderId;
  final String status;

  UpdateOrderStatusLoading(this.orderId, this.status);
}

class UpdateOrderStatusSuccess extends UpdateOrderStatusState {
  final UpdateOrderStatusModel response;
  final String orderId;

  UpdateOrderStatusSuccess(this.response, {this.orderId = ''});
}

class UpdateOrderStatusFailure extends UpdateOrderStatusState {
  final String error;
  final String orderId;

  UpdateOrderStatusFailure(this.error, {this.orderId = ''});
}
