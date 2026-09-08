import 'package:flutter/material.dart';

class CurvedAppBarShape extends ContinuousRectangleBorder {
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = Path();
    const curveHeight = 30.0;

    path
      ..lineTo(0, rect.height)
      ..quadraticBezierTo(
        rect.width / 2,
        rect.height + curveHeight,
        rect.width,
        rect.height,
      )
      ..lineTo(rect.width, 0)
      ..close();

    return path;
  }
}
