import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

class AppSvgWidget extends StatelessWidget {
  const AppSvgWidget({
    required this.assetsUrl,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String assetsUrl;
  final double? width;
  final double? height;
  final Color? color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return VectorGraphic(
      loader: AssetBytesLoader(assetsUrl),
      width: width ?? 30,
      height: height ?? 30,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      fit: fit,
    );
  }
}
