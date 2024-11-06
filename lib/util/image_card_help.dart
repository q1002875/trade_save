import 'package:flutter/material.dart';

class ImageCardHelper {
  // 构建图片卡片
  static Widget buildImageCard(BuildContext context, String? imageUrl) {
    return _DynamicAspectRatioImageCard(imageUrl: imageUrl);
  }

  // 显示大图对话框
  static void showLargeImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.fill,
                      width: double.maxFinite,
                      height: 500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭弹窗
                  },
                  child: const Text('關閉'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class __DynamicAspectRatioImageCardState
    extends State<_DynamicAspectRatioImageCard> {
  double? _aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '圖表記錄',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // 如果 imageUrl 不为空，显示图片，否则显示占位符
            widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      ImageCardHelper.showLargeImageDialog(
                          context, widget.imageUrl!);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _aspectRatio != null
                          ? AspectRatio(
                              aspectRatio: _aspectRatio!,
                              child: Image.network(
                                widget.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator()), // 加载中的占位符
                    ),
                  )
                : const SizedBox() // 如果没有图片，显示空的占位符
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _calculateAspectRatio();
    }
  }

  // 计算图片宽高比
  void _calculateAspectRatio() {
    final Image image = Image.network(widget.imageUrl!);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        final int width = info.image.width;
        final int height = info.image.height;
        setState(() {
          _aspectRatio = width / height;
        });
      }),
    );
  }
}

// 内部封装一个有状态组件来动态获取宽高比
class _DynamicAspectRatioImageCard extends StatefulWidget {
  final String? imageUrl;
  const _DynamicAspectRatioImageCard({super.key, required this.imageUrl});

  @override
  __DynamicAspectRatioImageCardState createState() =>
      __DynamicAspectRatioImageCardState();
}
