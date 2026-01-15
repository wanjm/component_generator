part of 'network.dart';

class NetworkImpl extends BaseMethod implements Network {
  NetworkImpl({required HttpClient client}) : super(client: client);
  @override
  Future<RespData<LoginResult?>> login(LoginParams data) => getData(
    data: data,
    url: "/user/login",
    encodeDataFunction: (RespData resp) {
      resp.obj = LoginResult.fromJson(resp.res);
    },
  );
}

var network = NetworkImpl(client: client);
