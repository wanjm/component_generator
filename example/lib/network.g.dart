// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// Generator: NetworkBuilder
// **************************************************************************

class NetworkApi extends BaseMethod implements Network {
  NetworkApi({required super.client});

  @override
  Future<RespData<dynamic>> login(LoginParams data) => getData(
    data: data,

    url: "/user/login",

    encodeDataFunction: (RespData resp) {
      resp.obj = resp.res;
    },
  );

  @override
  Future<RespData<ListUserResp?>> listUser(LoginParams data) => getData(
    data: data,

    url: "/user/list",
    buffer: bufferMap["/user/list"] as ClassBuffer<int, ListUserResp>?,

    encodeDataFunction: (RespData resp) {
      resp.obj = ListUserResp.fromJson(resp.res);
    },
  );

  Future<List<UserInfo>> listUserFetch(
    IPaginationController<LoginParams> controller,
  ) async {
    final baseParam = controller.param;
    baseParam.pageNum = controller.pageNum;
    baseParam.pageSize = controller.pageSize;

    final resp = await listUser(baseParam);

    if (resp.code == RespCode.SUCCESS && resp.obj != null) {
      final obj = resp.obj!;
      controller.setTotalCount(obj.total);
      return obj.list;
    } else {
      throw Exception(resp.msg ?? "Failed to load data (code: ${resp.code})");
    }
  }
}

var networkApi = NetworkApi(client: client);
