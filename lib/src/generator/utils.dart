import 'package:analyzer/dart/element/type.dart';

/// 通用工具类
class Utils {
  /// 提取泛型类型（如 RespData<T> → T）
  static String extractGenericType(DartType type) {
    if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
      return type.typeArguments.first.getDisplayString();
    }
    throw ArgumentError('类型 $type 不是带泛型的类型（如 RespData<T>）');
  }
}