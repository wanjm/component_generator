import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

import 'parameter.dart';

var boundary = "hellothisisplasocontentdososos";

class MultiPartParam extends RequestAbleParameter {
  @override
  Future<ReqInfo> getReqInfo() async {
    List<int> resultContent = <int>[];
    ReqInfo result = ReqInfo(
      contentType: "multipart/form-data; boundary=$boundary",
      content: resultContent,
    );
    for (var contentItem in contents.entries) {
      var key = contentItem.key;
      var value = contentItem.value;
      if (value is File) {
        var fileName = basename(value.path);
        var data = '--$boundary\r\n'
            'Content-Disposition:form-data;name="$key";filename="$fileName"\r\n'
            'Content-Type:application/octet-stream\r\n\r\n';
        var content = await value.readAsBytes();
        resultContent
          ..addAll(Utf8Encoder().convert(data))
          ..addAll(content)
          ..addAll("\r\n".codeUnits);
      } else {
        var data = '--$boundary\r\n'
            'Content-Disposition: form-data; name="$key";\r\n\r\n'
            '$value\r\n';
        resultContent.addAll(Utf8Encoder().convert(data));
      }
    }
    //理论上此处要utf8encode;但是结果相同;
    resultContent.addAll("--$boundary--".codeUnits);
    return result;
  }

  Map<String, dynamic> contents = {};
  void addValue(String name, dynamic value) {
    contents[name] = value;
  }
}
