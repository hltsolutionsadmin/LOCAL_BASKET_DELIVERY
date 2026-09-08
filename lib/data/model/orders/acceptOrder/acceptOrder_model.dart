class AcceptOrderModel {
  AcceptOrderModel({
    required this.selfOrder,
    required this.orderId,
    required this.totalPrice,
    required this.deliveryCharge,
    required this.deliveryPartnerId,
    required this.userName,
    required this.status,
  });

  final bool? selfOrder;
  final String? orderId;
  final num? totalPrice;
  final num? deliveryCharge;
  final String? deliveryPartnerId;
  final String? userName;
  final String? status;

  factory AcceptOrderModel.fromJson(Map<String, dynamic> json) {
    return AcceptOrderModel(
      selfOrder: json["selfOrder"],
      orderId: json["orderId"],
      totalPrice: json["totalPrice"],
      deliveryCharge: json["deliveryCharge"],
      deliveryPartnerId: json["deliveryPartnerId"],
      userName: json["userName"],
      status: json["status"],
    );
  }
}
