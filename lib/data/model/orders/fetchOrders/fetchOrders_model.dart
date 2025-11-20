class FetchOrdersModel {
  FetchOrdersModel({
    required this.message,
    required this.status,
    required this.data,
  });

  final String? message;
  final String? status;
  final Data? data;

  factory FetchOrdersModel.fromJson(Map<String, dynamic> json) {
    return FetchOrdersModel(
      message: json["message"],
      status: json["status"],
      data: json["data"] == null ? null : Data.fromJson(json["data"]),
    );
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
      sort: json["sort"] == null
          ? []
          : List<Sort>.from(json["sort"]!.map((x) => Sort.fromJson(x))),
      first: json["first"],
      numberOfElements: json["numberOfElements"],
      empty: json["empty"],
    );
  }
}

class Content {
  Content({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.username,
    required this.mobileNumber,
    required this.userAddress,
    required this.businessId,
    required this.businessName,
    required this.businessContactNumber,
    required this.shippingAddressId,
    required this.notes,
    required this.timmimgs,
    required this.businessAddress,
    required this.totalAmount,
    required this.totalTaxAmount,
    required this.taxInclusive,
    required this.paymentStatus,
    required this.paymentTransactionId,
    required this.orderStatus,
    required this.deliveryStatus,
    required this.createdDate,
    required this.updatedDate,
    required this.deliveryPartnerId,
    required this.deliveryPartnerName,
    required this.deliveryPartnerMobileNumber,
    required this.selfOrder,
    required this.orderItems,
  });

  final num? id;
  final String? orderNumber;
  final num? userId;
  final String? username;
  final String? mobileNumber;
  final UserAddress? userAddress;
  final num? businessId;
  final String? businessName;
  final dynamic businessContactNumber;
  final num? shippingAddressId;
  final String? notes;
  final String? timmimgs;
  final BusinessAddress? businessAddress;
  final double? totalAmount;
  final double? totalTaxAmount;
  final bool? taxInclusive;
  final String? paymentStatus;
  final String? paymentTransactionId;
  final String? orderStatus;
  final String? deliveryStatus;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerMobileNumber;
  final bool? selfOrder;
  final List<OrderItem> orderItems;

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      id: json["id"],
      orderNumber: json["orderNumber"],
      userId: json["userId"],
      username: json["username"],
      mobileNumber: json["mobileNumber"],
      userAddress: json["userAddress"] == null
          ? null
          : UserAddress.fromJson(json["userAddress"]),
      businessId: json["businessId"],
      businessName: json["businessName"],
      businessContactNumber: json["businessContactNumber"],
      shippingAddressId: json["shippingAddressId"],
      notes: json["notes"],
      timmimgs: json["timmimgs"],
      businessAddress: json["businessAddress"] == null
          ? null
          : BusinessAddress.fromJson(json["businessAddress"]),
      totalAmount: json["totalAmount"],
      totalTaxAmount: json["totalTaxAmount"],
      taxInclusive: json["taxInclusive"],
      paymentStatus: json["paymentStatus"],
      paymentTransactionId: json["paymentTransactionId"],
      orderStatus: json["orderStatus"],
      deliveryStatus: json["deliveryStatus"],
      createdDate: DateTime.tryParse(json["createdDate"] ?? ""),
      updatedDate: DateTime.tryParse(json["updatedDate"] ?? ""),
      deliveryPartnerId: json["deliveryPartnerId"],
      deliveryPartnerName: json["deliveryPartnerName"],
      deliveryPartnerMobileNumber: json["deliveryPartnerMobileNumber"],
      selfOrder: json["selfOrder"],
      orderItems: json["orderItems"] == null
          ? []
          : List<OrderItem>.from(
              json["orderItems"]!.map((x) => OrderItem.fromJson(x))),
    );
  }
}

class BusinessAddress {
  BusinessAddress({
    required this.id,
    required this.addressLine1,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.postalCode,
  });

  final num? id;
  final String? addressLine1;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? postalCode;

  factory BusinessAddress.fromJson(Map<String, dynamic> json) {
    return BusinessAddress(
      id: json["id"],
      addressLine1: json["addressLine1"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      postalCode: json["postalCode"],
    );
  }
}

class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.entryNumber,
    required this.productName,
    required this.media,
    required this.taxAmount,
    required this.taxPercentage,
    required this.totalAmount,
    required this.taxIgnored,
  });

  final num? id;
  final num? productId;
  final num? quantity;
  final num? price;
  final num? entryNumber;
  final String? productName;
  final List<Media> media;
  final double? taxAmount;
  final num? taxPercentage;
  final double? totalAmount;
  final bool? taxIgnored;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json["id"],
      productId: json["productId"],
      quantity: json["quantity"],
      price: json["price"],
      entryNumber: json["entryNumber"],
      productName: json["productName"],
      media: json["media"] == null
          ? []
          : List<Media>.from(json["media"]!.map((x) => Media.fromJson(x))),
      taxAmount: json["taxAmount"],
      taxPercentage: json["taxPercentage"],
      totalAmount: json["totalAmount"],
      taxIgnored: json["taxIgnored"],
    );
  }
}

class Media {
  Media({
    required this.mediaType,
    required this.url,
  });

  final String? mediaType;
  final String? url;

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      mediaType: json["mediaType"],
      url: json["url"],
    );
  }
}

class UserAddress {
  UserAddress({
    required this.id,
    required this.addressLine1,
    required this.addressLine2,
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.postalCode,
    required this.userId,
    required this.isDefault,
  });

  final num? id;
  final String? addressLine1;
  final String? addressLine2;
  final String? street;
  final String? city;
  final String? state;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? postalCode;
  final num? userId;
  final bool? isDefault;

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json["id"],
      addressLine1: json["addressLine1"],
      addressLine2: json["addressLine2"],
      street: json["street"],
      city: json["city"],
      state: json["state"],
      country: json["country"],
      latitude: json["latitude"],
      longitude: json["longitude"],
      postalCode: json["postalCode"],
      userId: json["userId"],
      isDefault: json["isDefault"],
    );
  }
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
      sort: json["sort"] == null
          ? []
          : List<Sort>.from(json["sort"]!.map((x) => Sort.fromJson(x))),
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
