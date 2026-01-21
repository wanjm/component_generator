# @TableWidget Extends Strategy Usage

The `@TableWidget` annotation can be used on classes that inherit from `TableContentWidget` to automatically generate table headers and data rows.

## 1. Define your Widget Class

Create a class that extends `TableContentWidget`. You only need to implement `fetchData`. The generator will handle `genTableHeader` and `genTableData`.

```dart
import 'package:flutter/material.dart';
import 'package:http_method/http_method.dart';
import 'schema.gen.dart';
import 'pagination_controller.dart';

part 'user_list_page.g.dart';

@TableWidget(OrgBiz, "listOrg")
class UserContentWidget extends TableContentWidget<UserInfo, UserReq> {
  const UserContentWidget({super.key});

  @override
  Future<List<UserInfo>> fetchData(PaginationController<UserReq> controller) {
    return UserService.listUser(controller);
  }

  // OPTIONAL: Override a specific cell by index or field name
  // The generator will detect these and use them automatically.
  DataCell gen3DataCell(BuildContext context, UserInfo item) {
    return DataCell(
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => _editUser(context, item),
      ),
    );
  }
}
```

## 2. Generated Code

The generator creates a `${ClassName}Impl` class in your `.g.dart` file:

```dart
// user_list_page.g.dart
class UserContentWidgetImpl extends UserContentWidget {
  const UserContentWidgetImpl({super.key});

  @override
  List<DataColumn> genTableHeader(BuildContext context) {
    return [
      DataColumn(label: const Text('ID')),
      DataColumn(label: const Text('Name')),
      DataColumn(label: const Text('Actions')), // Generated for field #3
    ];
  }

  @override
  List<DataCell> genTableData(BuildContext context, UserInfo item) {
    return [
      DataCell(Text(item.id.toString())),
      DataCell(Text(item.name)),
      gen3DataCell(context, item), // Automatically routed to your custom method
    ];
  }
}
```

## 3. Usage in Widgets

Use the generated `Impl` class directly in your UI. Since the implementation class has a `const` constructor, you can use it with `const`.

```dart
class UserListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PaginatedView<UserReq>(
      initialParam: UserReq(),
      child: const UserContentWidgetImpl(), // Use the generated Impl class
    );
  }
}
```

## Customization Summary

- **Field Customization**: Use `@TableField(label: '...')` on your data class fields.
- **Ignore Fields**: Use `@TableField(ignore: true)` to skip a column.
- **Custom Cells**: Implement `genNDataCell` (where N is 1-based index) or `genFieldNameDataCell` in your widget class.


