import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:localbasket_delivery_partner/presentation/cubit/orders/deliverOtpVerification/deliverOtpVerification_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/deliverOtpVerification/deliverOtpVerification_state.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/dashboard_widgets.dart';

class OrderCardWidget extends StatelessWidget {
  final dynamic order;

  final String? customStatusText;
  final Widget? paymentBadge;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.customStatusText,
    this.paymentBadge,
  });

  @override
  Widget build(BuildContext context) {
    final statusRaw = order.orderStatus ?? "";
    final status = _formatStatus(statusRaw);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, status),
              const SizedBox(height: 12),
              _buildStatusProgress(statusRaw),
              const SizedBox(height: 14),
              if (statusRaw != "DELIVERED") _buildAddressSection(context),
              const SizedBox(height: 12),
              _buildActionButtons(context, statusRaw),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, String status) {
    final paymentStatus = (order.paymentStatus ?? "").toUpperCase();

    Widget? autoPaymentBadge() {
      if (paymentStatus == "PENDING") {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Cash",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
        );
      }
      return null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order #${_last4(order.orderNumber)}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              statusChip(customStatusText ?? status),
            ],
          ),
        ),

        // ⭐ AUTO CASH BADGE → overrides paymentBadge → else nothing
        autoPaymentBadge() ?? paymentBadge ?? const SizedBox(),

        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.phone, color: Colors.green),
              onPressed: () => _showCall(context, order.mobileNumber),
            ),
            Text(
              "₹${order.totalAmount?.toStringAsFixed(2) ?? '--'}",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // PROGRESS BAR
  // ------------------------------------------------------------------

  Widget _buildStatusProgress(String status) {
    final stages = [
      "CONFIRMED",
      "READY_FOR_PICKUP",
      "PICKED_UP",
      "OUT_FOR_DELIVERY",
      "DELIVERED",
    ];

    int currentIndex = stages.indexOf(status);
    if (currentIndex < 0) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (currentIndex + 1) / stages.length,
          minHeight: 6,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(
            Colors.orange.shade400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Status: ${_formatStatus(status)}",
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // ADDRESS
  // ------------------------------------------------------------------

  Widget _buildAddressSection(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 24),
        _addressRow(
          "Pickup",
          order.businessAddress?.addressLine1 ?? "N/A",
          Icons.store,
          Colors.orange.shade400,
        ),
        const SizedBox(height: 12),
        _addressRow(
          "Delivery",
          order.userAddress?.addressLine1 ?? "N/A",
          Icons.delivery_dining,
          Colors.teal.shade400,
        ),
      ],
    );
  }

  Widget _addressRow(
      String title, String subtitle, IconData icon, Color color) {
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

  // ------------------------------------------------------------------
  // ACTION BUTTONS (REJECT RESTORED)
  // ------------------------------------------------------------------

  Widget _buildActionButtons(BuildContext context, String status) {
    final id = order.orderNumber.toString();

    switch (status) {
      // -----------------------------
      // BEFORE PICKUP
      // -----------------------------
      case "CONFIRMED":
      case "READY_FOR_PICKUP":
        return Row(
          children: [
            actionButton("Reject", Colors.red, () {
              context.read<UpdateOrderStatusCubit>().updateOrderStatus(
                    id,
                    "DELIVERY_REJECTED",
                  );
            }),
            const Spacer(),
            actionButton("Pick Up", Colors.green.shade600, () {
              context.read<UpdateOrderStatusCubit>().updateOrderStatus(
                    id,
                    "PICKED_UP",
                  );
            }),
          ],
        );

      // -----------------------------
      // AFTER PICKUP → show only Out For Delivery
      // -----------------------------
      case "PICKED_UP":
        return Row(
          children: [
            actionButton("Out for Delivery", Colors.blue.shade600, () {
              context.read<UpdateOrderStatusCubit>().updateOrderStatus(
                    id,
                    "OUT_FOR_DELIVERY",
                  );
            }),
          ],
        );

      // -----------------------------
      // AFTER OUT FOR DELIVERY → NOW show: Return + Reject + Deliver
      // -----------------------------
      case "OUT_FOR_DELIVERY":
        return Row(
          children: [
            actionButton("Return", Colors.red.shade400, () {
              context.read<UpdateOrderStatusCubit>().updateOrderStatus(
                    id,
                    "RETURNED",
                  );
            }),
            const SizedBox(width: 8),
            actionButton("Reject", Colors.red.shade700, () {
              context.read<UpdateOrderStatusCubit>().updateOrderStatus(
                    id,
                    "DELIVERY_REJECTED",
                  );
            }),
            const Spacer(),
            actionButton("Deliver", Colors.orange.shade600, () {
              _showOtpDialog(context, id);
            }),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ------------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------------

  String _formatStatus(String s) {
    if (s.isEmpty) return "--";
    s = s.replaceAll("_", " ").toLowerCase();
    return s[0].toUpperCase() + s.substring(1);
  }

  String _last4(String? num) {
    if (num == null || num.length <= 4) return num ?? "--";
    return num.substring(num.length - 4);
  }

  void _openMap(String address) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showCall(BuildContext context, String? number) {
    if (number == null) return;
    final uri = Uri.parse("tel:$number");
    launchUrl(uri);
  }

  // OTP dialog (unchanged)
  void _showOtpDialog(BuildContext context, String orderId) {
    final controller = TextEditingController();
    final cubit = context.read<DeliverOtpCubit>();

    cubit.triggerOtp(orderId);

    int resendSeconds = 30;
    final ValueNotifier<int> timerNotifier = ValueNotifier(resendSeconds);

    // Start 30s countdown
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerNotifier.value > 0) {
        timerNotifier.value--;
      } else {
        timer.cancel();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: BlocConsumer<DeliverOtpCubit, DeliverOtpState>(
              listener: (context, state) {
                if (state is DeliverOtpVerifySuccess) {
                  /// ⭐ AUTO UPDATE ORDER STATUS TO DELIVERED
                  context.read<UpdateOrderStatusCubit>().updateOrderStatus(
                        orderId,
                        "DELIVERED",
                      );

                  Navigator.pop(context); // close otp dialog
                }
              },
              builder: (context, state) {
                bool isLoading = state is DeliverOtpLoading;
                bool isError = state is DeliverOtpFailure;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Verify Delivery OTP",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      "Enter the 6-digit OTP sent to the customer.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: isError
                                ? Colors.red.withOpacity(0.18)
                                : Colors.grey.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: controller,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          letterSpacing: 3,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "••••••",
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            letterSpacing: 4,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color:
                                  isError ? Colors.red : Colors.orange.shade300,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (isError)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "Invalid or expired OTP",
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    /// 🔁 RESEND SECTION
                    ValueListenableBuilder<int>(
                      valueListenable: timerNotifier,
                      builder: (context, value, _) {
                        bool canResend = value == 0;

                        return GestureDetector(
                          onTap: canResend
                              ? () {
                                  cubit.triggerOtp(orderId);

                                  // Restart timer
                                  resendSeconds = 30;
                                  timerNotifier.value = resendSeconds;
                                  Timer.periodic(const Duration(seconds: 1),
                                      (timer) {
                                    if (timerNotifier.value > 0) {
                                      timerNotifier.value--;
                                    } else {
                                      timer.cancel();
                                    }
                                  });
                                }
                              : null,
                          child: Text(
                            canResend
                                ? "Resend OTP"
                                : "Resend OTP in ${value}s",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: canResend ? Colors.blue : Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    /// VERIFY BUTTON
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () => cubit.verifyOtp(
                                orderId,
                                controller.text.trim(),
                              ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 48,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: isLoading
                                ? [
                                    Colors.grey.shade400,
                                    Colors.grey.shade500,
                                  ]
                                : [
                                    Colors.orange.shade400,
                                    Colors.deepOrange.shade500,
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: isLoading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Verify OTP",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: GoogleFonts.poppins(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
