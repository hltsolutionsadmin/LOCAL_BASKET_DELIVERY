/// Response of `PUT api/users/me/fcm-token`.
///
/// The endpoint may reply with an empty body (200/204) or a small JSON object,
/// so every field is optional and parsing never throws.
class UpdateFcmTokenModel {
  UpdateFcmTokenModel({
    this.success = true,
    this.message,
    this.fcmToken,
    this.deviceType,
  });

  final bool success;
  final String? message;
  final String? fcmToken;
  final String? deviceType;

  factory UpdateFcmTokenModel.fromJson(dynamic json) {
    if (json is! Map) return UpdateFcmTokenModel();
    return UpdateFcmTokenModel(
      success: json["success"] ?? true,
      message: json["message"],
      fcmToken: json["fcmToken"],
      deviceType: json["deviceType"],
    );
  }
}
