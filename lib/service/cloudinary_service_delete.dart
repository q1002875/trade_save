import 'package:trade_save/util/common_imports.dart';

class CloudinaryDeleteService {
  final String cloudName = dotenv.env['CLOUD_NAME'] ?? '';
  final String apiKey = dotenv.env['API_KEY'] ?? '';
  final String apiSecret = dotenv.env['API_SECRET'] ?? ''; // 需要添加API密钥
  final String uploadPreset = dotenv.env['UPLOAD_PRESET'] ?? '';

  /// 删除图片
  Future<bool> deleteImage(String url) async {
    try {
      // 从 URL 中提取 publicId
      String publicId = extractPublicId(url);

      // 创建 Cloudinary 实例
      final cloudinary = Cloudinary.full(
        apiKey: apiKey,
        apiSecret: apiSecret,
        cloudName: cloudName,
      );

      final response = await cloudinary.deleteResource(
        url: url,
        resourceType: CloudinaryResourceType.image,
        invalidate: false,
      );
      if (response.isSuccessful) {
        print("圖片刪除成功: $publicId");
        return true;
      } else {
        print("圖片刪除失敗:");
        return false;
      }
    } catch (e) {
      print("圖片刪除失敗: $e");
      return false;
    }
  }

  /// 提取 publicId
  String extractPublicId(String url) {
    // 去掉前缀和版本号
    var path = url.split('/').skip(6).join('/');
    // 去掉扩展名
    return path.substring(0, path.lastIndexOf('.'));
  }
}
