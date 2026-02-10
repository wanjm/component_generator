// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// FetchDataGenerator
// **************************************************************************

import 'package:http_method/http_method.dart';
import 'pagination_controller.dart';
import 'schema.gen.dart';
import 'network.dart';

class NetworkFetch {
  static Future<List<UserInfo>> listUser(
      PaginationController<LoginParams> controller) async {
    final baseParam = controller.param;
    baseParam.pageNum = controller.pageNum;
    baseParam.pageSize = controller.pageSize;

    final resp = await networkService.listUser(baseParam);

    if (resp.code == RespCode.SUCCESS && resp.obj != null) {
      final obj = resp.obj!;
      controller.setTotalCount(obj.total);
      return obj.list;
    } else {
      throw Exception(resp.msg ?? "Failed to load data (code: \${resp.code})");
    }
  }
}
