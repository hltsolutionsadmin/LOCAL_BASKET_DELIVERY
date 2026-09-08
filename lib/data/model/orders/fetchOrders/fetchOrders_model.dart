/// Delivery-partner orders list.
///
/// Endpoint: GET api/fulfillment/orders/partner/{partnerId}?page&size
/// The response is a Spring `Page` object (no envelope), so [FetchOrdersModel]
/// simply wraps it in [data] to keep the existing call sites unchanged.
class FetchOrdersModel {
  FetchOrdersModel({required this.data});

  final Data? data;

  factory FetchOrdersModel.fromJson(Map<String, dynamic> json) {
    return FetchOrdersModel(data: Data.fromJson(json));
  }
}

class Data {
  Data({
    required this.content,
    required this.pageable,
    required this.last,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.sort,
    required this.first,
    required this.numberOfElements,
    required this.empty,
  });

  final List<Content> content;
  final Pageable? pageable;
  final bool? last;
  final num? totalElements;
  final num? totalPages;
  final num? size;
  final num? number;
  final List<Sort> sort;
  final bool? first;
  final num? numberOfElements;
  final bool? empty;

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      content: json["content"] == null
          ? []
          : List<Content>.from(
              json["content"]!.map((x) => Content.fromJson(x))),
      pageable:
          json["pageable"] == null ? null : Pageable.fromJson(json["pageable"]),
      last: json["last"],
      totalElements: json["totalElements"],
      totalPages: json["totalPages"],
      size: json["size"],
      number: json["number"],
      sort: json["sort"] is List
          ? List<Sort>.from(json["sort"]!.map((x) => Sort.fromJson(x)))
          : [],
      first: json["first"],
      numberOfElements: json["numberOfElements"],
      empty: json["empty"],
    );
  }
}

class Content {
  Content({
    required this.id,
    required this.b2bUnitId,
    required this.cartId,
    required this.couponCode,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    required this.deliveryPartnerId,
    required this.deliveryCharge,
    required this.platformFee,
    required this.subTotal,
    required this.totalDiscount,
    required this.totalTax,
    required this.totalPrice,
    required this.createdDate,
    required this.updatedDate,
    required this.version,
    required this.fulfillmentAgent,
    required this.lineItems,
    required this.shippingAddress,
    required this.billingAddress,
    required this.store,
    required this.user,
  });

  final String? id;
  final String? b2bUnitId;
  final String? cartId;
  final String? couponCode;
  final String? orderType;
  final String? status;
  final String? paymentStatus;
  final String? deliveryPartnerId;
  final double? deliveryCharge;
  final double? platformFee;
  final double? subTotal;
  final double? totalDiscount;
  final double? totalTax;
  final double? totalPrice;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final num? version;
  final FulfillmentAgent? fulfillmentAgent;
  final List<LineItem> lineItems;
  final OrderAddress? shippingAddress;
  final BillingAddress? billingAddress;
  final OrderStore? store;
  final OrderUser? user;

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json["id"],
      b2bUnitId: json["b2bUnitId"],
      cartId: json["cartId"],
      couponCode: json["couponCode"],
      orderType: json["orderType"],
      status: json["status"],
      paymentStatus: json["paymentStatus"],
      deliveryPartnerId: json["deliveryPartnerId"],
      deliveryCharge: _toDouble(json["deliveryCharge"]),
      platformFee: _toDouble(json["platformFee"]),
      subTotal: _toDouble(json["subTotal"]),
      totalDiscount: _toDouble(json["totalDiscount"]),
      totalTax: _toDouble(json["totalTax"]),
      totalPrice: _toDouble(json["totalPrice"]),
      createdDate: DateTime.tryParse(json["createdDate"] ?? ""),
      updatedDate: DateTime.tryParse(json["updatedDate"] ?? ""),
      version: json["version"],
      fulfillmentAgent: json["fulfillmentAgent"] == null
          ? null
          : FulfillmentAgent.fromJson(json["fulfillmentAgent"]),
      lineItems: json["lineItems"] == null
          ? []
          : List<LineItem>.from(
              json["lineItems"]!.map((x) => LineItem.fromJson(x))),
      shippingAddress: json["shippingAddressId"] is Map<String, dynamic>
          ? OrderAddress.fromJson(json["shippingAddressId"])
          : null,
      billingAddress: json["billingAddressId"] is Map<String, dynamic>
          ? BillingAddress.fromJson(json["billingAddressId"])
          : null,
      store: json["storeId"] is Map<String, dynamic>
          ? OrderStore.fromJson(json["storeId"])
          : null,
      user: json["userId"] is Map<String, dynamic>
          ? OrderUser.fromJson(json["userId"])
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Backwards-compatible getters used across the dashboard widgets.
  // ---------------------------------------------------------------------------

  /// Order identifier (UUID). Kept as `orderNumber` for existing UI code.
  String? get orderNumber => id;

  /// Single order status now drives both the order and delivery views.
  String? get orderStatus => status;
  String? get deliveryStatus => status;

  /// Grand total shown on the card.
  double? get totalAmount => totalPrice;

  /// Customer's display name (from the `userId` block).
  String? get customerName {
    final n = user?.name?.trim();
    if (n != null && n.isNotEmpty) return n;
    final local = user?.email?.split('@').first.trim();
    return (local != null && local.isNotEmpty) ? local : null;
  }

  /// Best-effort customer contact number.
  String? get mobileNumber =>
      shippingAddress?.mobileNumber ??
      billingAddress?.mobileNumber ??
      _phoneFromEmail(user?.email);

  /// Pickup location (store).
  BusinessAddress? get businessAddress => store == null
      ? null
      : BusinessAddress(
          addressLine1: (store!.address != null && store!.address!.isNotEmpty)
              ? store!.address
              : store!.storeName,
          latitude: store!.latitude,
          longitude: store!.longitude,
        );

  /// Drop location (customer shipping address).
  UserAddress? get userAddress => shippingAddress == null
      ? null
      : UserAddress(addressLine1: shippingAddress!.address);
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _phoneFromEmail(String? email) {
  if (email == null) return null;
  final local = email.split("@").first;
  final digits = RegExp(r'^\d{10,}$');
  return digits.hasMatch(local) ? local : null;
}

class FulfillmentAgent {
  FulfillmentAgent({
    required this.agentId,
    required this.agentType,
    required this.b2bUnitId,
    required this.displayName,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.status,
    required this.userId,
    required this.vehicleType,
    required this.vehicleRegistration,
  });

  final String? agentId;
  final String? agentType;
  final String? b2bUnitId;
  final String? displayName;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? status;
  final String? userId;
  final String? vehicleType;
  final String? vehicleRegistration;

  String get fullName =>
      [firstName, lastName].where((e) => e != null && e.isNotEmpty).join(" ");

  factory FulfillmentAgent.fromJson(Map<String, dynamic> json) {
    return FulfillmentAgent(
      agentId: json["agentId"],
      agentType: json["agentType"],
      b2bUnitId: json["b2bUnitId"],
      displayName: json["displayName"],
      email: json["email"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      mobileNumber: json["mobileNumber"],
      status: json["status"],
      userId: json["userId"],
      vehicleType: json["vehicleType"],
      vehicleRegistration: json["vehicleRegistration"],
    );
  }
}

class LineItem {
  LineItem({
    required this.id,
    required this.productCode,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.discountPrice,
    required this.taxAmount,
    required this.status,
    required this.fulfillmentStatus,
    required this.fulfillmentAgentId,
    required this.agentMessage,
    required this.skuId,
    required this.gift,
    required this.giftMessage,
  });

  final String? id;
  final String? productCode;
  final String? productId;
  final String? productName;
  final num? quantity;
  final double? unitPrice;
  final double? totalPrice;
  final double? discountPrice;
  final double? taxAmount;
  final String? status;
  final String? fulfillmentStatus;
  final String? fulfillmentAgentId;
  final String? agentMessage;
  final String? skuId;
  final bool? gift;
  final String? giftMessage;

  factory LineItem.fromJson(Map<String, dynamic> json) {
    return LineItem(
      id: json["id"],
      productCode: json["productCode"],
      productId: json["productId"],
      productName: json["productName"],
      quantity: json["quantity"],
      unitPrice: _toDouble(json["unitPrice"]),
      totalPrice: _toDouble(json["totalPrice"]),
      discountPrice: _toDouble(json["discountPrice"]),
      taxAmount: _toDouble(json["taxAmount"]),
      status: json["status"],
      fulfillmentStatus: json["fulfillmentStatus"],
      fulfillmentAgentId: json["fulfillmentAgentId"],
      agentMessage: json["agentMessage"],
      skuId: json["skuId"],
      gift: json["gift"],
      giftMessage: json["giftMessage"],
    );
  }
}

class OrderAddress {
  OrderAddress({
    required this.id,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.mobileNumber,
  });

  final String? id;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? mobileNumber;

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      id: json["id"],
      address: json["address"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      postalCode: json["postalCode"],
      mobileNumber: json["mobileNumber"],
    );
  }
}

class BillingAddress {
  BillingAddress({
    required this.id,
    required this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.mobileNumber,
  });

  final String? id;
  final String? line1;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? mobileNumber;

  factory BillingAddress.fromJson(Map<String, dynamic> json) {
    return BillingAddress(
      id: json["id"],
      line1: json["line1"],
      city: json["city"],
      state: json["state"],
      postalCode: json["postalCode"],
      mobileNumber: json["mobileNumber"],
    );
  }
}

class OrderStore {
  OrderStore({
    required this.id,
    required this.address,
    required this.storeName,
    required this.latitude,
    required this.longitude,
  });

  final String? id;
  final String? address;
  final String? storeName;
  final double? latitude;
  final double? longitude;

  factory OrderStore.fromJson(Map<String, dynamic> json) {
    return OrderStore(
      id: json["id"],
      address: json["address"],
      storeName: json["storeName"],
      latitude: _toDouble(json["latitude"]),
      longitude: _toDouble(json["longitude"]),
    );
  }
}

class OrderUser {
  OrderUser({
    required this.id,
    required this.email,
    required this.name,
  });

  final String? id;
  final String? email;
  final String? name;

  factory OrderUser.fromJson(Map<String, dynamic> json) {
    return OrderUser(
      id: json["id"],
      email: json["email"],
      name: json["name"],
    );
  }
}

/// Lightweight address shape retained for the dashboard widgets.
class BusinessAddress {
  BusinessAddress({
    this.addressLine1,
    this.latitude,
    this.longitude,
  });

  final String? addressLine1;
  final double? latitude;
  final double? longitude;
}

/// Lightweight address shape retained for the dashboard widgets.
class UserAddress {
  UserAddress({this.addressLine1});

  final String? addressLine1;
}

class Pageable {
  Pageable({
    required this.sort,
    required this.pageNumber,
    required this.pageSize,
    required this.offset,
    required this.paged,
    required this.unpaged,
  });

  final List<Sort> sort;
  final num? pageNumber;
  final num? pageSize;
  final num? offset;
  final bool? paged;
  final bool? unpaged;

  factory Pageable.fromJson(Map<String, dynamic> json) {
    return Pageable(
      sort: json["sort"] is List
          ? List<Sort>.from(json["sort"]!.map((x) => Sort.fromJson(x)))
          : [],
      pageNumber: json["pageNumber"],
      pageSize: json["pageSize"],
      offset: json["offset"],
      paged: json["paged"],
      unpaged: json["unpaged"],
    );
  }
}

class Sort {
  Sort({
    required this.direction,
    required this.property,
    required this.ignoreCase,
    required this.nullHandling,
    required this.ascending,
    required this.descending,
  });

  final String? direction;
  final String? property;
  final bool? ignoreCase;
  final String? nullHandling;
  final bool? ascending;
  final bool? descending;

  factory Sort.fromJson(Map<String, dynamic> json) {
    return Sort(
      direction: json["direction"],
      property: json["property"],
      ignoreCase: json["ignoreCase"],
      nullHandling: json["nullHandling"],
      ascending: json["ascending"],
      descending: json["descending"],
    );
  }
}
