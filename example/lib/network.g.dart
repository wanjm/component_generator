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
}

var network = NetworkImpl(client: client);
