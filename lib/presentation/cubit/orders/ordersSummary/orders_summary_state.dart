abstract class OrdersSummaryState {}

class OrdersSummaryInitial extends OrdersSummaryState {}

class OrdersSummaryLoading extends OrdersSummaryState {}

class OrdersSummaryLoaded extends OrdersSummaryState {
  /// Number of orders in the selected range whose status is `DELIVERED`.
  final int deliveredCount;

  /// Sum of `deliveryCharge` across those delivered orders.
  final double revenue;

  /// Sum of `totalPrice` (order value) across those delivered orders.
  final double orderValue;

  /// Total orders created inside the selected range (any status).
  final int totalOrdersInRange;

  final DateTime from;
  final DateTime to;

  OrdersSummaryLoaded({
    required this.deliveredCount,
    required this.revenue,
    required this.orderValue,
    required this.totalOrdersInRange,
    required this.from,
    required this.to,
  });
}

class OrdersSummaryError extends OrdersSummaryState {
  final String message;

  OrdersSummaryError(this.message);
}
