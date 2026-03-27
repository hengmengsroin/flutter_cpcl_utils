import 'enums.dart';

class CpclTextStyle {
  const CpclTextStyle({
    this.font = CpclFont.font0,
    this.size = 0,
    this.rotation = CpclRotation.angle0,
    this.xMultiplier = 1,
    this.yMultiplier = 1,
  }) : assert(size >= 0),
       assert(xMultiplier >= 1 && xMultiplier <= 16),
       assert(yMultiplier >= 1 && yMultiplier <= 16);

  final CpclFont font;
  final int size;
  final CpclRotation rotation;
  final int xMultiplier;
  final int yMultiplier;

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
