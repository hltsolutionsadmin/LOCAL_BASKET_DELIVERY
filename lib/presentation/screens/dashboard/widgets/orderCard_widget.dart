import 'dart:ui';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/deliverOtpVerification/deliverOtpVerification_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/deliverOtpVerification/deliverOtpVerification_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/dashboard_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderCardWidget extends StatelessWidget {
  final dynamic order;

  const OrderCardWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final status = (order.orderStatus ?? "").toUpperCase();
    final isDelivered = status == "DELIVERED";

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, status, isDelivered),
              if (!isDelivered) _buildAddressSection(context),
              const SizedBox(height: 12),
              _buildActionButtons(context, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String status, bool isDelivered) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Order #${_last4(order.orderNumber)}",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              statusChip(status.replaceAll('_', ' ')),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isDelivered)
              IconButton(
                icon: const Icon(Icons.phone, color: Colors.green),
                onPressed: () => _showCall(context, order.mobileNumber),
              ),
            Text("₹${order.totalAmount?.toStringAsFixed(2) ?? '--'}",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 24),
        _buildAddressRow(
          context,
          title: "Pickup",
          subtitle: order.businessAddress?.addressLine1 ?? "N/A",
          icon: Icons.restaurant,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildAddressRow(
          context,
          title: "Delivery",
          subtitle: order.userAddress?.addressLine1 ?? "N/A",
          icon: Icons.delivery_dining,
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildAddressRow(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: infoRow(
            icon: icon,
            color: color,
            title: title,
            subtitle: subtitle,
          ),
        ),
        IconButton(
          icon: Icon(Icons.navigation, color: color),
          onPressed: () => _openMap(subtitle),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    final orderId = order.orderNumber.toString();

    switch (status) {
      case "CONFIRMED":
      case "PENDING":
      case "READY_FOR_PICKUP":
        return Row(
          children: [
            actionButton("Reject", Colors.red, () {
              context
                  .read<UpdateOrderStatusCubit>()
                  .updateOrderStatus(orderId, "DELIVERY_REJECTED");
            }),
            const Spacer(),
            actionButton("Pick Up", Colors.green, () {
              context
                  .read<UpdateOrderStatusCubit>()
                  .updateOrderStatus(orderId, "PICKED_UP");
            }),
          ],
        );

      case "PICKED_UP":
        return Row(
          children: [
            actionButton("Reject", Colors.red, () {
              context
                  .read<UpdateOrderStatusCubit>()
                  .updateOrderStatus(orderId, "DELIVERY_REJECTED");
            }),
            const SizedBox(width: 8),
            actionButton("Return", const Color.fromARGB(255, 239, 108, 98), () {
              context
                  .read<UpdateOrderStatusCubit>()
                  .updateOrderStatus(orderId, "RETURNED");
            }),
            const SizedBox(width: 8),
            actionButton("Deliver", Colors.orange, () {
              _showOtpDialog(context, orderId);
            }),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showOtpDialog(BuildContext context, String orderId) {
    final controller = TextEditingController();
    final cubit = context.read<DeliverOtpCubit>();

    cubit.triggerOtp(orderId);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "OTP Dialog",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (_, anim, __, child) {
        return Transform.scale(
          scale: anim.value,
          child: Opacity(
            opacity: anim.value,
            child: BlocListener<DeliverOtpCubit, DeliverOtpState>(
              listener: (context, state) {
                if (state is DeliverOtpVerifySuccess) {
                  // ✅ Close OTP dialog only
                  Navigator.of(context, rootNavigator: true).pop();

                  // ✅ Update order status
                  context
                      .read<UpdateOrderStatusCubit>()
                      .updateOrderStatus(orderId, "DELIVERED");

                  // ✅ Confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Order marked as Delivered ✅")),
                  );
                }
              },
              child: AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Text("Enter Delivery OTP",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                content: BlocBuilder<DeliverOtpCubit, DeliverOtpState>(
                  builder: (context, state) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (state is DeliverOtpLoading)
                          const CupertinoActivityIndicator(),
                        if (state is DeliverOtpFailure)
                          Text(state.message,
                              style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: controller,
                          maxLength: 6,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "OTP",
                            labelStyle: GoogleFonts.poppins(),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => cubit.triggerOtp(orderId),
                              child: Text("Resend",
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[700])),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final otp = controller.text.trim();
                                if (otp.length == 6) {
                                  await cubit.verifyOtp(orderId, otp);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Enter full OTP")),
                                  );
                                }
                              },
                              child: Text("Verify & Deliver",
                                  style:
                                      GoogleFonts.poppins(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context, rootNavigator: true).pop(),
                    child: Text("Cancel", style: GoogleFonts.poppins()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCall(BuildContext context, String? number) {
    if (number == null) return;
    final uri = Uri.parse("tel:$number");
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_in_talk_rounded,
                size: 48, color: Colors.green),
            const SizedBox(height: 12),
            Text("Call the Customer?",
                style: GoogleFonts.poppins(fontSize: 18)),
            const SizedBox(height: 6),
            Text(number, style: GoogleFonts.poppins(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                launchUrl(uri);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.call, color: Colors.white),
              label: const Text("Call Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  void _openMap(String address) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  String _last4(String? num) => (num == null || num.length <= 4)
      ? (num ?? "--")
      : num.substring(num.length - 4);
}
