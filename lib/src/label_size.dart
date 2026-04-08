/// Physical label dimensions in printer dots.
class CpclLabelSize {
  /// Creates a label size with [width] and [height] in dots.
  const CpclLabelSize(this.width, this.height);

  /// Label width in dots.
  final int width;

  /// Label height in dots.
  final int height;
}
