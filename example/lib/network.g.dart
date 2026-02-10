// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// Generator: NetworkBuilder
// **************************************************************************

class NetworkImpl extends BaseMethod implements Network {
  NetworkImpl({super.client});

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
}

var networkService = NetworkImpl(client: client);
