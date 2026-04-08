import 'package:flutter/painting.dart';

/// Rendering options used when drawing Flutter text into a bitmap.
class CpclRenderedTextOptions {
  /// Creates options for rasterized text rendering.
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

  /// Flutter text style used for rendering.
  final TextStyle style;

  /// Optional max layout width in logical pixels.
  final double? maxWidth;

  /// Text alignment used by the painter.
  final TextAlign textAlign;

  /// Text direction used by the painter.
  final TextDirection textDirection;

  /// Padding around rendered text in logical pixels.
  final double padding;

  /// Pixel ratio used during rasterization.
  final double pixelRatio;

  /// Threshold used when converting rendered text to monochrome.
  final int threshold;

  /// Background color used while rendering text.
  final Color backgroundColor;
}
