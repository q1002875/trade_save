import 'package:intl/intl.dart';

import '../util/common_imports.dart';

class TradeCard extends StatelessWidget {
  final Trade trade;
  final int selectRow;
  final int tradeDataLength;
  final VoidCallback onPopCallback;

  const TradeCard({
    super.key,
    required this.trade,
    required this.selectRow,
    required this.tradeDataLength,
    required this.onPopCallback,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfitable = trade.profitLossUSDT > 0;
    String formatPrice(double price) {
      return price == price.roundToDouble()
          ? price.toInt().toString()
          : price.toString();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 減少垂直邊距
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/tradeDetail',
            arguments: TradeArguments(
                trade: trade,
                selectRow: selectRow,
                tradeDataLength: tradeDataLength),
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
            // 主要交易信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // 第一行：進場價格、進場時間、風險報酬比
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '進場價格',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatPrice(trade.entryPrice),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '進場時間',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm').format(trade.entryTime),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
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
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '1:${formatPrice(trade.riskRewardRatio)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 第二行：出場價格、出場時間、獲利USDT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '出場價格',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatPrice(trade.exitPrice),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '出場時間',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm').format(trade.exitTime),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '獲利 USDT',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${trade.profitLossUSDT > 0 ? '+' : ''}${trade.profitLossUSDT.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isProfitable ? Colors.green : Colors.red,
                              fontSize: 18,
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
          ],
        ),
      ),
    );
  }
}
