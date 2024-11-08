import 'package:trade_save/util/common_imports.dart';

class TradeListView extends StatefulWidget {
  const TradeListView({super.key});

  @override
  State<TradeListView> createState() => _TradeListViewState();
}

class _TradeListViewState extends State<TradeListView> with RouteAware {
  final TradeFilterState _filterState = TradeFilterState();
  bool _isLoading = false;
  String _error = '';
  final GoogleSheetsService _googleSheetsService =
      GoogleSheetsService(GoogleSheetsConfig());
  int _cachedDataCount = 0;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await Future.delayed(const Duration(seconds: 1), () {
          _checkAndUpdateData();
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Container(
              alignment: Alignment.topLeft, child: const Text('EXCEL 交易記錄')),
          actions: [
            _buildDateFilterButton(context),
            const SizedBox(width: 8),
            _buildPositionFilterButton(context),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/tradeJournalEntry',
              arguments: TradeArguments(trade: null, selectRow: null),
            ).then((_) {
              Future.delayed(const Duration(seconds: 1), _checkAndUpdateData);
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadGoogleSheetData();
    EasyLoading.dismiss();
  }

  @override
  void initState() {
    super.initState();
    _loadGoogleSheetData();
  }

  Widget _buildBody() {
    if (_isLoading && _filterState.filteredData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error.isNotEmpty && _filterState.filteredData.isEmpty) {
      return Center(child: Text(_error));
    }

    return RefreshIndicator(
      onRefresh: _loadGoogleSheetData,
      child: _filterState.filteredData.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Text('無數據顯示 右下角＋新增交易資料'),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _filterState.filteredData.length,
              itemBuilder: (context, index) {
                final trade = _filterState.filteredData[index];
                return TradeCard(
                  trade: trade,
                  selectRow: index,
                  tradeDataLength: _filterState.filteredData.length,
                  onPopCallback: _loadGoogleSheetData,
                );
              },
            ),
    );
  }

  Widget _buildDateFilterButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          const Icon(Icons.calendar_today),
          if (_filterState.currentDateFilter != '全部')
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
              ),
            ),
        ],
      ),
      offset: const Offset(0, 40),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (BuildContext context) => _buildDateFilterMenuItems(context),
      onSelected: (String value) {
        setState(() {
          _filterState.setDateFilter(value);
        });
      },
    );
  }

  List<PopupMenuItem<String>> _buildDateFilterMenuItems(BuildContext context) {
    final items = ['全部', '今天', '本週', '本月'];
    final icons = {
      '全部': Icons.all_inclusive,
      '今天': Icons.today,
      '本週': Icons.view_week,
      '本月': Icons.calendar_month,
    };

    return items.map((item) {
      return PopupMenuItem(
        value: item,
        child: Row(
          children: [
            Icon(
              icons[item],
              color: _filterState.currentDateFilter == item
                  ? Theme.of(context).colorScheme.primary
                  : null,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              item == '全部' ? '全部時間' : item,
              style: TextStyle(
                color: _filterState.currentDateFilter == item
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: _filterState.currentDateFilter == item
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (_filterState.currentDateFilter == item)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildPositionFilterButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          const Icon(Icons.filter_list_rounded),
          if (_filterState.currentPositionFilter != '全部')
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
              ),
            ),
        ],
      ),
      offset: const Offset(0, 40),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      itemBuilder: (BuildContext context) =>
          _buildPositionFilterMenuItems(context),
      onSelected: (String value) {
        setState(() {
          _filterState.setPositionFilter(value);
        });
      },
    );
  }

  List<PopupMenuItem<String>> _buildPositionFilterMenuItems(
      BuildContext context) {
    final items = ['全部', '多', '空'];
    final icons = {
      '全部': Icons.all_inclusive,
      '多': Icons.trending_up,
      '空': Icons.trending_down,
    };

    return items.map((item) {
      return PopupMenuItem(
        value: item,
        child: Row(
          children: [
            Icon(
              icons[item],
              color: _filterState.currentPositionFilter == item
                  ? Theme.of(context).colorScheme.primary
                  : null,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              item == '全部' ? '全部持倉' : item,
              style: TextStyle(
                color: _filterState.currentPositionFilter == item
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: _filterState.currentPositionFilter == item
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (_filterState.currentPositionFilter == item)
              Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _checkAndUpdateData() async {
    final currentTrades = await _googleSheetsService.fetchAllRowsAsTrades();
    final currentDataCount = currentTrades.length;

    if (currentDataCount != _cachedDataCount) {
      await _loadGoogleSheetData();
    }
  }

  Future<void> _loadGoogleSheetData() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final trades = await _googleSheetsService.fetchAllRowsAsTrades();
      setState(() {
        _filterState.updateData(trades.reversed.toList());
        _cachedDataCount = trades.length;
        _error = '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '讀取數據時發生錯誤: $e';
        _isLoading = false;
      });
    }
  }
}
