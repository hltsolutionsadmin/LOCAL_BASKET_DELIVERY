import 'dart:async';
import 'package:localbasket_delivery_partner/core/constants/img_const.dart';
import 'package:localbasket_delivery_partner/core/utils/push_notication_services.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/update/update_current_customer_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/screens/authentication/login_screen.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/deliveryPartnerDashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final NotificationServices _notificationServices = NotificationServices();

  bool _navigateManually = false;

  @override
  void initState() {
    super.initState();
    _startNavigationLogic();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationServices.requestNotificationPermissions();
    await _notificationServices.forgroundMessage();

    if (!mounted) return;
    await _notificationServices.firebaseInit(context);

    if (!mounted) return;
    await _notificationServices.setupInteractMessage(context);

    if (!mounted) return;
    await _notificationServices.isRefreshToken();

    _notificationServices.getDeviceToken().then((fcmToken) {
      if (!mounted) return;
      if (fcmToken != null) {
        print('FCM Token: $fcmToken');
        final payload = {
          'fullName': '',
          'email': '',
          "fcmToken": fcmToken,
        };
        context
            .read<UpdateCurrentCustomerCubit>()
            .updateCustomer(payload, context);
      }
    });
  }

  Future<void> _startNavigationLogic() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('TOKEN');
    final isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      _navigateTo(const LoginScreen());
      return;
    }

    if (token == null || token.isEmpty) {
      _navigateTo(const LoginScreen());
      return;
    }

    await context.read<CurrentCustomerCubit>().GetCurrentCustomer(context);
    setState(() => _navigateManually = true);
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return BlocListener<CurrentCustomerCubit, CurrentCustomerState>(
      listener: (context, state) {
        if (!_navigateManually) return;

        if (state is CurrentCustomerLoaded) {
          final model = state.currentCustomerModel;
          final roles = model.roles.map((r) => r.name).toList();
          final hasDeliveryRole = roles.contains('ROLE_DELIVERY_PARTNER');

          if (hasDeliveryRole) {
            _navigateManually = false;
            _navigateTo(const DeliveryPartnerDashboard());
          } else {
            _navigateManually = false;
            // ScaffoldMessenger.of(context).showSnackBar(
            //   SnackBar(
            //     behavior: SnackBarBehavior.floating,
            //     backgroundColor: Colors.black87,
            //     margin:
            //         const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(14),
            //     ),
            //     content: Row(
            //       children: [
            //         const Icon(
            //           Icons.lock_outline,
            //           color: Colors.white,
            //           size: 18,
            //         ),
            //         const SizedBox(width: 10),
            //         Expanded(
            //           child: Text(
            //             'You dont have access to this application',
            //             style: const TextStyle(
            //               color: Colors.white,
            //               fontSize: 14,
            //               fontWeight: FontWeight.w600,
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //     duration: const Duration(milliseconds: 1500),
            //   ),
            // );
            Future.delayed(const Duration(milliseconds: 800), () {
              _navigateTo(const LoginScreen());
            });
          }
        } else {
          _navigateManually = false;
          _navigateTo(const LoginScreen());
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              delivery,
              fit: BoxFit.cover,
            ),
            Container(
              color: Colors.black.withOpacity(0.6), // dark overlay for contrast
            ),
            // Center(
            //   child: Column(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Text(
            //         'LocalBasket Partner',
            //         style: GoogleFonts.montserrat(
            //           fontSize: 40,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white,
            //           letterSpacing: 1.5,
            //         ),
            //       ),
            //       const SizedBox(height: 8),
            //       Text(
            //         'Delivering on time, every time',
            //         style: GoogleFonts.poppins(
            //           color: Colors.white70,
            //           fontSize: 14,
            //           fontStyle: FontStyle.italic,
            //           letterSpacing: 1,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
