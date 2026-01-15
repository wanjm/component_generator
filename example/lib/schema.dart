import 'package:http_method/http_method.dart';

class LoginParams extends JSONParameter {
  final String loginName;
  final String password;
  final int loginType = 0;

  LoginParams(this.loginName, this.password);

  @override
  Map<String, dynamic> toJson() {
    return {
      "loginName": loginName,
      "password": password,
      "loginType": loginType,
    };
  }
}

class LoginResult {
  LoginResult();

  int total = 0;
  int retry = 0;
  int nextLoginTime = 0;

  LoginResult.fromJson(Map<String, dynamic> json) {

    if (json['total'] != null) {
      total = int.parse(json['total']);
    }
    nextLoginTime = json['nextLoginTime'] != null ? int.parse(json['nextLoginTime']) : 0;
    if (json['retry'] != null) {
      retry = int.parse(json['retry']);
    }
    if (json['nextLoginTime'] != null) {
      nextLoginTime = int.parse(json['nextLoginTime']);
    }
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};

    return data;
  }
}