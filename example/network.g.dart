part of 'network.dart';
class NetworkImpl extends BaseMethod implements Network {
  NetworkImpl({required MyClient client}) : super(client: client);
  @override
  RespData encodeData(String url, RespData resp) {
    switch (url) {
      case "/user/login":
        resp.obj = LoginResult.fromJson(resp.res);
        return resp;
      default:
        return resp;
    }
  }
  @override
  Future<RespData<LoginResult?>> login(LoginParams data) => getData(data, false, "/user/login", null, method: "POST");
}

var network = NetworkImpl(client: client);