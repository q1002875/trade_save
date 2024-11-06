import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'common_imports.dart';

class GooglePhotosConfig {
  final String uploadEndpoint =
      'https://photoslibrary.googleapis.com/v1/uploads';
  final String batchCreateEndpoint =
      'https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate';
  final List<String> scopes = ['https://www.googleapis.com/auth/photoslibrary'];
}

class PhotosService {
  final GoogleSheetsConfig _sheetsConfig;
  final GooglePhotosConfig _photosConfig;
  AuthClient? _authClient;

  PhotosService({
    GoogleSheetsConfig? sheetsConfig,
    GooglePhotosConfig? photosConfig,
  })  : _sheetsConfig = sheetsConfig ?? GoogleSheetsConfig(),
        _photosConfig = photosConfig ?? GooglePhotosConfig();

  Future<AuthClient> get _client async {
    if (_authClient != null) return _authClient!;

    try {
      _authClient = await _authenticateClient();
      return _authClient!;
    } catch (e) {
      throw PhotoUploadException('Failed to authenticate client', e);
    }
  }

  Future<PhotoUploadResult> uploadPhoto({
    required File file,
    String? description,
    String? fileName,
  }) async {
    try {
      // 获取上传令牌
      final uploadToken = await _getUploadToken(file);

      // 创建媒体项
      final response = await _createMediaItem(
        uploadToken: uploadToken,
        description: description ?? 'Uploaded via Flutter app',
        fileName: fileName ??
            'flutter-photos-upload-${DateTime.now().millisecondsSinceEpoch}',
      );

      // 解析响应
      final responseData = jsonDecode(response.body);
      final newMediaItem = responseData['newMediaItems']?[0];

      if (newMediaItem == null) {
        throw PhotoUploadException(
            'Failed to create media item: Empty response');
      }

      if (newMediaItem['status']?['message'] != 'Success') {
        throw PhotoUploadException(
            'Upload failed: ${newMediaItem['status']?['message'] ?? 'Unknown error'}');
      }

      return PhotoUploadResult.success(
        mediaItemId: newMediaItem['mediaItem']['id'],
        productUrl: newMediaItem['mediaItem']['productUrl'],
      );
    } catch (e) {
      return PhotoUploadResult.failure(e.toString());
    }
  }

  Future<AuthClient> _authenticateClient() async {
    try {
      return await clientViaUserConsent(
        ClientId(_sheetsConfig.clienId), // 确保是 clientId 而不是 clienId
        _photosConfig.scopes,
        _promptUserForConsent,
      );
    } catch (e) {
      throw PhotoUploadException('Authentication failed', e);
    }
  }

  Future<http.Response> _createMediaItem({
    required String uploadToken,
    required String description,
    required String fileName,
  }) async {
    final client = await _client;

    final response = await client.post(
      Uri.parse(_photosConfig.batchCreateEndpoint),
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({
        "newMediaItems": [
          {
            "description": description,
            "simpleMediaItem": {
              "fileName": fileName,
              "uploadToken": uploadToken,
            }
          }
        ]
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw PhotoUploadException(
        'Failed to create media item. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }

    return response;
  }

  String _getContentType(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg'; // 默认处理为 JPEG
    }
  }

  Future<String> _getUploadToken(File file) async {
    final client = await _client;

    final response = await client.post(
      Uri.parse(_photosConfig.uploadEndpoint),
      headers: {
        'Content-type': 'application/octet-stream',
        'X-Goog-Upload-Content-Type': _getContentType(file),
        'X-Goog-Upload-Protocol': 'raw'
      },
      body: await file.readAsBytes(),
    );

    if (response.statusCode != 200) {
      throw PhotoUploadException(
        'Failed to get upload token. Status: ${response.statusCode}, Body: ${response.body}',
      );
    }

    return response.body;
  }

  Future<void> _promptUserForConsent(String url) async {
    print('Launching URL for consent: $url');
    try {
      final uri = Uri.parse(url);
      // 这里添加任何必要的关闭或返回逻辑
      await Future.delayed(const Duration(milliseconds: 100));
      if (await canLaunchUrl(uri)) {
        // 确保在适当的视图层级中调用
        await launchUrl(uri,
            mode: LaunchMode.externalApplication); // 使用外部应用程序模式
      } else {
        throw PhotoUploadException('Cannot launch authorization URL: $url');
      }
    } catch (e) {
      throw PhotoUploadException('Failed to launch authorization URL', e);
    }
  }
}

class PhotoUploadException implements Exception {
  final String message;
  final dynamic error;

  PhotoUploadException(this.message, [this.error]);

  @override
  String toString() =>
      'PhotoUploadException: $message${error != null ? '\nError: $error' : ''}';
}

class PhotoUploadResult {
  final bool success;
  final String? mediaItemId;
  final String? productUrl;
  final String? error;

  PhotoUploadResult({
    required this.success,
    this.mediaItemId,
    this.productUrl,
    this.error,
  });

  factory PhotoUploadResult.failure(String error) {
    return PhotoUploadResult(
      success: false,
      error: error,
    );
  }

  factory PhotoUploadResult.success({
    required String mediaItemId,
    required String productUrl,
  }) {
    return PhotoUploadResult(
      success: true,
      mediaItemId: mediaItemId,
      productUrl: productUrl,
    );
  }
}
