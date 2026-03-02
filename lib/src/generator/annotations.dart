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

class TableWidget {
  final bool useI18n;
  final String i18nFunction;
  final List<String> columns;
  final List<String> skips;
  const TableWidget({
    this.useI18n = false,
    this.i18nFunction = 'tr',
    this.columns = const [],
    this.skips = const [],
  });
}

class TableField {
  final String? label;
  final String? tag;
  final bool ignore;
  const TableField({this.label, this.tag, this.ignore = false});
}
