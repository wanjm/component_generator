import 'dart:async';
import 'dart:io';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';
import 'package:http_method/src/generator/annotations.dart';

const String _myClientTemplate = """import 'package:http_method/http1_client.dart' as pl;
import 'package:http_method/http_method.dart';

class MyClient extends pl.HttpClientBase {
  MyClient() : super();
  @override
  int checkResult(RespData<dynamic> a, String url, Map<String, String> headers) {
    return 0;
  }
}
MyClient client = MyClient();

var bufferMap = <String, ClassBuffer<dynamic, dynamic>>{};
""";

const String _pcTemplate = """import 'package:flutter/foundation.dart';

class PaginationController<T> extends ChangeNotifier {
  int _pageNum;
  int _pageSize;
  T _param;
  int? _totalCount;
  
  // Separate notifier for count changes
  final ValueNotifier<int?> _countNotifier = ValueNotifier<int?>(null);

  PaginationController({
    int initialPageNo = 0,
    int initialPageSize = 10,
    required T initialParam,
  })  : _pageNum = initialPageNo,
        _pageSize = initialPageSize,
        _param = initialParam;

  // Getters
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  T get param => _param;
  int? get totalCount => _totalCount;
  
  // Getter for count notifier (for listening to count changes)
  ValueNotifier<int?> get countNotifier => _countNotifier;

  // Calculate total pages (pageCount)
  int? get pageCount {
    if (_totalCount == null) return null;
    return (_totalCount! / _pageSize).ceil();
  }
  
  // Alias for backward compatibility
  int? get totalPages => pageCount;

  // Check if can go to next/previous page
  bool get canGoNext {
    if (_totalCount == null || pageCount == null) return false;
    return _pageNum < pageCount! - 1;
  }

  bool get canGoPrevious => _pageNum > 0;

  // Set total count (called by content widget after fetching data)
  void setTotalCount(int total) {
    if (_totalCount != total) {
      _totalCount = total;
      // Notify count notifier
      _countNotifier.value = total;
      // Also notify main listeners (for pageNo/pageSize changes)
      notifyListeners();
    }
  }

  // Set page number
  void setPageNo(int pageNo) {
    if (_pageNum != pageNo && pageNo >= 0) {
      _pageNum = pageNo;
      notifyListeners();
    }
  }

  // Set page size
  void setPageSize(int pageSize) {
    if (_pageSize != pageSize && pageSize > 0) {
      _pageSize = pageSize;
      // Reset to first page when page size changes
      _pageNum = 0;
      notifyListeners();
    }
  }

  // Navigation methods
  void nextPage() {
    if (canGoNext) {
      setPageNo(_pageNum + 1);
    }
  }

  void previousPage() {
    if (canGoPrevious) {
      setPageNo(_pageNum - 1);
    }
  }

  void goToPage(int page) {
    if (page >= 0 && (totalPages == null || page < totalPages!)) {
      setPageNo(page);
    }
  }

  // Reset to first page
  void reset() {
    setPageNo(0);
  }

  // Trigger refresh (useful when param changes externally)
  // This notifies listeners that they should refresh data
  void triggerRefresh() {
    _pageNum = 0; // Reset to first page
    _totalCount = null; // Clear total count
    _countNotifier.value = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countNotifier.dispose();
    super.dispose();
  }
}
""";

const int _typeList = 1;

/// 网络接口生成器
class NetworkBuilder extends GeneratorForAnnotation<DataInterface> {
  // ignore: unused_field
  final _formatter =
      DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

  static final Set<String> _myClientChecked = <String>{};

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) async {
    if (element is! ClassElement) {
      return "";
    }

    // 检查并复制 myclient.dart 模板文件（每个包只检查一次）
    final package = buildStep.inputId.package;
    if (!_myClientChecked.contains(package)) {
      _myClientChecked.add(package);
      await _ensureMyClientExists(buildStep, package);
    }

    final cls = element;
    final clsName = "${cls.name}Impl";
    final ifName = cls.name;
    var withMixin = annotation.read("mixins").stringValue;
    if (withMixin.isNotEmpty) {
      withMixin = "with $withMixin";
    }

    final methods = <String>[];

    for (var methodElement in cls.methods) {
      final methodData = _processMethod(methodElement);
      if (methodData != null) {
        methods.add(methodData.implementation);
      }
    }

    final clientValue = annotation.read("client").stringValue;
    final nameValue = annotation.read("name").stringValue;
    final client = clientValue.isNotEmpty ? clientValue : "client";
    final name = nameValue.isNotEmpty ? nameValue : "${cls.name![0].toLowerCase()}${cls.name!.substring(1)}Service";

    return """
class $clsName extends BaseMethod $withMixin implements $ifName {
  $clsName({super.client});

  ${methods.join("\n\n  ")}
}

var ${name}Service = $clsName(client: $client);
""";
  }

  _MethodData? _processMethod(MethodElement f) {

    TypeChecker reqConfigChecker = TypeChecker.typeNamed(ReqConfig);
    final reqConfigAnnotation = reqConfigChecker.firstAnnotationOf(f);
    if (reqConfigAnnotation == null) return null;

    final reader = ConstantReader(reqConfigAnnotation);
    final url = reader.read("url").stringValue;
    final returnType = f.returnType;
    if (returnType is! InterfaceType) return null;
    if (returnType.typeArguments.isEmpty) return null;

    final respType = returnType.typeArguments[0];
    if (respType is! InterfaceType) return null;
    if (respType.typeArguments.isEmpty) return null;

    final innerRespType = respType.typeArguments[0];
    final noDetailData = innerRespType is VoidType|| innerRespType is DynamicType;
    
    String respName="";
    String formatCode;
    
    if (noDetailData) {
      // Handle dynamic type - skip fromJson
      formatCode = "resp.obj = resp.res;";
    } else {
      // Handle non-dynamic types
      if (innerRespType is! InterfaceType) return null;

      final innerRespTypeInterface = innerRespType;
      InterfaceType? realRespType;
      int? resultType;

      if (innerRespTypeInterface.typeArguments.isNotEmpty) {
        if (innerRespTypeInterface.isDartCoreList) {
          realRespType = innerRespTypeInterface.typeArguments[0] as InterfaceType;
          resultType = _typeList;
        // } else {
        //   var superclass = innerRespType.superclass;
        //   while (superclass != null && !superclass.isDartCoreObject) {
        //     if (superclass.getDisplayString(withNullability: false) ==
        //         "RSList<dynamic>") {
        //       realRespType = innerRespType.typeArguments[0] as InterfaceType;
        //       resultType = _typeRsList;
        //       break;
        //     }
        //     superclass = superclass.superclass;
        //   }
        }
      }

      realRespType ??= innerRespTypeInterface;
      respName = realRespType.getDisplayString(withNullability: false);
      
      String format = "";
      if (innerRespTypeInterface.getMethod("formatData") != null) {
        format = "a.formatData();";
      }

      switch (resultType) {
        case _typeList:
          formatCode = """
          resp.obj = (resp.res as List?)?.map((e) {
            var a = $respName.fromJson(e);
            $format
            return a;
          }).toList();""";
          break;
        // case _typeRsList:
        //   formatCode = """
        //     Map<String, dynamic> objs = resp.res;
        //     var b = (objs["rs"] as List?)?.map((e) {
        //       var a = $respName.fromJson(e);
        //       $format
        //       return a;
        //     }).toList();
        //     var a = ${innerRespType.getDisplayString(withNullability: false)}.fromJson(resp.res);
        //     a.rs = b;
        //     resp.obj = a;""";
        //   break;
        default:
          if (format.isEmpty) {
            formatCode = "resp.obj = $respName.fromJson(resp.res);";
          } else {
            formatCode = """
            resp.obj = $respName.fromJson(resp.res);
            var a = resp.obj;
            $format""";
          }
      }
    }

    final reqMethod = reader.peek("method")?.stringValue ?? "POST";
    final keyType = reader.peek("keyType")?.stringValue ?? "";
    final keyTypeString = keyType.isNotEmpty ? keyType : "int";


    final String methodDisplayString = f.toString();
    final List paramsList = (f.type as dynamic).parameters as List;

    final firstParam =
        paramsList.isNotEmpty ? paramsList[0].name : "null";
    final secondParam =
        paramsList.length > 1 ? (paramsList[1]).name : "false";

    final bufferString = noDetailData ? "" : "buffer: bufferMap[\"$url\"] as ClassBuffer<$keyTypeString, $respName>?,";
    final methodString = reqMethod != "POST" ? "method: \"$reqMethod\"," : "";
    final slientString = secondParam != "false" ? "slient: $secondParam," : "";

    final implementation = """
  @override
  $methodDisplayString=> getData(
        data: $firstParam,
        $slientString
        url: "$url",
        $bufferString
        $methodString
        encodeDataFunction: (RespData resp) {
          $formatCode
        },
      );""";

    return _MethodData(implementation);
  }

  /// 确保 myclient.dart 文件存在，如果不存在则从模板复制
  Future<void> _ensureMyClientExists(BuildStep buildStep, String package) async {
    try {
      // 使用文件系统操作：检查目标文件是否存在
      // 获取源文件所在的目录（与 .g.dart 文件相同的目录）
      final sourcePath = buildStep.inputId.path;
      final sourceDir = p.dirname(sourcePath);
      final targetFile = File(p.join(sourceDir, 'myclient.dart'));
      
      // 如果文件已存在，直接返回
      if (await targetFile.exists()) {
        return;
      }

      // 尝试从 buildStep 读取模板文件
      String templateContent = _myClientTemplate;
      // 确保目录存在
      await targetFile.parent.create(recursive: true);
      
      // 复制模板内容到目标文件
      await targetFile.writeAsString(templateContent);
    } catch (e) {
      // 如果文件操作失败，忽略错误
      // 用户需要手动创建 myclient.dart
    }
  }
}

class _MethodData {
  final String implementation;

  _MethodData(this.implementation);
}

/// Builder 工厂方法
Builder networkBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [NetworkBuilder()],
    'network',
  );
}

/// 自动生成 fetchData 的 Builder
class FetchDataGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    final annotatedElements =
        library.annotatedWith(TypeChecker.typeNamed(FetchData));
    if (annotatedElements.isEmpty) return "";

    // 确保 pagination_controller.dart 在同级目录存在
    await _ensurePaginationControllerExists(buildStep);

    final fileName = p.basename(buildStep.inputId.path);
    final buffer = StringBuffer();

    buffer.writeln("import 'package:http_method/http_method.dart';");
    buffer.writeln("import 'pagination_controller.dart';");
    buffer.writeln("import 'schema.gen.dart';");
    buffer.writeln("import '$fileName';");
    buffer.writeln();

    for (var annotatedElement in annotatedElements) {
      final element = annotatedElement.element;
      if (element is! ClassElement) continue;

      final cls = element;
      final fetchMethods = <String>[];

      for (var method in cls.methods) {
        final methodData = _processFetchMethod(method, cls);
        if (methodData != null) {
          fetchMethods.add(methodData);
        }
      }

      if (fetchMethods.isEmpty) continue;

      final fetchClsName = "${cls.name}Fetch";
      buffer.writeln("class $fetchClsName {");
      buffer.writeln("  ${fetchMethods.join("\n\n  ")}");
      buffer.writeln("}");
      buffer.writeln();
    }

    return buffer.toString();
  }

  String? _processFetchMethod(MethodElement f, ClassElement cls) {
    final returnType = f.returnType;
    if (returnType is! InterfaceType) return null;
    if (returnType.typeArguments.isEmpty) return null;

    final respType = returnType.typeArguments[0];
    if (respType is! InterfaceType) return null;
    if (respType.typeArguments.isEmpty) return null;

    final innerRespType = respType.typeArguments[0];
    if (innerRespType is! InterfaceType) return null;

    // 检查 innerRespType 是否包含 list 和 total 字段
    final innerElement = innerRespType.element;

    final listField = innerElement.getField('list');
    final totalField = innerElement.getField('total');

    if (listField == null || totalField == null) return null;

    final listItemType = (listField.type as InterfaceType).typeArguments[0];
    final parameters = (f.type as dynamic).parameters as List;
    final reqType = parameters.isNotEmpty ? parameters[0].type : null;
    if (reqType == null) return null;

    final methodName = f.name;
    
    // 获取 DataInterface 的 name 属性作为 serviceInstanceName
    String serviceInstanceName;
    final dataInterfaceChecker = TypeChecker.typeNamed(DataInterface);
    final dataInterfaceAnnotation = dataInterfaceChecker.firstAnnotationOf(cls);
    if (dataInterfaceAnnotation != null) {
      final reader = ConstantReader(dataInterfaceAnnotation);
      final nameValue = reader.read("name").stringValue;
      if (nameValue.isNotEmpty) {
        serviceInstanceName = nameValue;
      } else {
        serviceInstanceName = "${cls.name![0].toLowerCase()}${cls.name!.substring(1)}Service";
      }
    }else{
      return "";
    }

    return """
  static Future<List<${listItemType.getDisplayString(withNullability: false)}>> $methodName(PaginationController<${reqType.getDisplayString(withNullability: false)}> controller) async {
    final baseParam = controller.param;
    baseParam.pageNum = controller.pageNum;
    baseParam.pageSize = controller.pageSize;

    final resp = await $serviceInstanceName.$methodName(baseParam);

    if (resp.code == RespCode.SUCCESS && resp.obj != null) {
      final obj = resp.obj!;
      controller.setTotalCount(obj.total);
      return obj.list;
    } else {
      throw Exception(resp.msg ?? "Failed to load data (code: \\\${resp.code})");
    }
  }""";
  }

  Future<void> _ensurePaginationControllerExists(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final dir = p.dirname(inputId.path);
    final pcPath = p.join(dir, 'pagination_controller.dart');

    final pcFile = File(p.join(Directory.current.path, pcPath));
    if (!await pcFile.exists()) {
      await pcFile.writeAsString(_pcTemplate);
    }
  }
}

/// FetchBuilder 工厂方法
Builder fetchBuilder(BuilderOptions options) {
  return LibraryBuilder(
    FetchDataGenerator(),
    generatedExtension: '.fetch.dart',
  );
}
