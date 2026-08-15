class CurrentCustomerModel {
  CurrentCustomerModel({
    this.id,
    this.username,
    this.email,
    this.mobile,
    this.firstName,
    this.lastName,
    this.roles,
    this.b2bUnitId,
    this.b2bUnit,
    this.storeId,
    this.store,
  });

  final String? id;
  final String? username;
  final String? email;
  final String? mobile;
  final String? firstName;
  final String? lastName;
  final List<String>? roles;
  final dynamic b2bUnitId;
  final dynamic b2bUnit;
  final dynamic storeId;
  final dynamic store;

  String? get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return null;
    return '$first $last'.trim();
  }

  factory CurrentCustomerModel.fromJson(Map<String, dynamic> json) {
    return CurrentCustomerModel(
      id: json["id"],
      username: json["username"],
      email: json["email"],
      mobile: json["mobile"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      roles: json["roles"] == null
          ? []
          : List<String>.from(json["roles"]!.map((x) => x)),
      b2bUnitId: json["b2bUnitId"],
      b2bUnit: json["b2bUnit"],
      storeId: json["storeId"],
      store: json["store"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "email": email,
        "mobile": mobile,
        "firstName": firstName,
        "lastName": lastName,
        "roles": roles,
        "b2bUnitId": b2bUnitId,
        "b2bUnit": b2bUnit,
        "storeId": storeId,
        "store": store,
      };
}
