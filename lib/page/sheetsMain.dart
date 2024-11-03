import 'package:trade_save/util/tradeListView.dart';

import '../util/common_imports.dart'; // 导入 File

class GSheetsReaderPage extends StatefulWidget {
  const GSheetsReaderPage({super.key});

  @override
  _GSheetsReaderPageState createState() => _GSheetsReaderPageState();
}

class _GSheetsReaderPageState extends State<GSheetsReaderPage> {
  List<Trade> _data = [];
  bool _isLoading = false;
  String _error = '';
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // ImagePicker 实例
  final GoogleSheetsConfig _googleSheetsConfig = GoogleSheetsConfig();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Excel 交易資料'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _loadGoogleSheetData(); // 确保在这里调用时等待加载数据
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/tradeJournalEntry',
                arguments: TradeArguments(trade: null, selectRow: null),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : (_data.isNotEmpty
                ? TradeListView(trades: _data) // 传递 trades 参数
                : const Text('無數據顯示 按＋新增交易資料')), // 提示没有数据
      ),
    );
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadGoogleSheetData();
  }

  DateTime parseDateTime(dynamic value, bool isDate) {
    try {
      if (value == null || value.toString().trim().isEmpty) {
        return DateTime.now(); // 或者返回其他默認值
      }

      if (isDate) {
        // 處理日期（整數）
        if (value is num || num.tryParse(value.toString()) != null) {
          final number = num.tryParse(value.toString()) ?? 0;
          final DateTime baseDate = DateTime(1899, 12, 30);
          return baseDate.add(Duration(days: number.toInt()));
        }
      } else {
        // 處理時間（小數）
        if (value is num || num.tryParse(value.toString()) != null) {
          final number = num.tryParse(value.toString()) ?? 0;
          final totalMinutes = (number * 24 * 60).round();
          final hours = (totalMinutes ~/ 60) % 24;
          final minutes = totalMinutes % 60;

          // 獲取當前日期部分
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hours, minutes);
        }
      }
      return DateTime.parse(value.toString());
    } catch (e) {
      print('日期時間解析錯誤: $value');
      return DateTime.now(); // 或者返回其他默認值
    }
  }

  Future<void> _loadGoogleSheetData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final gsheets = GSheets(_googleSheetsConfig.credentials);
      final ss = await gsheets.spreadsheet(_googleSheetsConfig.spreadsheetId);
      final sheet = ss.worksheetByIndex(0);

      if (sheet == null) {
        throw Exception('找不到工作表');
      }

      final values = await sheet.values.allRows();

      // 日期轉換函數
      String formatDateAndTime(dynamic value, bool isDate) {
        if (value == null || value.toString().trim().isEmpty) {
          return '';
        }

        try {
          if (isDate) {
            // 處理日期（整數部分）
            if (value is num || num.tryParse(value.toString()) != null) {
              final number = num.tryParse(value.toString()) ?? 0;
              final DateTime baseDate = DateTime(1899, 12, 30);
              final date = baseDate.add(Duration(days: number.toInt()));
              return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
            }
          } else {
            // 處理時間（小數部分）
            if (value is num || num.tryParse(value.toString()) != null) {
              final number = num.tryParse(value.toString()) ?? 0;
              // 將小數轉換為時間
              final totalMinutes = (number * 24 * 60).round();
              final hours = (totalMinutes ~/ 60) % 24;
              final minutes = totalMinutes % 60;
              return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
            }
          }
          return value.toString();
        } catch (e) {
          print('格式轉換錯誤: $value');
          return value.toString();
        }
      }

      // 轉換數據為 List<List<String>>
      List<List<String>> normalizeData(List<List<dynamic>> values) {
        if (values.isEmpty) return [];

        final headers = values.first;
        // 分別指定日期欄位和時間欄位
        final dateColumns = ['交易日期']; // 日期欄位
        final timeColumns = ['進場時間', '出場時間']; // 時間欄位

        return values.map((row) {
          return row.asMap().entries.map((entry) {
            final columnIndex = entry.key;
            final value = entry.value;
            final columnName = columnIndex < headers.length
                ? headers[columnIndex].toString()
                : '';

            // 根據欄位類型進行不同的轉換
            if (dateColumns.contains(columnName)) {
              return formatDateAndTime(value, true); // 日期轉換
            } else if (timeColumns.contains(columnName)) {
              return formatDateAndTime(value, false); // 時間轉換
            }

            // 其他欄位直接轉換成字串
            return value?.toString() ?? '';
          }).toList();
        }).toList();
      }

      // final List<List<String>> normalizedData = normalizeData(values);
      final List<Trade> tradedData = _normalizeData(values);
      final List<Trade> reversedTradedData = tradedData.reversed.toList();

      setState(() {
        _data = reversedTradedData;
        // _data = normalizedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '讀取數據時發生錯誤: $e';
        _isLoading = false;
      });
      print('詳細錯誤: $e');
    }
  }

  List<Trade> _normalizeData(List<List<dynamic>> values) {
    if (values.length <= 1) return []; // 如果只有標題行或空數據，返回空列表

    return values.skip(1).map((row) {
      try {
        return Trade(
          id: row[0]?.toString() ?? '',
          tradeDate: parseDateTime(row[0], true), // 交易日期
          entryTime: parseDateTime(row[1], false), // 進場時間
          exitTime: parseDateTime(row[2], false), // 出場時間
          direction: row[3]?.toString() ?? '', //多空方向
          bigTimePeriod: row[4]?.toString() ?? '', //大時區
          smallTimePeriod: row[5]?.toString() ?? '', //小時區
          entryPrice: double.tryParse(row[6]?.toString() ?? '0') ?? 0.0, //進場價
          exitPrice: double.tryParse(row[7]?.toString() ?? '0') ?? 0.0, //出場價
          profitLossUSDT:
              double.tryParse(row[8]?.toString() ?? '0') ?? 0.0, //盈虧
          riskRewardRatio: double.tryParse(row[9]?.toString() ?? '0') ?? 0.0,

          entryReason: row[10]?.toString() ?? '',
          stopConditions: row[11]?.toString() ?? '',

          reflection: row[12]?.toString() ?? '',
          imageUrl: null, // 圖片URL需要特別處理
        );
      } catch (e) {
        print('行數據解析錯誤: $row');
        print('錯誤詳情: $e');
        rethrow;
      }
    }).toList();
  }
// 选择图片
  // Future<void> _selectImage() async {
  //   final pickedFile =
  //       await _picker.pickImage(source: ImageSource.gallery); // 从图库选择图片
  //   if (pickedFile != null) {
  //     await _uploadImageToSheet(File(pickedFile.path)); // 上传图片到工作表
  //   }
  // }

  void _showAddDataDialog() {
    Navigator.pushNamed(context, '/tradeJournalEntry');
  }
}
