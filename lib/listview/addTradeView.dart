import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:trade_save/service/cloudinary_service.dart';
import 'package:trade_save/service/cloudinary_service_delete.dart';

import '../util/common_imports.dart';

class TimeFrameOption {
  static const List<String> timeFrameOptions = [
    '1分鐘',
    '5分鐘',
    '15分鐘',
    '30分鐘',
    '1小時',
    '4小時',
    '1天'
  ];

  // 獲取小於指定時間級別的選項
  static List<String> getSmallerTimeFrames(String biggerTimeFrame) {
    final int index = timeFrameOptions.indexOf(biggerTimeFrame);
    if (index == -1) return [];
    return timeFrameOptions.sublist(0, index + 1);
  }
}

class TradeJournalEntry extends StatefulWidget {
  final Trade? initialTrade; // Add initial trade parameter
  final int? selectRow;
  final int? tradeDataLength;
  const TradeJournalEntry(
      {super.key,
      required this.initialTrade,
      required this.selectRow,
      required this.tradeDataLength});

  @override
  _TradeJournalEntryState createState() => _TradeJournalEntryState();
}

class _TradeJournalEntryState extends State<TradeJournalEntry> {
  static const List<String> directionOptions = ['多', '空'];

  String _direction = '多';
  String _directionBigArea = '15分鐘';
  String _directionSmallArea = '1分鐘';

  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _entryTime;
  TimeOfDay? _exitTime;

  final TextEditingController _entryPriceController = TextEditingController();
  final TextEditingController _exitPriceController = TextEditingController();
  final TextEditingController _profitLossController = TextEditingController();
  bool _isPositive = true; // 默认选择正数
  final TextEditingController _entryReasonController = TextEditingController();
  final TextEditingController _stopConditionsController =
      TextEditingController();
  final TextEditingController _riskRewardController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  XFile? _selectedImage;

  String imageUrl = '';
  final googleSheetsConfig = GoogleSheetsConfig();
  final cloudinaryService = CloudinaryService();
  final cloudinaryDeleteService = CloudinaryDeleteService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: (widget.selectRow != null)
            ? const Text('修改交易紀錄')
            : const Text('新增交易紀錄'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        // 设置 AppBar 高度
        toolbarHeight: 70, // 根据需要调整高度
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6), // 添加右侧间距
            child: Column(
              mainAxisSize: MainAxisSize.min, // 垂直居中对齐
              children: [
                IconButton(
                  icon: const Icon(Icons.save),
                  iconSize: 32,
                  onPressed: _submitForm,
                ),
                Text(
                  (widget.selectRow != null) ? '修改' : '新增',
                  style: const TextStyle(color: Colors.black), // 字体颜色
                ),
              ],
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCard(
                    title: '基本交易資訊',
                    child: Column(
                      children: [
                        _buildDateSelector(context),
                        const SizedBox(height: 16),
                        _buildTimeSelectors(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '交易方向與時間週期',
                    child: Column(
                      children: [
                        _buildDirectionDropdown(),
                        const SizedBox(height: 16),
                        _buildTimeFrameDropdowns(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '價格與收益資訊',
                    child: Column(
                      children: [
                        _buildPriceInputs(),
                        const SizedBox(height: 16),
                        _buildProfitLossInput(),
                        const SizedBox(height: 16),
                        _buildRiskRewardInput(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '交易分析',
                    child: Column(
                      children: [
                        _buildEntryReasonInput(),
                        const SizedBox(height: 16),
                        _buildStopConditionsInput(),
                        const SizedBox(height: 16),
                        _buildReflectionInput(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: '附加資訊',
                    child: _buildImageUrlInput(),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.selectRow != null)
                          Flexible(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('確認刪除'),
                                      content: const Text('確定要刪除這筆交易紀錄嗎？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _deleteDataFromSheet(
                                                widget.initialTrade!);
                                          },
                                          child: const Text('確定'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.delete),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                child: Text('刪除'),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose all controllers
    _entryPriceController.dispose();
    _exitPriceController.dispose();
    _profitLossController.dispose();
    _riskRewardController.dispose();
    _entryReasonController.dispose();
    _stopConditionsController.dispose();
    _reflectionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeFields();

    print('add page selectRow${widget.initialTrade.toString()}');
  }

  // 新增或更新數據到表格
  Future<void> _addDataToSheet(String data, Trade? trade) async {
    try {
      final sheet = await _initGoogleSheet();
      final newRow = data.split(',');

      if (trade?.id != null) {
        // 更新現有記錄
        final rowNumber = await _findTradeRow(sheet, trade!.id);
        await sheet.values.insertRow(rowNumber, newRow, fromColumn: 1);

        // 驗證更新
        final updatedValues = await sheet.values.row(rowNumber);
        if (updatedValues.length != newRow.length) {
          throw Exception('更新失敗');
        }
        _showMessage('成功更新紀錄');
      } else {
        // 追加新行
        await sheet.values.appendRow(newRow);
        _showMessage('成功新增一筆交易紀錄');
      }

      if (context.mounted) {
        EasyLoading.dismiss();
        Navigator.popUntil(context, (route) => route.settings.name == '/');
      }
    } catch (e) {
      // _showMessage('操作失敗: ${e.toString()}', isError: true);
      EasyLoading.show(status: '操作失敗: ${e.toString()}');
    }
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '交易日期',
          border: const OutlineInputBorder(),
          errorText: _selectedDate == null ? '請選擇日期' : null,
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedDate == null
              ? '選擇日期'
              : DateFormat('yyyy-MM-dd').format(_selectedDate),
        ),
      ),
    );
  }

/////////////////////widget///////////////////////////
  Widget _buildDirectionDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: '交易方向',
        border: const OutlineInputBorder(),
        prefixIcon: _direction == "多"
            ? const Icon(Icons.trending_up)
            : const Icon(Icons.trending_down),
      ),
      value: _direction,
      items: directionOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _direction = newValue;
          });
        }
      },
      validator: (value) {
        if (value == null || !directionOptions.contains(value)) {
          return '請選擇交易方向';
        }
        return null;
      },
    );
  }

  Widget _buildEntryReasonInput() {
    return TextFormField(
      controller: _entryReasonController,
      decoration: const InputDecoration(
        labelText: '買進理由',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.psychology),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請輸入買進理由';
        }
        return null;
      },
    );
  }

  Widget _buildImageUrlInput() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 判断是显示本地图片还是远程图片
          _selectedImage != null
              ? Image.file(
                  File(_selectedImage!.path), // 将 XFile 转换为 File
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                )
              : imageUrl != ''
                  ? Image.network(
                      imageUrl,
                      width: 300,
                      height: 300,
                      fit: BoxFit.contain,
                    )
                  : const Text('尚未選取圖片'),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage, // 选择图片按钮
            child: const Text('從相簿選取圖片'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputs() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _entryPriceController,
            decoration: const InputDecoration(
              labelText: '開倉價',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.price_change),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入開倉價';
              }
              if (double.tryParse(value) == null) {
                return '請輸入有效數字';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextFormField(
            controller: _exitPriceController,
            decoration: const InputDecoration(
              labelText: '平倉價',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.price_check),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入平倉價';
              }
              if (double.tryParse(value) == null) {
                return '請輸入有效數字';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfitLossInput() {
    return Row(
      children: [
        // 正负号选择按钮
        IconButton(
          icon: Icon(
            _isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: _isPositive ? Colors.green : Colors.red,
          ),
          onPressed: () {
            setState(() {
              _isPositive = !_isPositive; // 切换正负号
              // 更新输入框的内容
              String currentValue = _profitLossController.text;
              if (currentValue.isNotEmpty) {
                double number = double.tryParse(currentValue) ?? 0.0;
                _profitLossController.text =
                    (_isPositive ? number.abs() : -number.abs()).toString();
                _profitLossController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _profitLossController.text.length),
                );
              }
            });
          },
        ),
        Expanded(
          child: TextFormField(
            controller: _profitLossController,
            decoration: const InputDecoration(
              labelText: '盈虧 (USDT)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '請輸入盈虧金額';
              }
              // 检查输入是否为有效的数字，包括负数
              if (double.tryParse(value) == null) {
                return '請輸入有效數字';
              }
              return null;
            },
            inputFormatters: [
              // 允许输入负号和小数点
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReflectionInput() {
    return TextFormField(
      controller: _reflectionController,
      decoration: const InputDecoration(
        labelText: '結果心得',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.rate_review),
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請輸入交易心得';
        }
        return null;
      },
    );
  }

  Widget _buildRiskRewardInput() {
    return TextFormField(
      controller: _riskRewardController,
      decoration: const InputDecoration(
        labelText: '報酬比',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.balance),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請輸入報酬比';
        }
        if (double.tryParse(value) == null) {
          return '請輸入有效數字';
        }
        return null;
      },
      onChanged: (value) {
        _riskRewardController.text = value;
      },
    );
  }

  Widget _buildStopConditionsInput() {
    return TextFormField(
      controller: _stopConditionsController,
      decoration: const InputDecoration(
        labelText: '停損停利設置原因',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.warning),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '請輸入停損停利設置原因';
        }
        return null;
      },
    );
  }

  Widget _buildTimeFrameDropdowns() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: '交易觀察大時段級別',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.short_text),
          ),
          value: _directionBigArea,
          items: TimeFrameOption.timeFrameOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _directionBigArea = newValue;
                // 如果當前小時間級別大於新選擇的大時間級別，重置小時間級別
                final smallerOptions =
                    TimeFrameOption.getSmallerTimeFrames(newValue);
                if (!smallerOptions.contains(_directionSmallArea)) {
                  _directionSmallArea = smallerOptions.last;
                }
              });
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: '交易小時段入場級別',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.short_text),
          ),
          value: _directionSmallArea,
          items: TimeFrameOption.getSmallerTimeFrames(_directionBigArea)
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _directionSmallArea = newValue;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimeSelectors(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context, true),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '進場時間',
                border: const OutlineInputBorder(),
                errorText: _entryTime == null ? '請選擇時間' : null,
                prefixIcon: const Icon(Icons.access_time),
              ),
              child: Text(_entryTime?.format(context) ?? '選擇時間'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(context, false),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: '出場時間',
                border: const OutlineInputBorder(),
                errorText: _exitTime == null ? '請選擇時間' : null,
                prefixIcon: const Icon(Icons.access_time),
              ),
              child: Text(_exitTime?.format(context) ?? '選擇時間'),
            ),
          ),
        ),
      ],
    );
  }

/////////////////////widget///////////////////////////
  // 從表格刪除數據
  Future<void> _deleteDataFromSheet(Trade? trade) async {
    try {
      if (trade?.id == null) {
        throw Exception('無效的交易記錄');
      }

      final sheet = await _initGoogleSheet();
      final rowNumber = await _findTradeRow(sheet, trade!.id);

      await sheet.deleteRow(rowNumber);

      if (trade.imageUrl != '') {
        await cloudinaryDeleteService.deleteImage(trade.imageUrl!);
      }

      _showMessage('成功刪除數據');

      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.settings.name == '/');
      }
    } catch (e) {
      _showMessage('刪除失敗: ${e.toString()}', isError: true);
    }
  }

  // 查找特定 trade 的行號
  Future<int> _findTradeRow(Worksheet sheet, String tradeId) async {
    final allRows = await sheet.values.allRows();
    for (int i = 0; i < allRows.length; i++) {
      if (allRows[i].length >= 15 && allRows[i][14] == tradeId) {
        return i + 1; // Google Sheets 行號從1開始
      }
    }
    throw Exception('找不到對應的交易記錄');
  }

  // 初始化 Google Sheets
  Future<Worksheet> _initGoogleSheet() async {
    final gsheets = GSheets(googleSheetsConfig.credentials);
    final ss = await gsheets.spreadsheet(googleSheetsConfig.spreadsheetId);
    final sheet = ss.worksheetByIndex(0);

    if (sheet == null) {
      throw Exception('找不到工作表');
    }
    return sheet;
  }

  void _initializeFields() {
    _selectedDate = DateTime.now();
    _direction = directionOptions.first;

    _isPositive = true;
    imageUrl = '';
    if (widget.initialTrade != null) {
      final trade = widget.initialTrade!;

      _selectedDate = trade.tradeDate;

      _entryTime = TimeOfDay.fromDateTime(trade.entryTime);
      _exitTime = TimeOfDay.fromDateTime(trade.exitTime);

      if (directionOptions.contains(trade.direction)) {
        _direction = trade.direction;
      }

      _directionBigArea = trade.bigTimePeriod; // 設置為最大時間級別
      _directionSmallArea = trade.smallTimePeriod; // 設置為最小時間級別

      _entryPriceController.text = trade.entryPrice.toString();
      _exitPriceController.text = trade.exitPrice.toString();

      _isPositive = trade.profitLossUSDT >= 0;
      _profitLossController.text = (trade.profitLossUSDT > 0)
          ? trade.profitLossUSDT.abs().toString()
          : '-${trade.profitLossUSDT.abs().toString()}';

      _riskRewardController.text = trade.riskRewardRatio.toString();
      _entryReasonController.text = trade.entryReason;
      _stopConditionsController.text = trade.stopConditions;
      _reflectionController.text = trade.reflection;

      if (trade.imageUrl != '') {
        imageUrl = trade.imageUrl!;
      }
    } else {
      // Clear all controllers for new entry

      _entryPriceController.text = '';
      _exitPriceController.text = '';
      _profitLossController.text = '';
      _riskRewardController.text = '';
      _entryReasonController.text = '';
      _stopConditionsController.text = '';
      _reflectionController.text = '';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile; // 更新选中的 XFile
      });
    } else {
      print("未选择图片");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isEntry) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isEntry) {
          _entryTime = picked;
        } else {
          _exitTime = picked;
        }
      });
    }
  }

  // 顯示操作結果消息
  void _showMessage(String message, {bool isError = false}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有必填欄位')),
      );
      return;
    }

    if (_entryTime == null || _exitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請選擇日期和時間')),
      );
      return;
    }

    EasyLoading.show(status: '儲存中');

    await _submitUploadImage();

    final entryDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _entryTime!.hour,
      _entryTime!.minute,
    );

    final exitDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _exitTime!.hour,
      _exitTime!.minute,
    );

    try {
      final trade = Trade(
        id: const Uuid().v4(), // 生成唯一ID
        tradeDate: _selectedDate,
        entryTime: entryDateTime,
        exitTime: exitDateTime,
        direction: _direction,

        bigTimePeriod: _directionBigArea,
        smallTimePeriod: _directionSmallArea,

        entryPrice: double.parse(_entryPriceController.text),
        exitPrice: double.parse(_exitPriceController.text),
        profitLossUSDT: double.parse(_profitLossController.text),
        entryReason: _entryReasonController.text,
        stopConditions: _stopConditionsController.text,
        riskRewardRatio: double.parse(_riskRewardController.text),
        reflection: _reflectionController.text,
        imageUrl: imageUrl,
      );

      final checkprofitLoss = _isPositive
          ? trade.profitLossUSDT.abs()
          : -trade.profitLossUSDT.abs();

// 假设 tradeDate 和 entryTime 是 DateTime 对象
      DateTime tradeDate = DateTime.parse('${trade.tradeDate}');
      DateTime entryTime = DateTime.parse('${trade.entryTime}');
      DateTime exitTime = DateTime.parse('${trade.exitTime}');
// 格式化 tradeDate 为 yyyy-MM-dd
      String formattedTradeDate =
          "${tradeDate.year}-${tradeDate.month.toString().padLeft(2, '0')}-${tradeDate.day.toString().padLeft(2, '0')}";
// 格式化 entryTime 为 HH:mm
      String formattedEntryTime =
          "${entryTime.hour.toString().padLeft(2, '0')}:${entryTime.minute.toString().padLeft(2, '0')}";
      String formattedExitTime =
          "${exitTime.hour.toString().padLeft(2, '0')}:${exitTime.minute.toString().padLeft(2, '0')}";

      final tradeString =
          '$formattedTradeDate,$formattedEntryTime,$formattedExitTime,${trade.direction},${trade.bigTimePeriod},${trade.smallTimePeriod},${trade.entryPrice},${trade.exitPrice},$checkprofitLoss,${trade.riskRewardRatio},${trade.entryReason},${trade.stopConditions},${trade.reflection},${trade.imageUrl},${trade.id}';
      print(tradeString);
      _addDataToSheet(tradeString, widget.initialTrade);
      // 顯示成功消息

      // EasyLoading.showSuccess('交易記錄已保存');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('交易記錄已保存')),
      // );

      // 清空表單
      // _clearForm();
    } catch (e) {
      // 錯誤處理
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失敗: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitUploadImage() async {
    if (_selectedImage != null) {
      // 异步调用上传方法，等待上传完成并返回 URL
      final String? url = await cloudinaryService.uploadImage(_selectedImage);
      // 将返回的 URL 赋值给 imageUrl
      if (url != null) {
        imageUrl = url; // 更新 imageUrl
      } else {
        print('上傳失敗');
      }
    }
  }
}
