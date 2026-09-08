import 'package:flutter/material.dart';
import 'package:qatrah/core/constants/app_assets.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    this.imagePath,
    this.opacity = .2,
    super.key,
  });

  final Widget child;
  final String? imagePath;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : size.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : size.height;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    imagePath ?? AppAssets.splashBackgroundImg,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SafeArea(
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
