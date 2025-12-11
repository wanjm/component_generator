part of 'network.dart';
class NetworkImpl extends BaseMethod implements Network {
  NetworkImpl({required MyClient client}) : super(client: client);
   void encodeLoginData( RespData resp) {
        resp.obj = LoginResult.fromJson(resp.res);
  }
  @override
  Future<RespData<LoginResult?>> login(LoginParams data) => getData(data: data, 
  slient: false, url: "/user/login", buffer: null, method: "POST", 
  encodeDataFunction: encodeLoginData,
  );
}

var network = NetworkImpl(client: client);