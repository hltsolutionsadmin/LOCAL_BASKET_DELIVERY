import 'package:localbasket_delivery_partner/presentation/cubit/orders/fetchOrders/fetchOrders_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/fetchOrders/fetchOrders_state.dart';
import 'package:localbasket_delivery_partner/presentation/screens/dashboard/widgets/orderCard_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_cubit.dart';
import 'package:localbasket_delivery_partner/presentation/cubit/orders/updateOrderStatus/updateOrderStatus_state.dart';

class BuildOrders extends StatefulWidget {
  final String status;
  final String partnerId;

  const BuildOrders(this.status, this.partnerId, {super.key});

  @override
  State<BuildOrders> createState() => _BuildOrdersState();
}

class _BuildOrdersState extends State<BuildOrders> {
  final ScrollController _scrollController = ScrollController();
  int currentPage = 0;
  final int pageSize = 10;
  bool isLoadingMore = false;
  bool allPagesLoaded = false;
  List<dynamic> allOrders = [];
  String? customStatusText;
  Widget? paymentBadge;

  @override
  void initState() {
    super.initState();
    _fetchOrders();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 100 &&
          !isLoadingMore &&
          !allPagesLoaded) {
        currentPage++;
        _fetchOrders(isPaginating: true);
      }
    });
  }

  void _fetchOrders({bool isPaginating = false}) {
    final params = {
      "partnerId": widget.partnerId,
      "page": currentPage,
      "size": pageSize,
    };

    if (isPaginating) setState(() => isLoadingMore = true);

    context.read<FetchOrdersCubit>().fetchOrders(params).then((_) {
      if (mounted) setState(() => isLoadingMore = false);
    });
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    final status = widget.status.toUpperCase();

    return orders.where((order) {
      final orderStatus = (order.deliveryStatus ?? "").toUpperCase();

      if (status == "ACCEPTED") {
        return [
          "ASSIGNED",
          "CONFIRMED",
          "PENDING",
          "PREPARING",
          "READY_FOR_PICKUP",
          "PICKED_UP",
          "OUT_FOR_DELIVERY",
          "IN_PROGRESS"
        ].contains(orderStatus);
      } else if (status == "DELIVERED") {
        return orderStatus == "DELIVERED";
      }

      return false;
    }).toList();
  }

  String formatStatus(String status) {
    return status
        .replaceAll("_", " ")
        .toLowerCase()
        .split(" ")
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(" ");
  }

  // PAYMENT BADGE UI
  Widget buildPaymentBadge(String? mode) {
    final clean = (mode ?? "").toUpperCase();

    Color bg;
    Color text;

    switch (clean) {
      case "COD":
        bg = Colors.orange.shade100;
        text = Colors.orange.shade800;
        break;

      case "ONLINE":
      case "PREPAID":
        bg = Colors.green.shade100;
        text = Colors.green.shade700;
        break;

      case "WALLET":
        bg = Colors.blue.shade100;
        text = Colors.blue.shade700;
        break;

      default:
        bg = Colors.grey.shade200;
        text = Colors.grey.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        clean,
        style: TextStyle(
          fontSize: 12,
          color: text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdateOrderStatusCubit, UpdateOrderStatusState>(
      listener: (context, state) {
        if (state is UpdateOrderStatusLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Updating order status...")),
          );
        } else if (state is UpdateOrderStatusSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Order status updated.")),
          );
          currentPage = 0;
          allOrders.clear();
          _fetchOrders();
        } else if (state is UpdateOrderStatusFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update status.")),
          );
        }
      },
      child: BlocConsumer<FetchOrdersCubit, FetchOrdersState>(
        listener: (context, state) {
          if (state is FetchOrdersSuccess) {
            final newOrders = _filterOrders(state.orders.data?.content ?? []);
            setState(() {
              if (currentPage == 0) {
                allOrders = newOrders;
              } else {
                allOrders.addAll(newOrders);
              }
              allPagesLoaded = state.orders.data?.last ?? true;
            });
          }
        },
        builder: (context, state) {
          if (state is FetchOrdersLoading && currentPage == 0) {
            return _buildLoading();
          }

          if (state is FetchOrdersFailure) {
            return _buildError("Failed to Fetch Orders");
          }

          if (allOrders.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: allOrders.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < allOrders.length) {
                final order = allOrders[index];

                return Column(
                  children: [
                    OrderCardWidget(
                      order: order,
                      customStatusText:
                          formatStatus(order.deliveryStatus ?? ""),
                      paymentBadge: buildPaymentBadge(order.paymentStatus),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CupertinoActivityIndicator());

  Widget _buildError(String message) =>
      Center(child: Text(message, style: GoogleFonts.poppins()));

  Widget _buildEmpty() => const Center(
        child: Text("No accepted or delivered orders found."),
      );
}
