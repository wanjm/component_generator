import 'package:http_gen_method/http_gen_method.dart';
import 'schema.dart';
import 'myclient.dart';
part 'network.g.dart';
// @DataInterface("network", "client.client")
abstract class Network {
  //  @ReqConfig("/manage/nc/login/doLoginForClient")
  Future<RespData<LoginResult?>> login(LoginParams data);
}