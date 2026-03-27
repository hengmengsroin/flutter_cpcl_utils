import 'package:flutter/painting.dart';

class CpclRenderedTextOptions {
  const CpclRenderedTextOptions({
    required this.style,
    this.maxWidth,
    this.textAlign = TextAlign.left,
    this.textDirection = TextDirection.ltr,
    this.padding = 0,
    this.pixelRatio = 3,
    this.threshold = 180,
    this.backgroundColor = const Color(0xFFFFFFFF),
  });

  final TextStyle style;
  final double? maxWidth;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final double padding;
  final double pixelRatio;
  final int threshold;
  final Color backgroundColor;
}
