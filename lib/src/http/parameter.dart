import 'dart:convert';
import 'dart:typed_data';

import 'function.dart';

const String JSONTYPE = "application/json; charset=utf-8";
const String URLENCODED = "application/x-www-form-urlencoded; charset=utf-8";

class ReqInfo {
  String contentType;
  dynamic get content => _content;
  final dynamic _content;
  List<String>? urlParameters;
  ReqInfo({this.contentType="", dynamic content = "", this.urlParameters})
      : assert(content is String || content is List<int>),
        _content = content;
}

class JsonReqInfo extends ReqInfo {
  JsonReqInfo({
    String contentType="",
    Map<String, dynamic>? content,
    List<String>? urlParameters,
  }) : super(
          contentType: contentType,
          urlParameters: urlParameters,
          content: json.encode(content),
        );
}

abstract class RequestAbleParameter {
  Future<ReqInfo> getReqInfo();
}

abstract class Parameter<KT> {
  KT? getKey();
}

abstract class JSONParameter {
  Map<String, dynamic> toJson();
}

mixin JSONParameterMixin implements JSONParameter, RequestAbleParameter {
  List<String>? urlParameters;
  @override
  Future<ReqInfo> getReqInfo() {
    var info = ReqInfo(
      contentType: JSONTYPE,
      content: json.encode(toJson()),
      urlParameters: urlParameters,
    );
    return Future.value(info);
  }
}

mixin UrlEncodedParameterMixin implements JSONParameter, RequestAbleParameter {
  List<String>? urlParameters;
  @override
  Future<ReqInfo> getReqInfo() {
    var info = ReqInfo(
      contentType: URLENCODED,
      content: makeQuery(toJson()),
      urlParameters: urlParameters,
    );
    return Future.value(info);
  }
}
mixin UrlEncodedStringParameterMixin implements JSONParameter, RequestAbleParameter {
  @override
  Future<ReqInfo> getReqInfo() {
    var info = ReqInfo(contentType: URLENCODED, content: makeQuery(toJson()));
    return Future.value(info);
  }
}

abstract class IdParameter<T> extends Parameter {
  T? id;
  IdParameter({this.id});
  @override
  T? getKey() {
    return id;
  }
}

abstract class SIdParameter extends IdParameter<String> {}

class RSList<T> {
  List<T>? rs;
}

class PagedResult<T> extends RSList {
  int? total;
  PagedResult({this.total});
  Map<String, dynamic> toJson() => <String, dynamic>{'total': total, 'rs': rs};
  factory PagedResult.fromJson(Map<String, dynamic> json) {
    return PagedResult(total: json['total'] as int?);
  }
}

class Response {
  String? contentType;
  Uint8List? bodyBytes;
  int? status;
  String? body;
  Map<String, String>? headers;
  Response({this.contentType, this.body, this.bodyBytes, this.status, this.headers});
}

class RespCode {
  //0成功,>0服务器返回错误; <0 , 客户端自身错误; 目前仅有网络错误, 将来如果出现需要处理客户端代码错误, 需要分段;不要交叉;
  static const int FORMAT_ERROR = -1; //格式错误
  static const int NETWORK_ERROR = -2; //网络错误
  static const int TIMEOUT = -3; //废弃 实际超时时，返回的response为空；
  static const int ABORT = -4; //废弃
  static const int HTTPERROR = -5; //HTTP错误
  static const int SUCCESS = 0; //请求成功
  static const int SERVER_INTERNAL_ERROR = 1; //服务器内部错误
  static const int ACCESS_TOKEN_ERROR = 2; //token错误
  static const int API_NOT_SUPPORT = 3; //接口不支持
  static const int INPUT_DATA_ERROR = 4; //输入参数错误
  static const int NO_RECORD_FOUND = 5; //数据不存在
  static const int RECORD_ALREADY_EXIST = 6; //数据已存在
  static const int CLIENT_VERSION_OLD = 9; //客户版本太老
}

class RespData<PlasoObject> {
  int code;
  PlasoObject? obj;
  dynamic res; //obj对应的haspMap; 这两个变量注意内存释放; 可能是 object，也可能是list；
  dynamic raw; //记录原始内容. json记录的是所有的返回的json; 否则是response;只有response时，才可以访问body；
  String? msg;
  String? reqId;
  int? expire;
  RespData({required this.code, this.res, int? expireDelta, this.msg, this.raw, this.expire, this.reqId}) {
    if (expireDelta != null) {
      expire = expireDelta * 1000 + DateTime.now().millisecondsSinceEpoch;
    } else if (expire != null) {
      expire = expire! * 1000;
    }
  }

  factory RespData.fromJson(Map<String, dynamic> json) {
    return RespData(
      code: json['code'],
      res: json['obj'],
      expireDelta: json['expireDelta'],
      expire: json['expire'],
      msg: json['msg'] ?? json['errMsg'],
      reqId: json['reqId'],
      raw: json,
    );
  }
  factory RespData.copy(RespData data) {
    return RespData(code: data.code, expire: data.expire);
  }
  factory RespData.raw(Response raw) {
    RespData<PlasoObject> a = RespData(
      code: 0,
      raw: raw,
    );
    return a;
  }
}
