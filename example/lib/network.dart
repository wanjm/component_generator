import 'package:http_method/http_method.dart';
import 'schema.dart';
import 'myclient.dart';
part 'network.g.dart';

@DataInterface()
@FetchData()
abstract class Network {
  @ReqConfig("/user/login")
  Future<RespData> login(LoginParams data);

  @ReqConfig("/user/list")
  Future<RespData<ListUserResp?>> listUser(LoginParams data);
}
