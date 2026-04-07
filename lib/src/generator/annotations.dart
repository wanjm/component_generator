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
  /// Column specs: each entry is either a single field name, or
  /// `"fieldName displayLabel"` (first token = model field and codegen hooks;
  /// the rest is the column header: plain text when [useI18n] is false, or the
  /// key passed to [i18nFunction] when [useI18n] is true). If there is only one
  /// token, that string is used for both field binding and header/i18n key.
  /// Examples:
  /// - `["title", "createTime", "endTime"]`
  /// - `["title course.title", "status course.status"]`
  /// - `["title course.title", "status course.status", "createTime 创建时间", "endTime 结束时间"]`
  final List<String> columns;
  final List<String> skips;
  final Type? formWidget;
  final String? fetchData;
  const TableWidget({
    this.useI18n = false,
    this.i18nFunction = 'tr',
    this.columns = const [],
    this.skips = const [],
    this.formWidget,
    this.fetchData,
  });
}

class TableField {
  final String? label;
  final String? tag;
  final bool ignore;
  const TableField({this.label, this.tag, this.ignore = false});
}
