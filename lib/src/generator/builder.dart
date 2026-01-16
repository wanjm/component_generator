import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';
import 'package:http_method/src/generator/annotations.dart';

const int _typeList = 1;
const int _typeRsList = 2;

/// 网络接口生成器
class NetworkBuilder extends GeneratorForAnnotation<DataInterface> {
  // ignore: unused_field
  final _formatter =
      DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

  @override
  FutureOr<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      return "";
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

    final client = annotation.read("client").stringValue;
    final name = annotation.read("name").stringValue;

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
    if (innerRespType is! InterfaceType) return null;

    InterfaceType? realRespType;
    String format = "";
    int? resultType;

    if (innerRespType.typeArguments.isNotEmpty) {
      if (innerRespType.isDartCoreList) {
        realRespType = innerRespType.typeArguments[0] as InterfaceType;
        resultType = _typeList;
      } else {
        var superclass = innerRespType.superclass;
        while (superclass != null && !superclass.isDartCoreObject) {
          if (superclass.getDisplayString(withNullability: false) ==
              "RSList<dynamic>") {
            realRespType = innerRespType.typeArguments[0] as InterfaceType;
            resultType = _typeRsList;
            break;
          }
          superclass = superclass.superclass;
        }
      }
    }

    realRespType ??= innerRespType;

    final respName = realRespType.getDisplayString(withNullability: false);
    if (innerRespType.getMethod("formatData") != null) {
      format = "a.formatData();";
    }

    String formatCode;
    switch (resultType) {
      case _typeList:
        formatCode = """
          resp.obj = (resp.res as List?)?.map((e) {
            var a = $respName.fromJson(e);
            $format
            return a;
          }).toList();""";
        break;
      case _typeRsList:
        formatCode = """
          Map<String, dynamic> objs = resp.res;
          var b = (objs["rs"] as List?)?.map((e) {
            var a = $respName.fromJson(e);
            $format
            return a;
          }).toList();
          var a = ${innerRespType.getDisplayString(withNullability: false)}.fromJson(resp.res);
          a.rs = b;
          resp.obj = a;""";
        break;
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

    final reqMethod = reader.peek("method")?.stringValue ?? "POST";
    final bufferName = reader.peek("buffer")?.stringValue ?? "null";

    final String displayString = (f as dynamic).displayString();
    final paramsStart = displayString.indexOf('(');
    final paramsEnd = displayString.lastIndexOf(')');
    final paramsString = displayString.substring(paramsStart + 1, paramsEnd);

    final dynamic parameters = (f as dynamic).formalParameters;
    final List paramsList = (parameters is List) ? parameters : [];

    final firstParam =
        paramsList.isNotEmpty ? (paramsList[0] as dynamic).name : "null";
    final secondParam =
        paramsList.length > 1 ? (paramsList[1] as dynamic).name : "false";

    final bufferString = bufferName != "null" ? "buffer: $bufferName," : "";
    final methodString = reqMethod != "POST" ? "method: \"$reqMethod\"," : "";
    final slientString = secondParam != "false" ? "slient: $secondParam," : "";

    final implementation = """
  @override
  ${returnType.getDisplayString(withNullability: true)} ${f.name}($paramsString) => getData(
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
