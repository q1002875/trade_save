import 'package:flutter/material.dart';
import 'package:trade_save/model/tradeModel.dart';
import 'package:trade_save/util/app_router.dart';

class TradeDetailPage extends StatelessWidget {
  final Trade? trade;
  final int? selectRow;
  final int? tradeDataLength;
  const TradeDetailPage(
      {super.key,
      required this.trade,
      required this.selectRow,
      required this.tradeDataLength});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('交易詳情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/tradeJournalEntry',
                arguments: TradeArguments(
                    trade: trade,
                    selectRow: selectRow,
                    tradeDataLength: tradeDataLength),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTradeStatusHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTimeCard(),
                  const SizedBox(height: 16),
                  _buildTradeDetailsCard(),
                  const SizedBox(height: 16),
                  _buildAnalysisCard(),
                  const SizedBox(height: 16),
                  if (trade!.imageUrl != null) _buildImageCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void initState() {
    print('TradeDetailPage: init${trade.toString()}');
  }

  Widget _buildAnalysisCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('交易分析',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildDetailRow('進場理由', trade!.entryReason),
            _buildDetailRow('止盈止損條件', trade!.stopConditions),
            _buildDetailRow('結果復盤心得', trade!.reflection),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('圖表記錄',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                trade!.imageUrl!,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('時間資訊',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildDetailRow(
                '交易日期', trade!.tradeDate.toLocal().toString().split(' ')[0]),
            _buildDetailRow('進場時間', _formatTime(trade!.entryTime)),
            _buildDetailRow('出場時間', _formatTime(trade!.exitTime)),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeDetailsCard() {
    String formatPrice(double price) {
      return price == price.roundToDouble()
          ? price.toInt().toString()
          : price.toString();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('交易資訊',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildDetailRow('交易方向', trade!.direction),
            _buildDetailRow('大時段', trade!.bigTimePeriod),
            _buildDetailRow('小時段', trade!.smallTimePeriod),
            _buildDetailRow('進場價格', formatPrice(trade!.entryPrice)),
            _buildDetailRow('出場價格', formatPrice(trade!.exitPrice)),
            _buildDetailRow(
                '風險報酬比', '1:${(formatPrice(trade!.riskRewardRatio))}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeStatusHeader() {
    final isProfit = trade!.profitLossUSDT > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isProfit ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Text(
            isProfit ? '獲利' : '虧損',
            style: TextStyle(
              fontSize: 18,
              color: isProfit ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${trade!.profitLossUSDT.toStringAsFixed(2)} USDT',
            style: TextStyle(
              fontSize: 24,
              color: isProfit ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
