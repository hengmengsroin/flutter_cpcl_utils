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

/// Standard CPCL ratio codes defining the wide-to-narrow bar relationship.
///
/// In Zebra CPCL, the ratio parameter specifies discrete wide-to-narrow bar ratio codes:
/// - Codes `0` through `4`:
///   - `0`: 1.5:1 ratio
///   - `1`: 2.0:1 ratio
///   - `2`: 2.5:1 ratio
///   - `3`: 3.0:1 ratio
///   - `4`: 3.5:1 ratio
/// - Codes `20` through `30`:
///   - `20`: 2.0:1 ratio (extended format)
///   - `21`: 2.1:1 ratio
///   - `22`: 2.2:1 ratio
///   - `23`: 2.3:1 ratio
///   - `24`: 2.4:1 ratio
///   - `25`: 2.5:1 ratio
///   - `26`: 2.6:1 ratio
///   - `27`: 2.7:1 ratio
///   - `28`: 2.8:1 ratio
///   - `29`: 2.9:1 ratio
///   - `30`: 3.0:1 ratio
class CpclBarcodeRatio {
  /// Creates a validated CPCL barcode ratio code.
  const CpclBarcodeRatio(this.code)
    : assert(
        (code >= 0 && code <= 4) || (code >= 20 && code <= 30),
        'Valid CPCL barcode ratio codes are 0..4 and 20..30. Got: $code',
      );

  /// Creates and validates a CPCL ratio code from an integer value.
  factory CpclBarcodeRatio.code(int value) {
    validateCode(value);
    return CpclBarcodeRatio(value);
  }

  /// Numeric ratio code value expected by CPCL.
  final int code;

  /// Returns true if [value] is a documented, protocol-valid CPCL ratio code.
  static bool isValidCode(int value) =>
      (value >= 0 && value <= 4) || (value >= 20 && value <= 30);

  /// Validates that [value] is within valid CPCL ratio sets (`0..4` or `20..30`).
  ///
  /// Throws [RangeError] if invalid.
  static void validateCode(int value) {
    if (!isValidCode(value)) {
      throw RangeError.range(
        value,
        0,
        30,
        'ratio',
        'Valid CPCL barcode ratio codes are 0..4 and 20..30. Got: $value',
      );
    }
  }

  /// 1.5:1 ratio (ratio code 0).
  static const CpclBarcodeRatio ratio1_5 = CpclBarcodeRatio(0);

  /// 2.0:1 ratio (ratio code 1).
  static const CpclBarcodeRatio ratio2_0 = CpclBarcodeRatio(1);

  /// 2.5:1 ratio (ratio code 2).
  static const CpclBarcodeRatio ratio2_5 = CpclBarcodeRatio(2);

  /// 3.0:1 ratio (ratio code 3).
  static const CpclBarcodeRatio ratio3_0 = CpclBarcodeRatio(3);

  /// 3.5:1 ratio (ratio code 4).
  static const CpclBarcodeRatio ratio3_5 = CpclBarcodeRatio(4);

  /// 2.0:1 ratio alternate (ratio code 20).
  static const CpclBarcodeRatio ratio20 = CpclBarcodeRatio(20);

  /// 2.1:1 ratio (ratio code 21).
  static const CpclBarcodeRatio ratio21 = CpclBarcodeRatio(21);

  /// 2.2:1 ratio (ratio code 22).
  static const CpclBarcodeRatio ratio22 = CpclBarcodeRatio(22);

  /// 2.3:1 ratio (ratio code 23).
  static const CpclBarcodeRatio ratio23 = CpclBarcodeRatio(23);

  /// 2.4:1 ratio (ratio code 24).
  static const CpclBarcodeRatio ratio24 = CpclBarcodeRatio(24);

  /// 2.5:1 ratio alternate (ratio code 25).
  static const CpclBarcodeRatio ratio25 = CpclBarcodeRatio(25);

  /// 2.6:1 ratio (ratio code 26).
  static const CpclBarcodeRatio ratio26 = CpclBarcodeRatio(26);

  /// 2.7:1 ratio (ratio code 27).
  static const CpclBarcodeRatio ratio27 = CpclBarcodeRatio(27);

  /// 2.8:1 ratio (ratio code 28).
  static const CpclBarcodeRatio ratio28 = CpclBarcodeRatio(28);

  /// 2.9:1 ratio (ratio code 29).
  static const CpclBarcodeRatio ratio29 = CpclBarcodeRatio(29);

  /// 3.0:1 ratio alternate (ratio code 30).
  static const CpclBarcodeRatio ratio30 = CpclBarcodeRatio(30);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CpclBarcodeRatio &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CpclBarcodeRatio($code)';
}
