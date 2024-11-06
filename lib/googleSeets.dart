import 'dart:io';

import 'package:googleapis/sheets/v4.dart' as sheets_api;
import 'package:googleapis_auth/auth_io.dart';
import 'package:gsheets/gsheets.dart' as gsheets;

import 'util/common_imports.dart';

// 配置類 - 應該移到單獨的配置文件中

class GoogleSheetsExample extends StatefulWidget {
  const GoogleSheetsExample({super.key});

  @override
  _GoogleSheetsExampleState createState() => _GoogleSheetsExampleState();
}

class _GoogleSheetsExampleState extends State<GoogleSheetsExample> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      sheets_api.SheetsApi.spreadsheetsScope,
      'https://www.googleapis.com/auth/photoslibrary'
    ],
  );
  final googleSheetsConfig = GoogleSheetsConfig();
  final PhotosService photo = PhotosService();
  GoogleSignInAccount? _user;
  String _message = '';
  bool _isLoading = false;
  List<List<dynamic>> _sheetData = [];
  List<gsheets.Worksheet> _worksheets = [];
  gsheets.Worksheet? _selectedWorksheet;
  gsheets.GSheets? _gsheets;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工作表清單'),
        leading: IconButton(
          icon: _user != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(_user!.photoUrl ?? ''),
                )
              : const Icon(Icons.person),
          onPressed: () {
            if (_user != null) {
              _showLogoutDialog();
            } else {
              _signIn();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              pickAndUploadFile();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initGoogleSheets();
  }

  pickAndUploadFile() async {
    setState(() {});
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      File file = File(result.files.single.path!);
      await PhotosService().uploadPhoto(file: file);

      setState(() {});
    }
  }

  // 構建主體UI
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedWorksheet != null) {
          await _loadWorksheetData(_selectedWorksheet!);
        } else {
          await _initGoogleSheets();
        }
      },
      child: Column(
        children: [
          if (_message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_message),
            ),
          Expanded(
            child: _worksheets.isEmpty
                ? _buildEmptyState()
                : _buildWorksheetList(),
          ),
          if (_selectedWorksheet != null && _sheetData.isNotEmpty)
            Expanded(
              child: _buildDataTable(),
            ),
        ],
      ),
    );
  }

  // 構建數據表格列
  List<DataColumn> _buildColumns() {
    if (_sheetData.isEmpty) return [];
    return _sheetData[0].map((header) {
      return DataColumn(
        label: Expanded(
          child: Text(
            header.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }).toList();
  }

  // 構建數據表格
  Widget _buildDataTable() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Scrollbar(
        controller: _horizontalScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: Scrollbar(
            controller: _verticalScrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: DataTable(
                columns: _buildColumns(),
                rows: _buildRows(),
                showCheckboxColumn: false,
                horizontalMargin: 24,
                columnSpacing: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 構建空狀態
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('無工作表'),
          if (_message.isNotEmpty) Text(_message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initGoogleSheets,
            child: const Text('重試'),
          ),
        ],
      ),
    );
  }

  // 構建數據表格行
  List<DataRow> _buildRows() {
    if (_sheetData.length <= 1) return [];
    return _sheetData.skip(1).map((row) {
      return DataRow(
        cells: row.map((cell) {
          return DataCell(
            Text(cell?.toString() ?? ''),
            onTap: () {
              // 可以添加單元格點擊處理
            },
          );
        }).toList(),
      );
    }).toList();
  }

  // 構建工作表列表
  Widget _buildWorksheetList() {
    return ListView.builder(
      itemCount: _worksheets.length,
      itemBuilder: (context, index) {
        final worksheet = _worksheets[index];
        final isSelected = worksheet == _selectedWorksheet;

        return Card(
          elevation: isSelected ? 4 : 1,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: isSelected ? Colors.blue.shade100 : null,
          child: ListTile(
            title: Text(worksheet.title ?? '未命名工作表'),
            subtitle: Text('ID: ${worksheet.id}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${worksheet.rowCount} 列 x ${worksheet.columnCount} 欄'),
                const Icon(Icons.arrow_forward_ios),
              ],
            ),
            onTap: () => _showWorksheetDetails(worksheet),
          ),
        );
      },
    );
  }

  // 檢查網絡連接
  // Future<bool> _checkInternetConnection() async {
  //   var connectivityResult = await Connectivity().checkConnectivity();
  //   return connectivityResult != ConnectivityResult.none;
  // }

  // 初始化 Google Sheets
  Future<void> _initGoogleSheets() async {
    try {
      setState(() {
        _isLoading = true;
        _message = '初始化中...';
      });

      // if (!await _checkInternetConnection()) {
      //   throw Exception('無網絡連接');
      // }

      final accountCredentials = ServiceAccountCredentials.fromJson(
          googleSheetsConfig.accountCredentials);

      final scopes = [sheets_api.SheetsApi.spreadsheetsScope];

      final client = await clientViaServiceAccount(accountCredentials, scopes)
          .timeout(const Duration(seconds: 10));

      _gsheets = gsheets.GSheets(client);
      final spreadsheet =
          await _gsheets!.spreadsheet(googleSheetsConfig.spreadsheetId);
      _worksheets = spreadsheet.sheets;

      setState(() => _message = '初始化成功，請選擇工作表');
    } on TimeoutException {
      setState(() => _message = '連接超時，請檢查網絡');
      _showRetryDialog();
    } on Exception catch (e) {
      setState(() => _message = '初始化失敗: ${e.toString()}');
      _showRetryDialog();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 加載工作表數據
  Future<void> _loadWorksheetData(gsheets.Worksheet worksheet) async {
    try {
      setState(() {
        _isLoading = true;
        _message = '讀取工作表數據中...';
      });

      final data = await worksheet.values.allRows();

      setState(() {
        _sheetData = data;
        _selectedWorksheet = worksheet;
        _message = '數據讀取成功';
      });
    } catch (e) {
      setState(() {
        _message = '讀取數據失敗: $e';
        _sheetData = [];
      });
      _showRetryDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 顯示登出確認對話框
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('登出確認'),
          content: const Text('確定要登出嗎？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('登出'),
              onPressed: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  // 重試對話框
  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('連接失敗'),
        content: const Text('是否要重試？'),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('重試'),
            onPressed: () {
              Navigator.pop(context);
              _initGoogleSheets();
            },
          ),
        ],
      ),
    );
  }

  // 顯示工作表詳情
  void _showWorksheetDetails(gsheets.Worksheet worksheet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(worksheet.title ?? '未命名工作表'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('工作表 ID: ${worksheet.id}'),
            Text('列數: ${worksheet.rowCount}'),
            Text('欄數: ${worksheet.columnCount}'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('取消'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('查看數據'),
            onPressed: () {
              Navigator.pop(context);
              _loadWorksheetData(worksheet);
            },
          ),
        ],
      ),
    );
  }

  // 登入處理
  Future<void> _signIn() async {
    try {
      setState(() {
        _isLoading = true;
        _message = '登入中...';
      });

      final account = await _googleSignIn.signIn();
      if (account != null) {
        setState(() {
          _user = account;
          _message = '登入成功';
        });
        await _initGoogleSheets(); // 重新初始化
      }
    } catch (e) {
      setState(() {
        _message = '登入失敗: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 登出處理
  Future<void> _signOut() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _googleSignIn.signOut();
      setState(() {
        _user = null;
        _selectedWorksheet = null;
        _sheetData = [];
        _message = '已登出';
      });
    } catch (e) {
      setState(() {
        _message = '登出失敗: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
