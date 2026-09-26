import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/dashboard_widgets.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/orderDetailsSection_widget.dart';

class OrderCardWidget extends StatelessWidget {
  final dynamic order;

  final String? customStatusText;
  final Widget? paymentBadge;

  /// While `true`, this card's action button shows a spinner (a status update
  /// for this order is in flight).
  final bool isUpdating;

  /// Show the order's `createdDate` under the order number (used on the
  /// Completed Orders screen).
  final bool showCreatedDate;

  const OrderCardWidget({
    super.key,
    required this.order,
    this.customStatusText,
    this.paymentBadge,
    this.isUpdating = false,
    this.showCreatedDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusRaw = order.orderStatus ?? "";
    final status = _formatStatus(statusRaw);
    // Before accept the card is collapsed to customer name, payment type and
    // the Accept button; after accept it expands with the order details API.
    final collapsed = statusRaw != "DELIVERED" && !_isAccepted(statusRaw);

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
          child: collapsed
              ? _buildCollapsed(context, statusRaw)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, status),
                    const SizedBox(height: 12),
                    _buildStatusProgress(statusRaw),
                    if (statusRaw != "DELIVERED")
                      OrderDetailsSection(
                          key: ValueKey(order.id), order: order),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.customerName ?? "Customer",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Order #${_last4(order.orderNumber)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (showCreatedDate && _createdDateText(order) != null) ...[
                const SizedBox(height: 2),
                Text(
                  _createdDateText(order)!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              statusChip(customStatusText ?? status),
            ],
          ),
        ),
        _paymentTypeBadge() ?? paymentBadge ?? const SizedBox(),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 4),
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

  /// Pickup/delivery locations are only revealed once the partner has
  /// accepted the order (dashboard step >= 1, or a post-accept status).
  bool _isAccepted(String status) => const [
        "PICKED_UP",
        "IN_DELIVERY",
        "OUT_FOR_DELIVERY",
      ].contains(status.toUpperCase());

  /// Before accept: only the customer name (`userId.name`), payment type and
  /// the Accept button.
  Widget _buildCollapsed(BuildContext context, String statusRaw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: Colors.blue.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.customerName ?? "Customer",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _paymentTypeBadge() ?? paymentBadge ?? const SizedBox(),
          ],
        ),
        const SizedBox(height: 12),
        _buildActionButtons(context, statusRaw),
      ],
    );
  }

  /// `paymentStatus` PENDING → collect cash; PAID/SUCCESS → prepaid online.
  Widget? _paymentTypeBadge() {
    final paymentStatus = (order.paymentStatus ?? "").toUpperCase();
    final String label;
    final Color bg;
    final Color fg;
    if (paymentStatus == "PENDING") {
      label = "Cash";
      bg = Colors.orange.shade100;
      fg = Colors.orange.shade800;
    } else if (const ["PAID", "SUCCESS", "COMPLETED"].contains(paymentStatus)) {
      label = "Paid Online";
      bg = Colors.green.shade100;
      fg = Colors.green.shade800;
    } else {
      return null;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // ACTION BUTTONS (REJECT RESTORED)
  // ------------------------------------------------------------------

  /// Status-driven flow:
  ///   READY        → "Accept"      → PICKED_UP
  ///   PICKED_UP    → "In Delivery" → IN_DELIVERY
  ///   IN_DELIVERY  → "Completed"   → DELIVERED
  ///   DELIVERED    → no button
  Widget _buildActionButtons(BuildContext context, String status) {
    final id = order.orderNumber.toString();

    void update(String next) {
      context.read<UpdateOrderStatusCubit>().updateOrderStatus(id, next);
    }

    switch (status.toUpperCase()) {
      case "READY":
      case "READY_FOR_PICKUP":
        return Row(
          children: [
            actionButton(
                "Accept", Colors.green.shade600, () => update("PICKED_UP"),
                isLoading: isUpdating),
          ],
        );

      case "PICKED_UP":
        return Row(
          children: [
            actionButton("In Delivery", Colors.blue.shade600,
                () => update("IN_DELIVERY"),
                isLoading: isUpdating),
          ],
        );

      case "IN_DELIVERY":
      case "OUT_FOR_DELIVERY":
        return Row(
          children: [
            actionButton(
                "Completed", Colors.orange.shade600, () => update("DELIVERED"),
                isLoading: isUpdating),
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

  String? _createdDateText(dynamic order) {
    final DateTime? created = order.createdDate;
    if (created == null) return null;
    return DateFormat('dd MMM yyyy, hh:mm a').format(created.toLocal());
  }
}
