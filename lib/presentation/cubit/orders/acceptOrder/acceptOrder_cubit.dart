import 'package:bloc/bloc.dart';
import 'package:localbasket_delivery_partner/domain/usecase/orders/acceptOrder/acceptOrder_usecase.dart';
import 'acceptOrder_state.dart';

class AcceptOrderCubit extends Cubit<AcceptOrderState> {
  final AcceptOrderUseCase useCase;

  AcceptOrderCubit(this.useCase) : super(AcceptOrderInitial());

  Future<void> acceptOrder(String orderId, String deliveryPartnerId) async {
    try {
      emit(AcceptOrderLoading());
      final result = await useCase.call(orderId, deliveryPartnerId);
      emit(AcceptOrderSuccess(result));
    } catch (e) {
      emit(AcceptOrderFailure(e.toString()));
    }
  }
}
