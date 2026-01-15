import 'package:http_method/http_method.dart';
import 'schema.dart';
import 'myclient.dart';
part 'network.g.dart';

@DataInterface("network", "client.client")
abstract class Network {
  @ReqConfig("/user/login")
  Future<RespData<LoginResult?>> login(LoginParams data);
}