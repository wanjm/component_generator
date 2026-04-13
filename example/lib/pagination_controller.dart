import 'package:component_set/paging/pagination_controller.dart';

/// Small Dart-only pagination holder for the example (no Flutter).
///
/// For Flutter apps you can implement [IPaginationController] with
/// [ChangeNotifier] or similar.
class PaginationController<T> extends IPaginationController<T> {
  int _pageNum;
  int _pageSize;
  final T _param;
  int? _totalCount;

  PaginationController({
    int initialPageNo = 0,
    int initialPageSize = 10,
    required T initialParam,
  })  : _pageNum = initialPageNo,
        _pageSize = initialPageSize,
        _param = initialParam;

  @override
  T get param => _param;

  @override
  int get pageNum => _pageNum;

  @override
  int get pageSize => _pageSize;

  int? get totalCount => _totalCount;

  @override
  void setTotalCount(int total) {
    _totalCount = total;
  }

  void setPageNo(int pageNo) {
    if (_pageNum != pageNo && pageNo >= 0) {
      _pageNum = pageNo;
    }
  }

  void setPageSize(int pageSize) {
    if (_pageSize != pageSize && pageSize > 0) {
      _pageSize = pageSize;
      _pageNum = 0;
    }
  }
}
