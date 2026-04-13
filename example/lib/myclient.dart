import 'package:component_set/http1_client.dart' as pl;
import 'package:component_set/component_set.dart';

class MyClient extends pl.HttpClientBase {
  MyClient() : super();
  @override
  int checkResult(RespData<dynamic> a, String url, Map<String, String> headers) {
    return 0;
  }
}
MyClient client = MyClient();

var bufferMap = <String, ClassBuffer<dynamic, dynamic>>{};
