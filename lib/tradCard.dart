import 'package:intl/intl.dart';

import 'util/common_imports.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final int selectRow;
  final VoidCallback onPopCallback;

  const TradeCard({
    super.key,
    required this.trade,
    required this.selectRow,
    required this.onPopCallback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfitable = trade.profitLossUSDT > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 減少垂直邊距
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/tradeDetail',
            arguments: TradeArguments(trade: trade, selectRow: selectRow),
          ).then(
              (_) => Future.delayed(const Duration(seconds: 1), onPopCallback));
        },
        child: Column(
          children: [
            // 頂部信息欄
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12), // 減少垂直 padding
              decoration: BoxDecoration(
                color: (trade.direction == '空')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(trade.tradeDate),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16, // 增加字體大小
                    ),
                  ),
                  Text(
                    '${trade.direction} [${trade.bigTimePeriod}/${trade.smallTimePeriod}]',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                      fontSize: 16, // 增加字體大小
                    ),
                  ),
                ],
              ),
            ),

            // 主要交易信息
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12), // 減少垂直 padding
              child: Column(
                children: [
                  // 價格信息行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '進場價格',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13, // 增加標籤字體
                            ),
                          ),
                          const SizedBox(height: 2), // 減少間距
                          Text(
                            trade.entryPrice.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18, // 增加價格字體
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '出場價格',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13, // 增加標籤字體
                            ),
                          ),
                          const SizedBox(height: 2), // 減少間距
                          Text(
                            trade.exitPrice.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18, // 增加價格字體
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12), // 減少間距

                  // 獲利和風險比率
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '獲利 USDT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13, // 增加標籤字體
                            ),
                          ),
                          const SizedBox(height: 2), // 減少間距
                          Text(
                            '${trade.profitLossUSDT > 0 ? '+' : ''}${trade.profitLossUSDT.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isProfitable ? Colors.green : Colors.red,
                              fontSize: 18, // 增加數字字體
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '風險報酬比',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13, // 增加標籤字體
                            ),
                          ),
                          const SizedBox(height: 2), // 減少間距
                          Text(
                            '1:${trade.riskRewardRatio}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18, // 增加數字字體
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 底部時間信息
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6), // 減少垂直 padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '進場: ${DateFormat('HH:mm').format(trade.entryTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12, // 調整時間字體
                    ),
                  ),
                  Text(
                    '出場: ${DateFormat('HH:mm').format(trade.exitTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12, // 調整時間字體
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
