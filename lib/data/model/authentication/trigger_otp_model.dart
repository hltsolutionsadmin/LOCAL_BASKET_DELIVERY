class TriggerOtpModel {
  String? otp;
  String? status;

  TriggerOtpModel({this.otp, this.status});

  TriggerOtpModel.fromJson(Map<String, dynamic> json) {
    otp = json['otp'];
    status = json['status'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['otp'] = otp;
    data['status'] = status;
    return data;
  }
}
