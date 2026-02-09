import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

/// 优化的缓存图片组件
class OptimizedCachedImage extends StatelessWidget {
  final String cacheKey;
  final Uint8List? imageBytes;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedCachedImage({
    Key? key,
    required this.cacheKey,
    this.imageBytes,
    this.width = 56,
    this.height = 56,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: ImageCacheService().loadImage(cacheKey, imageBytes),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? _buildPlaceholder();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return errorWidget ?? _buildErrorWidget(context);
        }

        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: fit,
          gaplessPlayback: true, // 优化图片切换
          filterQuality: FilterQuality.medium, // 平衡质量和性能
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.music_note,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
        size: width * 0.6,
      ),
    );
  }
}
