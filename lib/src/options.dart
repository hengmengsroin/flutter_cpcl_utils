import 'enums.dart';

/// Parameters for CPCL `BARCODE` and `VBARCODE` commands.
class CpclBarcodeOptions {
  /// Creates barcode rendering options.
  const CpclBarcodeOptions({
    this.type = CpclBarcodeType.code128,
    this.narrow = 1,
    this.wide = 1,
    this.height = 100,
  });

  /// Barcode symbology.
  final CpclBarcodeType type;

  /// Narrow bar width in dots.
  final int narrow;

  /// Wide bar width in dots.
  final int wide;

  /// Barcode height in dots.
  final int height;
}

/// Parameters for CPCL QR code generation.
class CpclQrCodeOptions {
  /// Creates QR code options.
  const CpclQrCodeOptions({
    this.ecc = CpclQrErrorCorrection.medium,
    this.model = 2,
    this.unit = 6,
  });

  /// Error correction level.
  final CpclQrErrorCorrection ecc;

  /// QR model number (usually 1 or 2).
  final int model;

  /// Module size in dots.
  final int unit;
}

/// Parameters for CPCL `SETLP` line-print mode.
class CpclLinePrintOptions {
  /// Creates line-print options.
  const CpclLinePrintOptions({
    this.font = CpclFont.font0,
    this.size = 0,
    this.unitWidth = 24,
    this.unitHeight = 24,
  });

  /// Font used by line-print mode.
  final CpclFont font;

  /// Font size variant.
  final int size;

  /// Character unit width in dots.
  final int unitWidth;

  /// Character unit height in dots.
  final int unitHeight;
}

/// Global printer and label configuration used by [CpclGenerator].
class CpclConfiguration {
  /// Creates a full CPCL label configuration.
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

  /// Printable width in dots.
  final int printWidth;

  /// Label length in dots.
  final int labelLength;

  /// Number of copies to print.
  final int copies;

  /// Top offset in dots.
  final int offset;

  /// Density preset used when explicit DPI is not provided.
  final CpclPrintDensity printDensity;

  /// Optional custom horizontal DPI.
  final int? horizontalDpi;

  /// Optional custom vertical DPI.
  final int? verticalDpi;

  /// Optional print speed (`0..5`).
  final int? speed;

  /// Optional tone (`0..3`).
  final int? tone;

  /// Optional contrast (`0..3`).
  final int? contrast;

  /// Optional country code for special character tables.
  final CpclCountryCode? country;

  /// Optional prefeed distance in dots.
  final int? prefeed;

  /// Optional postfeed distance in dots.
  final int? postfeed;

  /// Optional alignment mode.
  final CpclAlignment? alignment;

  /// Optional line-print configuration.
  final CpclLinePrintOptions? linePrintOptions;

  /// Whether `FORM` is automatically appended.
  final bool autoForm;

  /// Whether `PRINT` is automatically appended.
  final bool autoPrint;

  /// Effective horizontal DPI.
  int get resolvedHorizontalDpi => horizontalDpi ?? printDensity.dpi;

  /// Effective vertical DPI.
  int get resolvedVerticalDpi => verticalDpi ?? printDensity.dpi;
}
