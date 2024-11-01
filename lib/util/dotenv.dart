import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleSheetsConfig {
  // 保存单例实例
  static final GoogleSheetsConfig _instance = GoogleSheetsConfig._internal();

  // 定义实例属性
  late final String _spreadsheetId;

  late final String _credentials;

  // 提供一个全局访问点
  factory GoogleSheetsConfig() => _instance;
  // 私有构造函数，确保外部无法直接创建对象
  GoogleSheetsConfig._internal() {
    _spreadsheetId = dotenv.env['SPREADSHEET_ID']!;
    _credentials = '''
    {
      "type": "${dotenv.env['GOOGLE_CLOUD_TYPE']}",
      "project_id": "${dotenv.env['GOOGLE_CLOUD_PROJECT_ID']}",
      "private_key_id": "${dotenv.env['GOOGLE_CLOUD_PRIVATE_KEY_ID']}",
      "private_key": "${dotenv.env['GOOGLE_CLOUD_PRIVATE_KEY']}",
      "client_email": "${dotenv.env['GOOGLE_CLOUD_CLIENT_EMAIL']}",
      "client_id": "${dotenv.env['GOOGLE_CLOUD_CLIENT_ID']}",
      "auth_uri": "${dotenv.env['GOOGLE_CLOUD_AUTH_URI']}",
      "token_uri": "${dotenv.env['GOOGLE_CLOUD_TOKEN_URI']}",
      "auth_provider_x509_cert_url": "${dotenv.env['GOOGLE_CLOUD_AUTH_PROVIDER_CERT_URL']}",
      "client_x509_cert_url": "${dotenv.env['GOOGLE_CLOUD_CLIENT_CERT_URL']}"
    }
    ''';
  }

  Map<String, dynamic> get accountCredentials {
    return jsonDecode(_credentials);
  }

  String get credentials => _credentials;
  // getter方法以提供对外访问
  String get spreadsheetId => _spreadsheetId;
}
