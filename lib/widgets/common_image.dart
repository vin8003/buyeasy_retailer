import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/web_image_stub.dart'
    if (dart.library.html) '../utils/web_image_web.dart';

class CommonImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const CommonImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final formattedUrl = ApiService().formatImageUrl(imageUrl);
    if (kIsWeb) {
      final String viewId = 'img-${formattedUrl.hashCode}';
      registerWebImage(formattedUrl, viewId);

      return SizedBox(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        child: HtmlElementView(viewType: viewId),
      );
    }

    return CachedNetworkImage(
      imageUrl: formattedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      errorWidget: (context, url, error) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
      progressIndicatorBuilder: (context, url, downloadProgress) => Center(
        child: CircularProgressIndicator(value: downloadProgress.progress),
      ),
    );
  }
}
