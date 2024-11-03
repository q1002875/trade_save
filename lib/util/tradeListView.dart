import 'common_imports.dart';

class TradeListView extends StatefulWidget {
  const TradeListView({super.key});

  @override
  State<TradeListView> createState() => _TradeListViewState();
}

class _TradeListViewState extends State<TradeListView> with RouteAware {
  List<Trade> _data = [];
  bool _isLoading = false;
  String _error = '';
  final GoogleSheetsService _googleSheetsService =
      GoogleSheetsService(GoogleSheetsConfig());
  int _cachedDataCount = 0; // 缓存数据的笔数

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 在返回时也可以添加延迟
        await Future.delayed(const Duration(seconds: 1), () {
          _checkAndUpdateData(); // 检查并更新数据
        });
        return true; // 允许返回
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('交易記錄')),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadGoogleSheetData,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/tradeJournalEntry',
                  arguments: TradeArguments(trade: null, selectRow: null),
                ).then((_) {
                  // 在返回时延迟两秒检查并更新数据
                  Future.delayed(
                      const Duration(seconds: 1), _checkAndUpdateData);
                });
              },
            ),
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
  void initState() {
    super.initState();
    _loadGoogleSheetData();
  }

  Widget _buildBody() {
    // 显示已有数据或加载提示
    if (_data.isNotEmpty) {
      return ListView.builder(
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final trade = _data[index];
          return TradeCard(
            trade: trade,
            selectRow: index,
            onPopCallback: _loadGoogleSheetData,
          );
        },
      );
    } else if (_isLoading) {
      return const Center(child: Text('正在加載數據...'));
    } else {
      return const Center(child: Text('無數據顯示 按＋新增交易資料'));
    }
  }

  Future<void> _checkAndUpdateData() async {
    // 直接获取数据而不更新 UI，减少卡顿
    final currentTrades = await _googleSheetsService.fetchAllRowsAsTrades();
    final currentDataCount = currentTrades.length;

    if (currentDataCount != _cachedDataCount) {
      // 只有在数据笔数不同的情况下才加载数据
      await _loadGoogleSheetData(); // 可能需要添加 await 以确保加载完成
    }
  }

  Future<void> _loadGoogleSheetData() async {
    setState(() => _isLoading = true);

    try {
      final trades = await _googleSheetsService.fetchAllRowsAsTrades();
      setState(() {
        _data = trades.reversed.toList();
        _cachedDataCount = _data.length; // 更新缓存的数据笔数
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
