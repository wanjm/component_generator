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

class GenWidget {
  final List<String> types;
  final bool useI18n;
  final String i18nFunction;
  final String fetchMethod;
  const GenWidget(this.types,
      {this.useI18n = false, this.i18nFunction = 'tr', this.fetchMethod = ''});
}

class TableField {
  final String? label;
  final String? tag;
  final bool ignore;
  const TableField({this.label, this.tag, this.ignore = false});
}
