String makeQuery(Map<String, dynamic> dataMap) {
  List<String> pvs = [];
  dataMap.forEach((key, value) {
    pvs.add("$key=${Uri.encodeQueryComponent(value.toString())}");
  });
  return pvs.join("&");
}