import 'package:localbasket_delivery_partner/components/custom_topbar.dart';
import 'package:localbasket_delivery_partner/core/injection.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/authentication/currentcustomer/get/current_customer_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/fetchOrders/fetchOrders_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/buildOrders_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full history of delivered orders, kept out of the home screen (which only
/// shows today's active orders).
class CompletedOrdersScreen extends StatelessWidget {
  const CompletedOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerState = context.read<CurrentCustomerCubit>().state;
    final partnerId = customerState is CurrentCustomerLoaded
        ? customerState.currentCustomerModel.id
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: const CustomAppBar(title: "Completed Orders", orangeTheme: true),
      body: (partnerId == null || partnerId.isEmpty)
          ? Center(
              child: Text(
                "Unable to load partner details.",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            )
          // Scoped cubit instance so this screen's pagination doesn't
          // collide with the dashboard's 5s polling on the shared one.
          : BlocProvider<FetchOrdersCubit>(
              create: (_) => sl<FetchOrdersCubit>(),
              child: BuildOrders("DELIVERED", partnerId),
            ),
    );
  }
}
