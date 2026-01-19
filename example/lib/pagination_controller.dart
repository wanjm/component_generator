import 'package:flutter/foundation.dart';

class PaginationController<T> extends ChangeNotifier {
  int _pageNum;
  int _pageSize;
  T _param;
  int? _totalCount;
  
  // Separate notifier for count changes
  final ValueNotifier<int?> _countNotifier = ValueNotifier<int?>(null);

  PaginationController({
    int initialPageNo = 0,
    int initialPageSize = 10,
    required T initialParam,
  })  : _pageNum = initialPageNo,
        _pageSize = initialPageSize,
        _param = initialParam;

  // Getters
  int get pageNum => _pageNum;
  int get pageSize => _pageSize;
  T get param => _param;
  int? get totalCount => _totalCount;
  
  // Getter for count notifier (for listening to count changes)
  ValueNotifier<int?> get countNotifier => _countNotifier;

  // Calculate total pages (pageCount)
  int? get pageCount {
    if (_totalCount == null) return null;
    return (_totalCount! / _pageSize).ceil();
  }
  
  // Alias for backward compatibility
  int? get totalPages => pageCount;

  // Check if can go to next/previous page
  bool get canGoNext {
    if (_totalCount == null || pageCount == null) return false;
    return _pageNum < pageCount! - 1;
  }

  bool get canGoPrevious => _pageNum > 0;

  // Set total count (called by content widget after fetching data)
  void setTotalCount(int total) {
    if (_totalCount != total) {
      _totalCount = total;
      // Notify count notifier
      _countNotifier.value = total;
      // Also notify main listeners (for pageNo/pageSize changes)
      notifyListeners();
    }
  }

  // Set page number
  void setPageNo(int pageNo) {
    if (_pageNum != pageNo && pageNo >= 0) {
      _pageNum = pageNo;
      notifyListeners();
    }
  }

  // Set page size
  void setPageSize(int pageSize) {
    if (_pageSize != pageSize && pageSize > 0) {
      _pageSize = pageSize;
      // Reset to first page when page size changes
      _pageNum = 0;
      notifyListeners();
    }
  }

  // Navigation methods
  void nextPage() {
    if (canGoNext) {
      setPageNo(_pageNum + 1);
    }
  }

  void previousPage() {
    if (canGoPrevious) {
      setPageNo(_pageNum - 1);
    }
  }

  void goToPage(int page) {
    if (page >= 0 && (totalPages == null || page < totalPages!)) {
      setPageNo(page);
    }
  }

  // Reset to first page
  void reset() {
    setPageNo(0);
  }

  // Trigger refresh (useful when param changes externally)
  // This notifies listeners that they should refresh data
  void triggerRefresh() {
    _pageNum = 0; // Reset to first page
    _totalCount = null; // Clear total count
    _countNotifier.value = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countNotifier.dispose();
    super.dispose();
  }
}
