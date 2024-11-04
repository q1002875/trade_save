// google_sheets_service.dart
import '../util/common_imports.dart';

class GoogleSheetsService {
  final GoogleSheetsConfig config;

  GoogleSheetsService(this.config);

  Future<List<Trade>> fetchAllRowsAsTrades() async {
    final gsheets = GSheets(config.credentials);
    final spreadsheet = await gsheets.spreadsheet(config.spreadsheetId);
    final sheet = spreadsheet.worksheetByIndex(0);

    if (sheet == null) {
      throw Exception('找不到工作表');
    }

    final values = await sheet.values.allRows();
    return _normalizeData(values);
  }

  List<Trade> _normalizeData(List<List<dynamic>> values) {
    if (values.length <= 1) return []; // 如果只有標題行或空數據，返回空列表

    return values.skip(1).map((row) {
      try {
        return Trade(
          tradeDate: _parseDateTime(row[0], true), // 交易日期
          entryTime: _parseDateTime(row[1], false), // 進場時間
          exitTime: _parseDateTime(row[2], false), // 出場時間
          direction: row[3]?.toString() ?? '', // 多空方向
          bigTimePeriod: row[4]?.toString() ?? '', // 大時區
          smallTimePeriod: row[5]?.toString() ?? '', // 小時區
          entryPrice: double.tryParse(row[6]?.toString() ?? '0') ?? 0.0, // 進場價
          exitPrice: double.tryParse(row[7]?.toString() ?? '0') ?? 0.0, // 出場價
          profitLossUSDT:
              double.tryParse(row[8]?.toString() ?? '0') ?? 0.0, // 盈虧
          riskRewardRatio:
              double.tryParse(row[9]?.toString() ?? '0') ?? 0.0, // 風險回報率
          entryReason: row[10]?.toString() ?? '',
          stopConditions: row[11]?.toString() ?? '',
          reflection: row[12]?.toString() ?? '',
          imageUrl: null, // 圖片URL需要特別處理
          id: row[14]?.toString() ?? '',
        );
      } catch (e) {
        print('行數據解析錯誤: $row');
        print('錯誤詳情: $e');
        rethrow;
      }
    }).toList();
  }

  DateTime _parseDateTime(dynamic value, bool isDate) {
    try {
      if (value == null || value.toString().trim().isEmpty) {
        return DateTime.now(); // 或者返回其他默認值
      }

      if (isDate) {
        if (value is num || num.tryParse(value.toString()) != null) {
          final number = num.tryParse(value.toString()) ?? 0;
          final DateTime baseDate = DateTime(1899, 12, 30);
          return baseDate.add(Duration(days: number.toInt()));
        }
      } else {
        if (value is num || num.tryParse(value.toString()) != null) {
          final number = num.tryParse(value.toString()) ?? 0;
          final totalMinutes = (number * 24 * 60).round();
          final hours = (totalMinutes ~/ 60) % 24;
          final minutes = totalMinutes % 60;

          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hours, minutes);
        }
      }
      return DateTime.parse(value.toString());
    } catch (e) {
      print('日期時間解析錯誤: $value');
      return DateTime.now();
    }
  }
}
