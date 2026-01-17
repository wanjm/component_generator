// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network.dart';

// **************************************************************************
// Generator: NetworkBuilder
// **************************************************************************

class NetworkImpl extends BaseMethod implements Network {
  NetworkImpl({super.client});

  @override
  Future<RespData<LoginResult?>> login(LoginParams data) => getData(
        data: data,
        url: "/user/login",
        buffer: bufferMap["/user/login"] as ClassBuffer<int, LoginResult>?,
        encodeDataFunction: (RespData resp) {
          resp.obj = LoginResult.fromJson(resp.res);
        },
      );
}

var network = NetworkImpl(client: client);
