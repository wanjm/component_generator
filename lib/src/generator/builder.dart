import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:http_method/src/generator/annotations.dart';
import 'utils.dart';

/// 网络接口生成器（对外隐藏，仅内部使用）
class NetworkBuilder extends GeneratorForAnnotation<DataInterface> {
  final _formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    print("come to buld");
    // 1. 校验元素类型（必须是抽象类）
    if (element is! ClassElement || !element.isAbstract) {
      throw InvalidGenerationSourceError(
        '${element.name} 必须是抽象类才能使用 @DataInterface 注解',
        element: element,
      );
    }
    final classElement = element;
    final className = classElement.name;
    final implClassName = '${className}Impl';
    final networkName = annotation.read('name').stringValue;

    // 获取源文件名
    final inputId = buildStep.inputId;
    final sourceFileName = path.basename(inputId.path);

    // 2. 生成所有抽象方法的实现
    final methods = <String>[];
    for (final method in classElement.methods) {
      if (method.isAbstract) {
        methods.add(_generateMethod(method));
      }
    }

    // 3. 拼接完整代码模板
    final code = '''
part of '$sourceFileName';

class $implClassName extends BaseMethod implements $className {
  $implClassName({required MyClient client}) : super(client: client);

  ${methods.join('\n  ')}
}

var $networkName = $implClassName(client: client);
''';

    // 4. 格式化代码并返回
    return _formatter.format(code);
  }

  /// 生成单个方法的实现
  String _generateMethod(MethodElement method) {
    // 查找 @ReqConfig 注解 - metadata 在运行时是可迭代的
    // ElementAnnotation? reqConfigAnnotation;
    final reqConfigAnnotation = method.metadata.annotations.firstWhere(
    final reqConfigChecker = TypeChecker.typeNamed(ReqConfig);
    final reqConfigAnnotation = reqConfigChecker.firstAnnotationOf(method); // as ElementAnnotation?;

    final reader = ConstantReader(reqConfigAnnotation);
    final url = reader.read('url').stringValue;
    // 读取注解的常量值
    // final constantValue = reqConfigAnnotation?.computeConstantValue();
    // if (constantValue == null) {
    //   throw InvalidGenerationSourceError(
    //     '无法读取方法 ${method.name} 的 @ReqConfig 注解值',
    //     element: method,
    //   );
    // }
    // final url = constantValue.getField('url')!.toStringValue() ?? '';

    // 解析方法元信息（返回类型、参数、泛型）
    final returnType = method.returnType.getDisplayString();
    final methodName = method.name;

    // 获取方法参数 - 使用动态访问以兼容不同 analyzer 版本
    final parameters = _getMethodParameters(method);
    if (parameters.isEmpty) {
      throw InvalidGenerationSourceError(
        '方法 ${method.name} 必须包含至少一个参数（data）',
        element: method,
      );
    }
    final param = parameters.first;
    final paramType = param.type.getDisplayString(withNullability: true);
    final paramName = param.name;

    // 提取返回类型的泛型（如 RespData<LoginResult?> → LoginResult?）
    final returnGeneric = Utils.extractGenericType(method.returnType);

    // 生成方法体
    return '''
@override
$returnType $methodName($paramType $paramName) => getData(
  data: $paramName,
  url: "$url",
  encodeDataFunction: (RespData resp) {
    resp.obj = $returnGeneric.fromJson(resp.res);
  },
);''';
  }

  /// 获取方法参数列表
  List<dynamic> _getMethodParameters(MethodElement method) {
    // 在 analyzer 8.x 中，MethodElement 应该直接有 parameters 属性
    // 但由于类型系统可能不识别，使用动态访问
    try {
      // 尝试直接访问 parameters
      final dynamic methodDynamic = method;
      final params = methodDynamic.parameters;
      if (params != null) {
        return List<dynamic>.from(params);
      }
    } catch (_) {
      // 如果直接访问失败，尝试其他方式
    }

    // MethodElement 继承自 ExecutableElement，尝试通过类型转换访问
    final dynamic execElement = method;
    final params = execElement.parameters;
    if (params != null) {
      return List<dynamic>.from(params);
    }

    throw InvalidGenerationSourceError(
      '无法访问方法 ${method.name} 的参数',
      element: method,
    );
  }
}

/// Builder 工厂方法（必须全局可见，供 build.yaml 调用）
Builder networkBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [NetworkBuilder()],
    'network',
  );
}
