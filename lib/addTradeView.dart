import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'util/common_imports.dart';

class TradeJournalEntry extends StatefulWidget {
  final Trade? initialTrade; // Add initial trade parameter
  final int? selectRow;

  const TradeJournalEntry(
      {super.key, required this.initialTrade, required this.selectRow});

  @override
  _TradeJournalEntryState createState() => _TradeJournalEntryState();
}

class _TradeJournalEntryState extends State<TradeJournalEntry> {
  static const List<String> timeFrameOptions = [
    '1m',
    '5m',
    '15m',
    '1H',
    '4H',
    '1D'
  ];
  static const List<String> directionOptions = ['多', '空'];
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _entryTime;
  TimeOfDay? _exitTime;
  String _direction = '多';

  String _directionBigArea = '1H';
  String _directionSmallArea = '5m';

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
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final googleSheetsConfig = GoogleSheetsConfig();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增交易紀錄'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
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
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      icon: const Icon(Icons.save),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        child: (widget.selectRow == null)
                            ? const Text('儲存交易紀錄')
                            : const Text('修改交易紀錄'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
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

    print('add page selectRow${widget.selectRow}');
  }

  Future<void> _addDataToSheet(String data, int? selectRow) async {
    final newRow = data.split(',');

    try {
      //認證
      final gsheets = GSheets(googleSheetsConfig.credentials);
      //使用哪一個excel資料
      final ss = await gsheets.spreadsheet(googleSheetsConfig.spreadsheetId);
      final sheet = ss.worksheetByIndex(0);

      if (sheet == null) {
        throw Exception('找不到工作表');
      }

      if (selectRow != null) {
        // 更新指定行的数据
        // Google Sheets API 的行号从1开始，所以需要 selectRow + 1
        final rowNumber = selectRow + 2;

        // 获取表格的列数
        final lastColumn = newRow.length;

        // 构建要更新的单元格范围
        final firstCell = 'A$rowNumber';
        final lastColumnLetter =
            String.fromCharCode('A'.codeUnitAt(0) + lastColumn - 1);
        final lastCell = '$lastColumnLetter$rowNumber';

        // 更新整行数据
        await sheet.values.insertRow(rowNumber, newRow, fromColumn: 1);

        // 可选：确保更新成功
        final updatedValues = await sheet.values.row(rowNumber);
        if (updatedValues.length != newRow.length) {
          throw Exception('更新行数据失败');
        }
      } else {
        // 追加新行
        await sheet.values.appendRow(newRow);
      }

      // 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                selectRow != null ? '成功更新第 ${selectRow + 1} 行数据' : '成功添加新数据'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 错误处理
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        // _error = '寫入數據時發生錯誤: $e';
      });
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
          _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                )
              : const Text('尚未選取圖片'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickImage,
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
    // return TextFormField(
    //   controller: _profitLossController,
    //   decoration: const InputDecoration(
    //     labelText: '盈虧 (USDT)',
    //     border: OutlineInputBorder(),
    //     prefixIcon: Icon(Icons.attach_money),
    //   ),
    //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
    //   validator: (value) {
    //     if (value == null || value.isEmpty) {
    //       return '請輸入盈虧金額';
    //     }
    //     // 检查输入是否为有效的数字，包括负数
    //     if (double.tryParse(value) == null) {
    //       return '請輸入有效數字';
    //     }
    //     return null;
    //   },
    //   inputFormatters: [
    //     // 允许输入负号
    //     FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]+(\.[0-9]+)?')),
    //   ],
    // );
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
              // 允许输入负号
              FilteringTextInputFormatter.allow(RegExp(r'-?[0-9]+(\.[0-9]+)?')),
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
        // 确保输入框文本前面始终带有 "1:"
        // if (!value.startsWith('1:')) {
        //   _riskRewardController.text = '1: $value';
        //   _riskRewardController.selection = TextSelection.fromPosition(
        //     TextPosition(offset: _riskRewardController.text.length),
        //   );
        // }
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
          items: timeFrameOptions.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _directionBigArea = newValue;
              });
            }
          },
          validator: (value) {
            if (value == null || !timeFrameOptions.contains(value)) {
              return '請選擇有效的時間級別';
            }
            return null;
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
          items: timeFrameOptions.map((String value) {
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
          validator: (value) {
            if (value == null || !timeFrameOptions.contains(value)) {
              return '請選擇有效的時間級別';
            }
            return null;
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

  void _initializeFields() {
    // Initialize with default values first
    _selectedDate = DateTime.now();
    _direction = directionOptions.first;
    _directionBigArea = timeFrameOptions[3]; // '1H'
    _directionSmallArea = timeFrameOptions[1]; // '5m'
    _isPositive = true;

    if (widget.initialTrade != null) {
      final trade = widget.initialTrade!;

      _selectedDate = trade.tradeDate;
      _entryTime = TimeOfDay.fromDateTime(trade.entryTime);
      _exitTime = TimeOfDay.fromDateTime(trade.exitTime);

      // Validate direction value exists in options
      if (directionOptions.contains(trade.direction)) {
        _direction = trade.direction;
      }

      // Validate time period values exist in options
      if (timeFrameOptions.contains(trade.bigTimePeriod)) {
        _directionBigArea = trade.bigTimePeriod;
      }
      if (timeFrameOptions.contains(trade.smallTimePeriod)) {
        _directionSmallArea = trade.smallTimePeriod;
      }

      _entryPriceController.text = trade.entryPrice.toString();
      _exitPriceController.text = trade.exitPrice.toString();

      _isPositive = trade.profitLossUSDT >= 0;
      _profitLossController.text = trade.profitLossUSDT.abs().toString();

      _riskRewardController.text = trade.riskRewardRatio.toString();
      _entryReasonController.text = trade.entryReason;
      _stopConditionsController.text = trade.stopConditions;
      _reflectionController.text = trade.reflection;

      if (trade.imageUrl != null) {
        _selectedImage = trade.imageUrl;
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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

  void _submitForm() {
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
        imageUrl: _selectedImage,
      );
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

      print("Formatted Trade Date: $formattedTradeDate"); // 输出: 2024-11-01
      print("Formatted Entry Time: $formattedEntryTime"); // 输出: 04:49
      print("Formatted Exit Time: $formattedExitTime");

// ${trade.tradeDate}, ${trade.entryTime}, ${trade.exitTime},
      final tradeString =
          '$formattedTradeDate,$formattedEntryTime,$formattedExitTime ,${trade.direction}, ${trade.bigTimePeriod}, ${trade.smallTimePeriod}, ${trade.entryPrice}, ${trade.exitPrice}, ${trade.profitLossUSDT},${trade.riskRewardRatio}, ${trade.entryReason}, ${trade.stopConditions}, ${trade.reflection}, ${trade.imageUrl}';
      print(tradeString);
      // TODO: 將trade存儲到數據庫或其他持久化存儲
      // debugPrint('${trade.toJson()}'); // 測試用，打印JSON數據
      _addDataToSheet(tradeString, widget.selectRow);
      // 顯示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('交易記錄已保存')),
      );
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => TradeDetailPage(trade: trade),
      //   ),
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
}
