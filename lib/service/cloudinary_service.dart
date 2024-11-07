import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:trade_save/util/common_imports.dart';

class CloudinaryService {
  final String cloudName = dotenv.env['CLOUD_NAME'] ?? '';
  final String apiKey = dotenv.env['API_KEY'] ?? '';
  final String apiSecret = dotenv.env['API_SECRET'] ?? ''; // 需要添加API密钥
  final String uploadPreset = dotenv.env['UPLOAD_PRESET'] ?? '';

  /// 选择图片并上传到 Cloudinary，返回图片 URL
  Future<String?> uploadImage(XFile? file) async {
    if (file != null) {
      try {
        // 创建 Cloudinary 实例
        final cloudinary =
            CloudinaryPublic(cloudName, uploadPreset, cache: false);

        // 上传图片到 Cloudinary
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(file.path),
        );

        // 返回上传成功的图片 URL
        return response.secureUrl;
      } catch (e) {
        print("上傳失敗: $e");
        return null;
      }
    } else {
      print("未選擇圖片");
      return null;
    }
  }
}
