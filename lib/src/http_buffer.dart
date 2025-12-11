import 'dart:async';

import 'log.dart' as log;
import 'http_base.dart';
import 'parameter.dart';

class ClassBuffer<KT, VT> {
  Map<KT?, RespData<VT?>>? buffer;
  Map<KT?, Completer<RespData<VT?>>> waitlist = <KT?, Completer<RespData<VT?>>>{};
  KT? getKey(Parameter a) => a.getKey();
  ClassBuffer([this.buffer]) {
    buffer ??= <KT?, RespData<VT?>>{};
  }
  RespData<VT?>? getData(KT? key) {
    RespData? res = buffer![key];
    if (res != null) {
      var time = DateTime.now();
      if (res.expire != null && res.expire! < time.millisecondsSinceEpoch) {
        res = null;
        buffer!.remove(key);
      }
    }
    return res as RespData<VT?>?;
  }

  void addData(KT key, RespData<VT> data) {
    buffer![key] = data;
  }

  void bufferData(RespData<Parameter> data) {
    var key = data.obj!.getKey();
    buffer![key] = data as RespData<VT>;
  }

  Future<RespData<VT?>> check({
    required Parameter data,
    required BaseMethod method,
    required String url,
    required String reqMethod,
    required bool slient,
    required Function(RespData resp) encodeDataFunction,
  }) async {
    var key = getKey(data);
    RespData<VT?>? result = getData(key);
    log.info("HttpBuffer@check url $url, result: $result, key: $key", null);
    if (result == null) {
      Completer<RespData<VT?>>? a = waitlist[key];
      if (a == null) {
        a = Completer<RespData<VT?>>();
        //如果当前data没有缓存，且rightData又不为空，说明当前查找的是pdf是解析好模式的数据。data中数据的cid多_1，应该使用rightData请求正确数据。
        proxyData(
          data: data,
          method: method,
          url: url,
          reqMethod: reqMethod,
          key: key,
          slient: slient,
          encodeDataFunction: encodeDataFunction,
        );
        waitlist[key] = a;
      } else {
        log.debug("return completer for $key", null);
      }
      return a.future;
    }
    return result;
  }

  void proxyData({
    required Parameter data,
    required BaseMethod method,
    required String url,
    required String reqMethod,
    required KT? key,
    required bool slient,
    required Function(RespData resp) encodeDataFunction,
  }) {
    log.info("proxyData@ url: $url , data: $data, key: $key, slient: $slient", null);
    method
        .getData<KT, VT>(
          data: data,
          slient: slient,
          url: url,
          buffer: null,
          encodeDataFunction: encodeDataFunction,
          method: reqMethod,
        )
        .then((oneValue) {
          if (oneValue.code == 0) {
            buffer![key] = oneValue;
          }
          waitlist[key]!.complete(oneValue);
          waitlist.remove(key);
        });
  }
}

class IdBuffer<KT, VT> extends ClassBuffer<KT, VT> {}

abstract class ArrayBuffer<KT, VT> extends ClassBuffer<KT, VT> {
  Timer? timer;
  Completer<RespData<VT>>? a;
  List<Parameter> waitParam = [];

  Map<String, dynamic> getParameter(List<Parameter> ps);
  @override
  void proxyData({
    required Parameter data,
    required BaseMethod method,
    required String url,
    required String reqMethod,
    required KT? key,
    required bool slient,
    required Function(RespData resp) encodeDataFunction,
  }) {
    log.info("proxyData@url: $url, data: $data, key: $key", null);
    if (waitlist.isEmpty) {
      log.debug("wait to more request of type ArrayBuffer", null);
      Timer(Duration(milliseconds: 2), () async {
        log.debug("will get parameter for ArrayBuffer request", null);
        var param = getParameter(waitParam);
        waitParam.clear();
        Map<KT?, Completer<RespData<VT?>>> waitlist1 = waitlist;
        waitlist = <KT?, Completer<RespData<VT?>>>{};
        RespData resp = await method.sendReq(url, param, reqMethod, slient);
        List? res = resp.res;
        if (res != null) {
          for (var it in res) {
            Map<String, dynamic> item = it;
            RespData<VT> one = RespData.copy(resp);
            one.res = item;
            encodeDataFunction(one);
            one.res = null;
            var key = getKey(one.obj as Parameter);
            log.debug("proxyData@key $key", null);
            var a = waitlist1[key];
            if (a == null) {
              if (key is String) {
                var tempkey = key + "_1";
                a = waitlist1[tempkey as KT];
                waitlist1.remove(tempkey);
                buffer![tempkey as KT] = one;
              }
            }
            waitlist1.remove(key);
            buffer![key] = one;
            if (a != null) {
              a.complete(one);
            } else {
              log.debug('$key not found in wait list', null);
            }
          }
        }
        waitlist1.forEach((k, v) {
          v.complete(RespData(code: 5));
        });
      });
    }
    waitParam.add(data);
  }
}

class IdsBuffer<KT, T extends IdParameter> extends ArrayBuffer<KT, T> {
  @override
  Map<String, dynamic> getParameter(List<Parameter> ps) {
    var a = <String, dynamic>{};
    List ids = [];
    for (var idParameter in ps) {
      IdParameter<KT> para = idParameter as IdParameter<KT>;
      ids.add(para.getKey());
    }
    a["ids"] = ids;
    return a;
  }
}

Map<KT, RespData<VT>> initBuffer<KT, VT>() => <KT, RespData<VT>>{};
