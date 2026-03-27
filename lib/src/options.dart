import 'enums.dart';

class CpclBarcodeOptions {
  const CpclBarcodeOptions({
    this.type = CpclBarcodeType.code128,
    this.narrow = 1,
    this.wide = 1,
    this.height = 100,
  });

  final CpclBarcodeType type;
  final int narrow;
  final int wide;
  final int height;
}

class CpclQrCodeOptions {
  const CpclQrCodeOptions({
    this.ecc = CpclQrErrorCorrection.medium,
    this.model = 2,
    this.unit = 6,
  });

  final CpclQrErrorCorrection ecc;
  final int model;
  final int unit;
}

class CpclLinePrintOptions {
  const CpclLinePrintOptions({
    this.font = CpclFont.font0,
    this.size = 0,
    this.unitWidth = 24,
    this.unitHeight = 24,
  });

  final CpclFont font;
  final int size;
  final int unitWidth;
  final int unitHeight;
}
