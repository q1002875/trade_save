import 'package:intl/intl.dart';

import 'util/common_imports.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final int selectRow;
  const TradeCard({super.key, required this.trade, required this.selectRow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfitable = trade.profitLossUSDT > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/tradeDetail',
            arguments: TradeArguments(trade: trade, selectRow: selectRow),
          );
        },
        child: Column(
          children: [
            // 頂部信息欄
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isProfitable
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
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '${trade.direction} ${trade.bigTimePeriod}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // 主要交易信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 價格信息行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('進場價格', style: theme.textTheme.bodySmall),
                          Text(
                            trade.entryPrice.toString(),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('出場價格', style: theme.textTheme.bodySmall),
                          Text(
                            trade.exitPrice.toString(),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 獲利和風險比率
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('獲利 USDT', style: theme.textTheme.bodySmall),
                          Text(
                            '${trade.profitLossUSDT > 0 ? '+' : ''}${trade.profitLossUSDT.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isProfitable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('風險報酬比', style: theme.textTheme.bodySmall),
                          Text(
                            '1:${trade.riskRewardRatio}',
                            style: theme.textTheme.titleMedium,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '進場: ${DateFormat('HH:mm').format(trade.entryTime)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    '出場: ${DateFormat('HH:mm').format(trade.exitTime)}',
                    style: theme.textTheme.bodySmall,
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
