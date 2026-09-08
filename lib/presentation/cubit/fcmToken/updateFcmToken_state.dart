import 'package:localbasket_delivery_partner/data/model/fcmToken/updateFcmToken_model.dart';

abstract class UpdateFcmTokenState {}

class UpdateFcmTokenInitial extends UpdateFcmTokenState {}

class UpdateFcmTokenLoading extends UpdateFcmTokenState {}

class UpdateFcmTokenSuccess extends UpdateFcmTokenState {
  final UpdateFcmTokenModel response;

  UpdateFcmTokenSuccess(this.response);
}

class UpdateFcmTokenFailure extends UpdateFcmTokenState {
  final String error;

  UpdateFcmTokenFailure(this.error);
}
