import 'package:http_gen_method/src/http1_client.dart' as pl;
import 'package:http_gen_method/src/parameter.dart';

class MyClient extends pl.HttpClientBase {
  MyClient() : super();
  @override
  int checkResult(RespData<dynamic> a, String url, Map<String, String> headers) {
    return 0;
  }
}
MyClient client = MyClient();