import 'enums.dart';

/// Parameters for CPCL `BARCODE` and `VBARCODE` commands.
class CpclBarcodeOptions {
  /// Creates barcode rendering options.
  ///
  /// [width] is the unit-width of the narrow bar in dots (`0..65535`).
  /// [ratio] is the CPCL wide-to-narrow bar ratio code (`0..4` or `20..30`).
  /// [height] is the barcode unit height in dots (`0..65535`).
  ///
  /// Note on alias precedence: If both canonical and deprecated parameters are
  /// supplied (e.g. both [width] and [narrow], or both [ratio] and [wide]),
  /// the canonical parameter ([width] or [ratio]) takes precedence.
  ///
  /// Note: While some symbologies (such as Code 128) ignore ratio during
  /// rendering, Zebra CPCL requires the ratio parameter in the command syntax,
  /// and invalid ratio codes may cause printers to reject the command.
  const CpclBarcodeOptions({
    this.type = CpclBarcodeType.code128,
    int? width,
    int? ratio,
    this.height = 100,
    @Deprecated('Use width instead.') int? narrow,
    @Deprecated('Use ratio instead.') int? wide,
  }) : width = width ?? narrow ?? 1,
       ratio = ratio ?? wide ?? 1;

  /// Barcode symbology.
  final CpclBarcodeType type;

  /// Narrow bar unit-width in dots (`0..65535`).
  final int width;

  /// Ratio of wide bar to narrow bar (Zebra ratio code: `0..4` or `20..30`).
  final int ratio;

  /// Barcode height in dots.
  final int height;

  /// Deprecated backward-compatible alias for [width].
  @Deprecated('Use width instead.')
  int get narrow => width;

  /// Deprecated backward-compatible alias for [ratio].
  @Deprecated('Use ratio instead.')
  int get wide => ratio;
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

/// Parameters for CPCL `SETLP` line-print mode using resident fonts.
///
/// Generates: `SETLP <font> <size> <lineSpacing>`
class CpclLinePrintOptions {
  /// Creates line-print options for resident fonts.
  const CpclLinePrintOptions({
    this.font = CpclFont.font0,
    this.size = 0,
    int? lineSpacing,
    @Deprecated(
      'unitWidth is not part of resident SETLP syntax; use lineSpacing.',
    )
    this.unitWidth = 24,
    @Deprecated('Use lineSpacing instead.') int? unitHeight,
  }) : lineSpacing = lineSpacing ?? unitHeight ?? 24;

  /// Font used by line-print mode.
  final CpclFont font;

  /// Font size variant.
  final int size;

  /// Line spacing / vertical advance in dots on CR/LF.
  final int lineSpacing;

  /// Deprecated parameter retained for source compatibility. Ignored in output.
  @Deprecated('unitWidth is not part of resident SETLP syntax.')
  final int unitWidth;

  /// Deprecated alias for [lineSpacing].
  @Deprecated('Use lineSpacing instead.')
  int get unitHeight => lineSpacing;

  /// Formats the arguments following `SETLP`.
  String formatArguments() => '${font.value} $size $lineSpacing';
}

/// Explicit type alias for resident font line-print options.
typedef CpclResidentLinePrintOptions = CpclLinePrintOptions;

/// Parameters for CPCL `SETLP` line-print mode using TrueType fonts.
///
/// Generates: `SETLP <fontName> <xScale> <yScale> <lineSpacing>`
class CpclTrueTypeLinePrintOptions extends CpclLinePrintOptions {
  /// Creates line-print options for TrueType fonts.
  const CpclTrueTypeLinePrintOptions({
    required this.fontName,
    this.xScale = 1,
    this.yScale = 1,
    super.lineSpacing = 24,
  }) : super(font: CpclFont.font0, size: 0);

  /// TrueType font name stored on the printer.
  final String fontName;

  /// Horizontal scale factor.
  final int xScale;

  /// Vertical scale factor.
  final int yScale;

  @override
  String formatArguments() => '$fontName $xScale $yScale $lineSpacing';
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

  /// Horizontal offset in dots.
  ///
  /// This is the first field of the CPCL `!` header. It shifts the whole
  /// label to the right. It is not a vertical offset.
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
