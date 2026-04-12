import 'package:http_method/http_method.dart';
import 'package:component_set/paging/pagination_controller.dart';
import 'schema.dart';
import 'myclient.dart';
part 'network.g.dart';

@DataInterface()
abstract class Network {
  @ReqConfig("/user/login")
  Future<RespData> login(LoginParams data);

  @ReqConfig("/user/list")
  Future<RespData<ListUserResp?>> listUser(LoginParams data);
}
