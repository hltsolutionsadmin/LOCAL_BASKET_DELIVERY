import 'package:localbasket_delivery_partner/components/custom_snackbar.dart';
import 'package:localbasket_delivery_partner/core/network/network_service.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbasket_delivery_partner/core/network/token_storage.dart';
import 'package:localbasket_delivery_partner/core/utils/push_notication_services.dart';
import '../../../../domain/usecase/authentication/signin_usecase.dart';
import 'signin_state.dart';

class SignInCubit extends Cubit<SignInState> {
  final SignInValidationUseCase useCase;
  final NetworkService networkService;
  SignInCubit({required this.useCase, required this.networkService})
      : super(SignInInitial());

  Future<void> signIn(BuildContext context, String mobileNumber, String otp,
      String fullName) async {
    print(
        'trigger otp 1 mobileNumber: $mobileNumber -- OTP: $otp -- fullName: $fullName');
    bool isConnected = await networkService.hasInternetConnection();
    if (!isConnected) {
      print("No Internet Connection");
      CustomSnackbars.showErrorSnack(
        context: context,
        title: 'Alert',
        message: 'Please check Internet Connection',
      );
      return;
    } else {
      if (otp.isEmpty || otp.length < 6) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(
                otp.isEmpty ? 'Please enter otp' : 'Please enter valid otp'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      try {
        emit(SignInLoading());
        final signEntity = await useCase(mobileNumber, otp, fullName);
        print('signEntity: $signEntity');

        if (signEntity.accessToken != null && signEntity.accessToken!.isNotEmpty) {
          await TokenStorage().saveTokens(
            accessToken: signEntity.accessToken,
            refreshToken: signEntity.refreshToken,
            expiresIn: signEntity.expiresIn,
          );
          context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
          // Register this device's FCM token now that we're authenticated.
          NotificationServices().registerFcmToken();
        } else {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Invalid OTP'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        emit(SignInLoaded(signEntity));
      } catch (e) {
        print('Sign in error: $e');
        emit(SignInError('Failed to validate OTP: ${e.toString()}'));
      }
    }
  }
}
