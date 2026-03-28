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

class CpclConfiguration {
  const CpclConfiguration({
    required this.printWidth,
    required this.labelLength,
    this.copies = 1,
    this.offset = 0,
    this.printDensity = CpclPrintDensity.d8,
    this.horizontalDpi,
    this.verticalDpi,
    this.speed,
    this.tone,
    this.contrast,
    this.country,
    this.prefeed,
    this.postfeed,
    this.alignment,
    this.linePrintOptions,
    this.autoForm = true,
    this.autoPrint = true,
  });

  final int printWidth;
  final int labelLength;
  final int copies;
  final int offset;
  final CpclPrintDensity printDensity;
  final int? horizontalDpi;
  final int? verticalDpi;
  final int? speed;
  final int? tone;
  final int? contrast;
  final CpclCountryCode? country;
  final int? prefeed;
  final int? postfeed;
  final CpclAlignment? alignment;
  final CpclLinePrintOptions? linePrintOptions;
  final bool autoForm;
  final bool autoPrint;

  int get resolvedHorizontalDpi => horizontalDpi ?? printDensity.dpi;

  int get resolvedVerticalDpi => verticalDpi ?? printDensity.dpi;
}
