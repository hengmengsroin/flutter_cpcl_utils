/// Supported text rotations for CPCL text commands.
enum CpclRotation {
  angle0('TEXT'),
  angle90('TEXT90'),
  angle180('TEXT180'),
  angle270('TEXT270');

  const CpclRotation(this.textCommand);

  /// CPCL text command token for this rotation.
  final String textCommand;
}

/// Built-in CPCL bitmap/text font identifiers.
enum CpclFont {
  font0(0),
  font1(1),
  font2(2),
  font3(3),
  font4(4),
  font5(5),
  font6(6),
  font7(7);

  const CpclFont(this.value);

  /// Numeric font value expected by CPCL.
  final int value;
}

/// Barcode formats supported by `BARCODE` and `VBARCODE`.
enum CpclBarcodeType {
  code128('128'),
  code39('39'),
  ean13('EAN13'),
  ean8('EAN8'),
  upcA('UPCA'),
  upcE('UPCE'),
  codabar('CODABAR'),
  interleaved2of5('I2OF5');

  const CpclBarcodeType(this.value);

  /// CPCL barcode type token.
  final String value;
}

/// Error-correction levels for CPCL QR codes.
enum CpclQrErrorCorrection {
  low('L'),
  medium('M'),
  quartile('Q'),
  high('H');

  const CpclQrErrorCorrection(this.value);

  /// CPCL QR error correction token.
  final String value;
}

/// Country code values accepted by the CPCL `COUNTRY` command.
enum CpclCountryCode {
  usa('USA'),
  france('FRANCE'),
  germany('GERMANY'),
  uk('UK'),
  spain('SPAIN'),
  italy('ITALY'),
  sweden('SWEDEN'),
  norway('NORWAY');

  const CpclCountryCode(this.value);

  /// CPCL country token.
  final String value;
}

/// Common printer density presets in dots per inch (DPI).
enum CpclPrintDensity {
  d6(152),
  d8(203),
  d12(300),
  d24(600);

  const CpclPrintDensity(this.dpi);

  /// The dots-per-inch value represented by this preset.
  final int dpi;
}

/// Alignment presets for text rendered by line-print mode.
enum CpclAlignment { left, center, right }
