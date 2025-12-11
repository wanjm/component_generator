import 'http_base.dart';
import 'parameter.dart';

abstract class HttpClientBase extends HttpClient {
  HttpClientBase() : super();
  @override
  set prefix(String prefix) {}
  @override
  Future<Response?>? sendReq(String url, ReqInfo params, String method) {
    return null;
  }
}
