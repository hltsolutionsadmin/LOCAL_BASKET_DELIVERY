import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbasket_delivery_partner/domain/usecase/fcmToken/updateFcmToken_usecase.dart';
import 'updateFcmToken_state.dart';

class UpdateFcmTokenCubit extends Cubit<UpdateFcmTokenState> {
  final UpdateFcmTokenUseCase useCase;

  UpdateFcmTokenCubit(this.useCase) : super(UpdateFcmTokenInitial());

  Future<void> updateFcmToken(String fcmToken, {String? deviceType}) async {
    if (fcmToken.isEmpty) return;
    try {
      emit(UpdateFcmTokenLoading());
      final result = await useCase.call(fcmToken, deviceType: deviceType);
      emit(UpdateFcmTokenSuccess(result));
    } catch (e) {
      emit(UpdateFcmTokenFailure(e.toString()));
    }
  }
}
