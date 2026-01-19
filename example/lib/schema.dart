import 'package:http_method/http_method.dart';

class LoginParams extends JSONParameter {
  String loginName;
  String password;
  int loginType = 0;
  int pageNum = 0;
  int pageSize = 0;

  LoginParams(this.loginName, this.password);

  @override
  Map<String, dynamic> toJson() {
    return {
      "loginName": loginName,
      "password": password,
      "loginType": loginType,
      "pageNum": pageNum,
      "pageSize": pageSize,
    };
  }
}

class UserInfo {
  String name;
  UserInfo({this.name = ""});
  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(name: json['name'] ?? "");
}

class ListUserResp {
  int total;
  List<UserInfo> list;
  ListUserResp({this.total = 0, this.list = const []});
  factory ListUserResp.fromJson(Map<String, dynamic> json) => ListUserResp(
        total: json['total'] ?? 0,
        list: (json['list'] as List? ?? []).map((e) => UserInfo.fromJson(e)).toList(),
      );
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