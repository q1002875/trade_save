// trade_filter.dart

import 'common_imports.dart';

class TradeFilter {
  String dateFilter;
  String positionFilter;

  TradeFilter({
    this.dateFilter = '今天',
    this.positionFilter = '全部',
  });

  bool get hasActiveFilters => dateFilter != '全部' || positionFilter != '全部';

  List<Trade> apply(List<Trade> trades) {
    return trades.where((trade) {
      return _matchesDateFilter(trade) && _matchesPositionFilter(trade);
    }).toList();
  }

  bool _matchesDateFilter(Trade trade) {
    if (dateFilter == '全部') return true;

    final tradeDate = trade.tradeDate;
    final now = DateTime.now();

    switch (dateFilter) {
      case '今天':
        return tradeDate.year == now.year &&
            tradeDate.month == now.month &&
            tradeDate.day == now.day;
      case '本週':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return tradeDate
                .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            tradeDate.isBefore(endOfWeek.add(const Duration(days: 1)));
      case '本月':
        return tradeDate.year == now.year && tradeDate.month == now.month;
      default:
        return true;
    }
  }

  bool _matchesPositionFilter(Trade trade) {
    return positionFilter == '全部' || trade.direction == positionFilter;
  }
}

// trade_filter_state.dart
class TradeFilterState extends ChangeNotifier {
  final TradeFilter _filter;
  List<Trade> _filteredData = [];
  List<Trade> _originalData = [];

  TradeFilterState() : _filter = TradeFilter();

  String get currentDateFilter => _filter.dateFilter;
  String get currentPositionFilter => _filter.positionFilter;
  List<Trade> get filteredData => _filteredData;
  bool get hasActiveFilters => _filter.hasActiveFilters;

  void setDateFilter(String filter) {
    _filter.dateFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void setPositionFilter(String filter) {
    _filter.positionFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void updateData(List<Trade> newData) {
    _originalData = newData;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredData = _filter.apply(_originalData);
  }
}
