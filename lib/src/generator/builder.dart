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

const int _typeList = 1;
const int _typeRsList = 2;

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
    final name = nameValue.isNotEmpty ? nameValue : (cls.name!.isEmpty ? cls.name! : cls.name![0].toLowerCase() + cls.name!.substring(1));

    return """
class $clsName extends BaseMethod $withMixin implements $ifName {
  $clsName({super.client});

  ${methods.join("\n\n  ")}
}

var $name = $clsName(client: $client);
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
    final isDynamic = innerRespType is DynamicType;
    
    String respName="";
    String formatCode;
    
    if (isDynamic) {
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
      respName = realRespType.getDisplayString();
      
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


    final String methodDisplayString = f.displayString();
    final dynamic parameters = f.formalParameters;
    final List paramsList = (parameters is List) ? parameters : [];

    final firstParam =
        paramsList.isNotEmpty ? paramsList[0].name : "null";
    final secondParam =
        paramsList.length > 1 ? (paramsList[1]).name : "false";

    final bufferString = isDynamic ? "" : "buffer: bufferMap[\"$url\"] as ClassBuffer<$keyTypeString, $respName>?,";
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
      final currentDir = Directory.current.path;
      final targetFile = File(p.join(currentDir, 'lib', 'myclient.dart'));
      
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
