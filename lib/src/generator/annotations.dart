class DataInterface {
  final String name;
  final String client;
  final String mixins;
  const DataInterface({this.name = "", this.client = "", this.mixins = ""});
}

class ReqConfig {
  final String url;
  final String method;
  final String keyType;
  const ReqConfig(this.url, {this.method = "POST", this.keyType = ""});
}

class FetchData {
  const FetchData();
}
