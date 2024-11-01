import 'package:trade_save/fliterPage.dart';

import 'common_imports.dart';

class TradeListView extends StatefulWidget {
  final List<Trade> trades;

  const TradeListView({super.key, required this.trades});

  @override
  State<TradeListView> createState() => _TradeListViewState();
}

class _TradeListViewState extends State<TradeListView> {
  TradeFilter _currentFilter = TradeFilter();
  List<Trade> _filteredTrades = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易記錄'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () async {
                  final result = await showDialog<TradeFilter>(
                    context: context,
                    builder: (context) => FilterDialog(
                      initialFilter: _currentFilter,
                    ),
                  );
                  if (result != null) {
                    _applyFilter(result);
                  }
                },
              ),
              if (!_currentFilter.isEmpty())
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _filteredTrades.isEmpty
          ? const Center(
              child: Text('無符合條件的交易記錄'),
            )
          : ListView.builder(
              itemCount: _filteredTrades.length,
              itemBuilder: (context, index) {
                final trade = _filteredTrades[index];
                return TradeCard(trade: trade, selectRow: index);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 新增交易記錄
          Navigator.pushNamed(
            context,
            '/tradeJournalEntry',
            arguments: TradeArguments(trade: null, selectRow: null),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _filteredTrades = widget.trades;
  }

  void _applyFilter(TradeFilter filter) {
    setState(() {
      _currentFilter = filter;
      _filteredTrades = widget.trades.where((trade) {
        // 日期範圍過濾
        if (filter.startDate != null &&
            trade.tradeDate.isBefore(filter.startDate!)) {
          return false;
        }
        if (filter.endDate != null &&
            trade.tradeDate.isAfter(filter.endDate!)) {
          return false;
        }

        // 交易方向過濾
        if (filter.direction != null && trade.direction != filter.direction) {
          return false;
        }

        // 時段過濾
        if (filter.bigTimePeriod != null &&
            trade.bigTimePeriod != filter.bigTimePeriod) {
          return false;
        }

        // 盈虧過濾
        if (filter.isProfitable != null) {
          bool isProfitable = trade.profitLossUSDT > 0;
          if (isProfitable != filter.isProfitable!) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }
}
