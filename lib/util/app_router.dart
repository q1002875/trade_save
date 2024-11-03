import 'package:trade_save/main.dart';

import 'common_imports.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MyApp());
      case '/tradeListView':
        return MaterialPageRoute(builder: (_) => const TradeListView());

      case '/tradeJournalEntry':
        final args = settings.arguments as TradeArguments;
        return MaterialPageRoute(
          builder: (_) => TradeJournalEntry(
            initialTrade: args.trade,
            selectRow: args.selectRow,
          ),
        );
      case '/tradeDetail':
        final args = settings.arguments as TradeArguments;
        return MaterialPageRoute(
          builder: (_) => TradeDetailPage(
            trade: args.trade,
            selectRow: args.selectRow,
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const MyApp());
    }
  }
}

class TradeArguments {
  final Trade? trade;
  final int? selectRow;

  TradeArguments({this.trade, this.selectRow});
}




// 傳遞範例
// Navigator.pushNamed(
//   context,
//   '/tradeDetailPage',
//   arguments: tradeInstance, // 假设 tradeInstance 是一个 Trade 对象
// );


// 多個參數傳遞範例用class
// Navigator.pushNamed(
//   context,
//   '/tradeDetail',
//   arguments: TradeArguments(trade: tradeInstance, selectRow: selectedRowIndex),
// );