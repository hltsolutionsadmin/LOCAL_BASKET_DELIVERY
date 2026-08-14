class SignInModel {
  String? accessToken;
  String? refreshToken;
  int? expiresIn;
  String? tokenType;

  SignInModel({this.accessToken, this.refreshToken, this.expiresIn, this.tokenType});

  SignInModel.fromJson(Map<String, dynamic> json) {
    accessToken = json['accessToken'];
    refreshToken = json['refreshToken'];
    expiresIn = json['expiresIn'];
    tokenType = json['tokenType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accessToken'] = accessToken;
    data['refreshToken'] = refreshToken;
    data['expiresIn'] = expiresIn;
    data['tokenType'] = tokenType;
    return data;
  }
}
