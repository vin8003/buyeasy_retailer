import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

void registerWebImage(String imageUrl, String viewId) {
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final img = html.ImageElement()
      ..src = imageUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.border = 'none';
    return img;
  });
}
