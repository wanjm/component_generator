  import 'lib/schema.dart';
import 'lib/network.dart';
import 'lib/myclient.dart';

void main() async{
  client.prefix = "http://localhost:8080";
  var result = await network.login(LoginParams("admin", "123456"));
  print(result.obj);
}
