class ReportsModel {
  ReportsModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final List<Datum> data;

  factory ReportsModel.fromJson(Map<String, dynamic> json) {
    return ReportsModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null
          ? []
          : List<Datum>.from(json["data"]!.map((x) => Datum.fromJson(x))),
    );
  }
}

class Datum {
  Datum({
    required this.periodLabel,
    required this.assignedCount,
    required this.deliveredCount,
    required this.pendingCount,
    required this.totalAmount,
    required this.averageAmountPerDeliveredRide,
  });

  final DateTime? periodLabel;
  final num? assignedCount;
  final num? deliveredCount;
  final num? pendingCount;
  final num? totalAmount;
  final num? averageAmountPerDeliveredRide;

  factory Datum.fromJson(Map<String, dynamic> json) {
    return Datum(
      periodLabel: DateTime.tryParse(json["periodLabel"] ?? ""),
      assignedCount: json["assignedCount"],
      deliveredCount: json["deliveredCount"],
      pendingCount: json["pendingCount"],
      totalAmount: json["totalAmount"],
      averageAmountPerDeliveredRide: json["averageAmountPerDeliveredRide"],
    );
  }
}
