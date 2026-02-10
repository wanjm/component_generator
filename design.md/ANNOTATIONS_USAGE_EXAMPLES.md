# HTTP Gen Method Annotations Usage Examples

This document provides comprehensive usage examples for all annotations available in the `http_gen_method` package.

## Table of Contents

1. [@DataInterface](#datainterface)
2. [@ReqConfig](#reqconfig)
3. [@TableWidget](#tablewidget)
4. [@TableField](#tablefield)

---

## @DataInterface

The `@DataInterface` annotation marks an abstract class as a network interface. It generates an implementation class with HTTP client methods.

### Parameters

- `name` (String, optional): Custom name for the service instance. Defaults to `{className}Service` (e.g., `NetworkService`).
- `client` (String, optional): Custom client instance name. Defaults to `"client"`.
- `mixins` (String, optional): Mixins to apply to the generated implementation class.

### Basic Usage

```dart
import 'package:http_method/http_method.dart';
import 'schema.dart';
import 'myclient.dart';

part 'network.g.dart';

@DataInterface()
abstract class Network {
  @ReqConfig("/user/login")
  Future<RespData<dynamic>> login(LoginParams data);
}
```

### With Custom Service Name

```dart
@DataInterface(name: "userService")
abstract class UserApi {
  @ReqConfig("/api/users")
  Future<RespData<List<User>>> getUsers();
}
```

### With Custom Client

```dart
@DataInterface(client: "customClient")
abstract class CustomApi {
  @ReqConfig("/api/data")
  Future<RespData<Data>> getData();
}
```

### With Mixins

```dart
@DataInterface(mixins: "LoggingMixin, CachingMixin")
abstract class AdvancedApi {
  @ReqConfig("/api/advanced")
  Future<RespData<Result>> getResult();
}
```

### Generated Output

The annotation generates a file `network.g.dart` with:

```dart
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

var networkService = NetworkImpl(client: client);
```

---

## @ReqConfig

The `@ReqConfig` annotation marks a method in a `@DataInterface` class as an HTTP endpoint. It generates the HTTP request implementation.

### Parameters

- `url` (String, required): The API endpoint URL.
- `method` (String, optional): HTTP method. Defaults to `"POST"`. Can be `"GET"`, `"POST"`, `"PUT"`, `"DELETE"`, etc.
- `keyType` (String, optional): Type for the buffer key. Defaults to `"int"`.

### Basic POST Request

```dart
@DataInterface()
abstract class Network {
  @ReqConfig("/user/login")
  Future<RespData<LoginResult>> login(LoginParams data);
}
```

### GET Request

```dart
@DataInterface()
abstract class Network {
  @ReqConfig("/user/profile", method: "GET")
  Future<RespData<UserProfile>> getUserProfile();
}
```

### With Dynamic Response Type

```dart
@DataInterface()
abstract class Network {
  @ReqConfig("/user/list")
  Future<RespData<ListUserResp?>> listUser(LoginParams data);
}
```

### With Void Response

```dart
@DataInterface()
abstract class Network {
  @ReqConfig("/user/logout")
  Future<RespData<void>> logout();
}
```

### With Custom Key Type

```dart
@DataInterface()
abstract class Network {
  @ReqConfig("/user/data", keyType: "String")
  Future<RespData<UserData>> getUserData(String userId);
}
```

### Using URL Constants

```dart
@DataInterface()
abstract class BillOuterApi {
  static const String getBillUrl = "/api/v1/tk/aiService/bill";
  
  @ReqConfig(getBillUrl)
  Future<RespData<AIBillRes?>> getBill(AIBillReq data);
}
```

### Generated Output

For a method like:
```dart
@ReqConfig("/user/list")
Future<RespData<ListUserResp?>> listUser(LoginParams data);
```

The generator creates:
```dart
@override
Future<RespData<ListUserResp?>> listUser(LoginParams data) => getData(
      data: data,
      url: "/user/list",
      buffer: bufferMap["/user/list"] as ClassBuffer<int, ListUserResp>?,
      encodeDataFunction: (RespData resp) {
        resp.obj = ListUserResp.fromJson(resp.res);
      },
    );
```

---

## Automatic Fetch Method Generation

`@DataInterface` automatically generates pagination-aware fetch methods for methods that return list responses. These methods work with `PaginationController` for list endpoints.

### Requirements

- The class must be annotated with `@DataInterface`
- Methods must return `Future<RespData<ResponseType>>` where `ResponseType` has `list` and `total` fields
- The request parameter should have `pageNum` and `pageSize` fields

### Basic Usage

```dart
@DataInterface()
abstract class Network {
  @ReqConfig("/user/list")
  Future<RespData<ListUserResp?>> listUser(LoginParams data);
}
```

### Response Structure

The response type must have this structure:

```dart
class ListUserResp {
  int total;
  List<UserInfo> list;
  
  ListUserResp({this.total = 0, this.list = const []});
  
  factory ListUserResp.fromJson(Map<String, dynamic> json) => ListUserResp(
    total: json['total'] ?? 0,
    list: (json['list'] as List? ?? []).map((e) => UserInfo.fromJson(e)).toList(),
  );
}
```

### Request Parameter Structure

The request parameter should include pagination fields:

```dart
class LoginParams extends JSONParameter {
  String loginName;
  String password;
  int pageNum = 0;
  int pageSize = 0;
  
  // ... other fields
}
```

### Generated Output

The annotation generates a file `network.fetch.dart` with:

```dart
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
      throw Exception(resp.msg ?? "Failed to load data (code: ${resp.code})");
    }
  }
}
```

### Usage in Widgets

```dart
class _StudentContentWidget extends TableContentWidget<StudentInfo, StudentReq> {
  @override
  Future<List<StudentInfo>> fetchData(PaginationController<StudentReq> controller) {
    return StudentNBizFetch.listStudent(controller);
  }
  
  @override
  Widget buildContent(BuildContext context, List<StudentInfo> data) {
    // Build UI with data
  }
}
```

---

## @TableWidget

The `@TableWidget` annotation generates Flutter widget helper methods for table widgets. It is used on mixin classes that extend `TableContentWidget` to automatically generate table headers and data rows.

### Parameters

- `fetchClass` (Type, required): The fetch class type (e.g., `OrgBizFetch`).
- `fetchMethod` (String, required): The name of the fetch method (e.g., `"listOrg"`).
- `useI18n` (bool, optional): Whether to use internationalization. Defaults to `false`.
- `i18nFunction` (String, optional): Name of the i18n function. Defaults to `"tr"`.

### Basic Usage

```dart
@TableWidget(OrgBiz, "listOrg")
mixin OrgContentMixin on TableContentWidget<OrgInfo, OrgReq> {
  // Optional: Override specific cells
  DataCell gen3DataCell(BuildContext context, OrgInfo item) {
    return DataCell(IconButton(icon: Icon(Icons.edit), onPressed: () {}));
  }
}
```

### With Internationalization

```dart
@TableWidget(OrgBiz, "listOrg", useI18n: true, i18nFunction: 'tr')
mixin OrgContentMixin on TableContentWidget<OrgInfo, OrgReq> {
}
```

### Generated Output

For `@TableWidget`, the generator creates:

```dart
class OrgContentImpl extends TableContentWidget<OrgInfo, OrgReq> with OrgContentMixin {
  const OrgContentImpl({super.key});

  @override
  Future<List<OrgInfo>> fetchData(PaginationController<OrgReq> controller) => OrgBizFetch.listOrg(controller);

  @override
  List<DataColumn> genTableHeader(BuildContext context) {
    return [
      DataColumn(label: const Text('id')),
      DataColumn(label: const Text('shortname')),
      DataColumn(label: const Text('name')),
    ];
  }

  @override
  List<DataCell> genTableData(BuildContext context, OrgInfo item) {
    return [
      DataCell(Center(child: Text(item.id.toString()))),
      DataCell(Text(item.shortname.toString())),
      DataCell(Text(item.name.toString())),
    ];
  }
}
```

### Usage in Flutter Widgets

```dart
PaginatedView<OrgReq>(
  initialParam: OrgReq(),
  child: const OrgContentImpl(),
)
```

---

## @TableField

The `@TableField` annotation customizes how fields are displayed in generated widgets when using `@TableWidget`. It can be applied to individual fields in a class.

### Parameters

- `label` (String?, optional): Custom label text for the column/field.
- `tag` (String?, optional): i18n tag key for internationalization.
- `ignore` (bool, optional): Whether to ignore this field in generated widgets. Defaults to `false`.

### Basic Usage - Custom Label

```dart
class UserInfo extends JSONParameter {
  @TableField(label: 'User ID')
  int id;
  
  @TableField(label: 'Full Name')
  String name;
  
  @TableField(label: 'Email Address')
  String email;
  
  // ... other fields
}

@TableWidget(UserBiz, "listUser")
mixin UserContentMixin on TableContentWidget<UserInfo, UserReq> {
}
```

### With i18n Tags

```dart
class UserInfo extends JSONParameter {
  @TableField(tag: 'user.id')
  int id;
  
  @TableField(tag: 'user.name')
  String name;
  
  @TableField(tag: 'user.email')
  String email;
  
  // ... other fields
}

@TableWidget(UserBiz, "listUser", useI18n: true)
mixin UserContentMixin on TableContentWidget<UserInfo, UserReq> {
}
```

### Ignoring Fields

```dart
class UserInfo extends JSONParameter {
  int id;
  String name;
  
  @TableField(ignore: true)
  String internalSecret; // This field won't appear in generated widgets
  
  // ... other fields
}

@TableWidget(UserBiz, "listUser")
mixin UserContentMixin on TableContentWidget<UserInfo, UserReq> {
}
```

### Combining Options

```dart
class ProductInfo extends JSONParameter {
  @TableField(label: 'Product ID', tag: 'product.id')
  int id;
  
  @TableField(label: 'Product Name')
  String name;
  
  @TableField(ignore: true)
  String internalNotes; // Hidden from widgets
  
  // ... other fields
}

@TableWidget(ProductBiz, "listProduct", useI18n: true)
mixin ProductContentMixin on TableContentWidget<ProductInfo, ProductReq> {
}
```

### Generated Output

For a field with `@TableField(label: 'User ID')`:

```dart
DataColumn(label: const Text('User ID'))
```

For a field with `@TableField(tag: 'user.id')` and `useI18n: true`:

```dart
DataColumn(label: Text(tr('user.id')))
```

---

## Complete Example

Here's a complete example combining multiple annotations:

```dart
import 'package:http_method/http_method.dart';
import 'schema.dart';
import 'myclient.dart';

part 'network.g.dart';

// Define request/response types
class StudentReq extends JSONParameter {
  String keyword;
  int orgId;
  int pageNum = 0;
  int pageSize = 0;
  
  StudentReq({this.keyword = "", this.orgId = 0});
  
  @override
  Map<String, dynamic> toJson() => {
    'keyword': keyword,
    'orgId': orgId,
    'pageNum': pageNum,
    'pageSize': pageSize,
  };
}

class StudentInfo extends JSONParameter {
  int id;
  String name;
  String loginname;
  String mobile;
  String email;
  int orgId;
  
  StudentInfo({
    this.id = 0,
    this.name = "",
    this.loginname = "",
    this.mobile = "",
    this.email = "",
    this.orgId = 0,
  });
  
  factory StudentInfo.fromJson(Map<String, dynamic> json) => StudentInfo(
    id: json['id'] ?? 0,
    name: json['name'] ?? "",
    loginname: json['loginname'] ?? "",
    mobile: json['mobile'] ?? "",
    email: json['email'] ?? "",
    orgId: json['orgId'] ?? 0,
  );
  
  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'loginname': loginname,
    'mobile': mobile,
    'email': email,
    'orgId': orgId,
  };
}

class StudentListResp {
  int total;
  List<StudentInfo> list;
  
  StudentListResp({this.total = 0, this.list = const []});
  
  factory StudentListResp.fromJson(Map<String, dynamic> json) => StudentListResp(
    total: json['total'] ?? 0,
    list: (json['list'] as List? ?? [])
        .map((e) => StudentInfo.fromJson(e))
        .toList(),
  );
}

// Define the network interface
@DataInterface(name: "studentService")
@FetchData()
abstract class StudentNBiz {
  static const String listStudentUrl = "/api/student/list";
  
  @ReqConfig(listStudentUrl)
  Future<RespData<StudentListResp?>> listStudent(StudentReq data);
}

// Define widget-enabled data class
class StudentInfo extends JSONParameter {
  @TableField(label: 'ID')
  int id;
  
  @TableField(label: 'Name', tag: 'student.name')
  String name;
  
  @TableField(label: 'Login Name')
  String loginname;
  
  @TableField(label: 'Mobile')
  String mobile;
  
  @TableField(label: 'Email')
  String email;
  
  @TableField(label: 'Organization ID')
  int orgId;
  
  @TableField(ignore: true)
  String internalNotes; // Hidden from widgets
  
  // ... fromJson, toJson methods
}

@TableWidget(StudentNBiz, "listStudent")
mixin StudentContentMixin on TableContentWidget<StudentInfo, StudentReq> {
}
```

This example demonstrates:
- `@DataInterface` with custom service name (automatically generates fetch methods for list responses)
- `@ReqConfig` for HTTP endpoints
- `@TableWidget` for Flutter widget generation
- `@TableField` for customizing field display

---

## Notes

1. **Build Configuration**: Make sure your `build.yaml` includes the builders:
   ```yaml
   builders:
     http_method:networkBuilder:
       enabled: true
     http_method:fetchBuilder:
       enabled: true
     http_method:widgetBuilder:
       enabled: true
   ```

2. **Required Files**: The generators expect:
   - `myclient.dart` - HTTP client configuration (auto-generated if missing)
   - `pagination_controller.dart` - For `@FetchData` (auto-generated if missing)

3. **Code Generation**: Run `dart run build_runner build` to generate code.

4. **Response Types**: For `@FetchData`, response types must have `list` and `total` fields.

5. **Request Types**: For `@FetchData`, request types should extend `JSONParameter` and include `pageNum` and `pageSize` fields.

