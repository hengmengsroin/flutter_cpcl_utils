import 'enums.dart';

/// Text styling options for CPCL `TEXT` commands.
class CpclTextStyle {
  /// Creates a CPCL text style.
  const CpclTextStyle({
    this.font = CpclFont.font0,
    this.size = 0,
    this.rotation = CpclRotation.angle0,
    this.xMultiplier = 1,
    this.yMultiplier = 1,
  }) : assert(size >= 0),
       assert(xMultiplier >= 1 && xMultiplier <= 16),
       assert(yMultiplier >= 1 && yMultiplier <= 16);

  /// CPCL font family.
  final CpclFont font;

  /// Font size variant (non-negative).
  final int size;

  /// Text rotation.
  final CpclRotation rotation;

  /// Horizontal magnification multiplier (1 to 16).
  final int xMultiplier;

  /// Vertical magnification multiplier (1 to 16).
  final int yMultiplier;

  /// Returns a copy with selectively replaced properties.
  CpclTextStyle copyWith({
    CpclFont? font,
    int? size,
    CpclRotation? rotation,
    int? xMultiplier,
    int? yMultiplier,
  }) {
    return CpclTextStyle(
      font: font ?? this.font,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      xMultiplier: xMultiplier ?? this.xMultiplier,
      yMultiplier: yMultiplier ?? this.yMultiplier,
    );
  }
}
