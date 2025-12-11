class DataInterface {
  final String name;
  final String client;
  final String mixins;
  const DataInterface(this.name, this.client, [this.mixins = ""]);
}

class ReqConfig {
  final String url;
  final String method;
  final String buffer;
  const ReqConfig(this.url, {this.method = "POST", this.buffer = "null"});
}
