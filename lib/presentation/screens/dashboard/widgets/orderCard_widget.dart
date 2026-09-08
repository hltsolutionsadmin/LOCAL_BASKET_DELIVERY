import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

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
      "IN_DELIVERY",
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

    void update(String next) {
      context.read<UpdateOrderStatusCubit>().updateOrderStatus(id, next);
    }

    switch (status.toUpperCase()) {
      // -----------------------------
      // JUST ASSIGNED → Accept moves it straight to PICKED_UP
      // -----------------------------
      case "ASSIGNED":
      case "ASSIGNED_TO_DELIVERY_PARTNER":
      case "PENDING":
      case "CONFIRMED":
      case "PREPARING":
      case "READY":
      case "READY_FOR_PICKUP":
        return Row(
          children: [
            actionButton("Accept", Colors.green.shade600, () => update("PICKED_UP")),
          ],
        );

      // -----------------------------
      // PICKED UP → show In Delivery
      // -----------------------------
      case "PICKED_UP":
        return Row(
          children: [
            actionButton(
                "In Delivery", Colors.blue.shade600, () => update("IN_DELIVERY")),
          ],
        );

      // -----------------------------
      // ON THE WAY → show Delivered
      // -----------------------------
      case "IN_DELIVERY":
      case "OUT_FOR_DELIVERY":
        return Row(
          children: [
            actionButton(
                "Delivered", Colors.orange.shade600, () => update("DELIVERED")),
          ],
        );

      // -----------------------------
      // DELIVERED → no actions left (card moves to Completed Orders)
      // -----------------------------
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
}
