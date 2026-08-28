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
  ///
  /// Codegen hooks on the annotated mixin (XXX = capitalized field name):
  /// - `bool showXXXCell(BuildContext context)` — omit that column's
  ///   DataColumn and DataCell when this returns false.
  /// - `DataCell genXXXDataCell(BuildContext context, T item)` — custom cell.
  /// - `void onXXXTap(BuildContext context, T item)` — cell tap handler.
  /// Examples:
  /// - `["title", "createTime", "endTime"]`
  /// - `["title course.title", "status course.status"]`
  /// - `["title course.title", "status course.status", "createTime 创建时间", "endTime 结束时间"]`
  final List<String> columns;
  final List<String> skips;

  /// A class annotated with [SearchForm]. Its generated widget is used as the
  /// table's search header.
  final Type? searchForm;

  /// Completely replaces [searchForm] when a hand-written header is needed.
  final Type? formWidget;
  final String? fetchData;
  const TableWidget({
    this.useI18n = false,
    this.i18nFunction = 'tr',
    this.columns = const [],
    this.skips = const [],
    this.searchForm,
    this.formWidget,
    this.fetchData,
  });
}

/// Generates a reusable search widget for [requestType].
///
/// Each [fields] entry uses:
/// `variableName|widgetName|labelName|hintText`.
///
/// Leave `widgetName` empty to use the default widget selected from the
/// request field's type.
class SearchForm {
  final Type requestType;
  final List<String> fields;

  const SearchForm({
    required this.requestType,
    this.fields = const [],
  });
}

class TableField {
  final String? label;
  final String? tag;
  final bool ignore;
  const TableField({this.label, this.tag, this.ignore = false});
}
