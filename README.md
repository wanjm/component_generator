<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# HTTP Gen Method

A powerful Dart code generation library that automatically generates HTTP client code, Flutter table widgets, and pagination-aware fetch methods from simple annotations.

## Features

- **🚀 HTTP Client Generation**: Automatically generate HTTP client implementations from annotated interfaces
- **📊 Table Widget Generation**: Create Flutter table widgets with automatic header and data cell generation
- **📄 Pagination Support**: Generate pagination-aware fetch methods for list endpoints
- **🔧 Flexible Annotations**: Customize HTTP methods, URLs, field labels, and more
- **🌐 Multi-Client Support**: Support for both HTTP/1.1 and HTTP/2 clients
- **🎯 Type Safety**: Full type checking and compile-time safety

## Getting Started

### Installation

Add `http_method` to your `pubspec.yaml`:

```yaml
dependencies:
  http_method: ^0.1.1

dev_dependencies:
  build_runner: ^2.3.2
```

### Basic Setup

1. **Create your HTTP client**:
```dart
import 'package:http_method/http1_client.dart';

class MyClient extends HttpClientBase {
  MyClient() : super();

  @override
  int checkResult(RespData<dynamic> resp, String url, Map<String, String> headers) {
    return 0; // Your response validation logic
  }
}

MyClient client = MyClient();
```

2. **Define your data models**:
```dart
class LoginParams extends JSONParameter {
  String loginName;
  String password;
  int pageNum = 0;
  int pageSize = 0;

  LoginParams(this.loginName, this.password);

  @override
  Map<String, dynamic> toJson() => {
    "loginName": loginName,
    "password": password,
    "pageNum": pageNum,
    "pageSize": pageSize,
  };
}

class UserInfo {
  int id;
  String name;
  String email;

  UserInfo({this.id = 0, this.name = "", this.email = ""});

  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'] ?? 0,
    name: json['name'] ?? "",
    email: json['email'] ?? "",
  );
}

class UserListResp {
  int total;
  List<UserInfo> list;

  UserListResp({this.total = 0, this.list = const []});

  factory UserListResp.fromJson(Map<String, dynamic> json) => UserListResp(
    total: json['total'] ?? 0,
    list: (json['list'] as List? ?? []).map((e) => UserInfo.fromJson(e)).toList(),
  );
}
```

3. **Create your network interface**:
```dart
import 'package:http_method/http_method.dart';

part 'network.g.dart';

@DataInterface()
abstract class Network {
  @ReqConfig("/user/login")
  Future<RespData> login(LoginParams data);

  @ReqConfig("/user/list")
  Future<RespData<UserListResp?>> listUser(LoginParams data);
}
```

4. **Generate code**:
```bash
dart run build_runner build
```

5. **Use the generated client**:
```dart
void main() async {
  client.prefix = "https://api.example.com";

  // Login
  final loginResult = await networkService.login(LoginParams("user", "pass"));
  print(loginResult.obj);

  // List users
  final userList = await networkService.listUser(LoginParams("", ""));
  print("Total users: ${userList.obj?.total}");
}
```

## Annotations

### @DataInterface

Marks an abstract class as a network interface that will generate HTTP client implementations.

```dart
@DataInterface(
  name: "customService",    // Optional: Custom service instance name
  client: "myClient",       // Optional: Custom client variable name
  mixins: "LoggingMixin"    // Optional: Mixins for generated implementation
)
abstract class MyApi {
  // Define your HTTP methods here
}
```

**Generated Output:**
```dart
class MyApiImpl extends BaseMethod implements MyApi {
  MyApiImpl({super.client});

  // Implementation of all abstract methods
}

var customService = MyApiImpl(client: myClient);
```

### @ReqConfig

Defines an HTTP endpoint for a method in a `@DataInterface` class.

```dart
@DataInterface()
abstract class UserApi {
  @ReqConfig("/users", method: "GET")
  Future<RespData<List<User>>> getUsers();

  @ReqConfig("/users", method: "POST")
  Future<RespData<User>> createUser(CreateUserParams data);

  @ReqConfig("/users/:id", method: "PUT")
  Future<RespData<User>> updateUser(int id, UpdateUserParams data);

  @ReqConfig("/users/:id", method: "DELETE")
  Future<RespData<void>> deleteUser(int id);
}
```

**Parameters:**
- `url` (required): The API endpoint URL
- `method` (optional): HTTP method ("GET", "POST", "PUT", "DELETE"). Default: "POST"
- `keyType` (optional): Type for buffer key. Default: "int"

### @TableWidget

Generates Flutter table widgets with automatic header and data cell generation. Used on mixin classes that extend `TableContentWidget`.

```dart
import 'package:flutter/material.dart';
import 'package:http_method/http_method.dart';

part 'user_table.g.dart';

@TableWidget(
  fetchClass: UserApi,        // Required: The fetch class type
  fetchMethod: "listUser",    // Required: The fetch method name
  useI18n: false,             // Optional: Enable i18n (default: false)
  i18nFunction: 'tr',         // Optional: i18n function name (default: 'tr')
  columns: [],                // Optional: Custom column order
  skips: []                   // Optional: Fields to skip
)
mixin UserTableMixin on TableContentWidget<UserInfo, UserReq> {
  // Optional: Override specific cells by field name  
  DataCell genIdDataCell(BuildContext context, UserInfo item) {
    return DataCell(
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _editUser(context, item),
      ),
    );
  }

  // Optional: Override tap handlers by field name
  void onNameTap(BuildContext context, UserInfo item) {
    // Handle name cell tap
    print('Tapped on user: ${item.name}');
  }
}
```

**Generated Output:**
```dart
class UserTable extends TableContentWidget<UserInfo, UserReq> with UserTableMixin {
  const UserTable({super.key});

  @override
  Future<List<UserInfo>> fetchData(PaginationController<UserReq> controller) {
    return UserApiFetch.listUser(controller); // Auto-generated if not implemented in mixin
  }

  @override
  List<DataColumn> genTableHeader(BuildContext context) {
    return [
      DataColumn(label: const Text('ID')),
      DataColumn(label: const Text('Name')),
      DataColumn(label: const Text('Email')),
    ];
  }

  @override
  List<DataCell> genTableData(BuildContext context, UserInfo item) {
    return [
      DataCell(Text(item.id.toString()), onTap: () => onIdTap(context, item)),
      DataCell(Text(item.name), onTap: () => onNameTap(context, item)),
      DataCell(Text(item.email)),
    ];
  }
}
```

### Predefined Methods

The `@TableWidget` annotation supports predefined methods for customizing cell behavior:

#### Cell Customization Methods
- `genFieldNameDataCell(BuildContext context, T item)` - Override cell for specific field

#### Tap Handler Methods
- `onFieldNameTap(BuildContext context, T item)` - Handle tap on cells for specific field

These methods are automatically detected and used by the generator if implemented in your mixin.

## Advanced Usage

### Pagination Support
The `@DataInterface` annotation automatically generates pagination-aware fetch methods for list endpoints:
@DataInterface schema code can be  generate by [gos](github.com/wanjm/gos)

```dart
@DataInterface()
abstract class ProductApi {
  @ReqConfig("/products")
  Future<RespData<ProductListResp?>> listProducts(ProductReq data);
}

// Automatically generates:
class ProductApiFetch {
  static Future<List<ProductInfo>> listProducts(
      PaginationController<ProductReq> controller) async {
    final baseParam = controller.param;
    baseParam.pageNum = controller.pageNum;
    baseParam.pageSize = controller.pageSize;

    final resp = await productService.listProducts(baseParam);
    if (resp.code == RespCode.SUCCESS && resp.obj != null) {
      controller.setTotalCount(resp.obj!.total);
      return resp.obj!.list;
    } else {
      throw Exception(resp.msg ?? "Failed to load data");
    }
  }
}
```

**Requirements:**
- Response type must have `list` and `total` fields
- Request type must extend `JSONParameter` and include `pageNum` and `pageSize` fields

### Flutter Integration

```dart
class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PaginatedView<ProductReq>(
      initialParam: ProductReq(),
      child: const ProductTableImpl(), // Use the generated Impl class
    );
  }
}
```

### HTTP Client Configuration

```dart
class MyClient extends HttpClientBase {
  MyClient() : super();

  @override
  int checkResult(RespData<dynamic> resp, String url, Map<String, String> headers) {
    // Custom response validation
    if (resp.code == 401) {
      // Handle unauthorized
      return -1;
    }
    return 0; // Success
  }

  @override
  Future<Map<String, String>> getHeaders(String url) async {
    // Add custom headers
    return {
      'Authorization': 'Bearer ${await getToken()}',
      'Content-Type': 'application/json',
    };
  }
}
```

## Build Configuration

The package includes pre-configured builders, so no additional `build.yaml` configuration is required. The builders are automatically enabled when you add the package to your dependencies.

## Complete Example

See the `/example` directory for a complete working example that demonstrates:

- HTTP client setup
- Data models with JSON serialization
- Network interface definition
- Code generation
- Flutter table widget usage

## Best Practices

1. **Type Safety**: Always use strongly typed response objects
2. **Error Handling**: Implement proper error handling in your HTTP client
3. **Naming Conventions**: Use consistent naming for services and methods
4. **Pagination**: Include `pageNum` and `pageSize` fields for list endpoints
5. **Code Generation**: Run `dart run build_runner build` after changing annotations

## Troubleshooting

### Common Issues

1. **"Undefined class" errors**: Make sure all imports are correct
2. **"Method not found"**: Run code generation after adding new methods
3. **Build failures**: Ensure all required dependencies are installed

### Debug Tips

- Use `dart run build_runner build --verbose` for detailed build output
- Check generated `.g.dart` files for issues
- Ensure all required fields are present in your data models

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This package is licensed under the MIT License. See the LICENSE file for details.
