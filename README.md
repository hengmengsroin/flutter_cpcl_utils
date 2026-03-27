# flutter_cpcl_utils

Utilities for generating CPCL printer commands from Flutter and Dart.

This package follows the same general shape as `flutter_tsc_utils`, but targets CPCL-compatible mobile and label printers.

## Features

- Chainable `CpclGenerator` API for building labels
- Label setup with `initialize()` and `PAGE-WIDTH`
- Text, lines, boxes, 1D barcodes, and QR codes
- Typed option objects for barcode, QR, and `SETLP` configuration
- Bitmap rasterization through `EG`
- Flutter-rendered `khmerText()` support for Khmer and other Unicode text that printer fonts do not handle well
- Raw command and raw byte hooks for unsupported CPCL features
- Input validation for common parameter ranges

## Usage

```dart
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

Future<void> main() async {
  final generator = CpclGenerator()
    ..initialize(const CpclLabelSize(576, 320))
    ..speed(3)
    ..tone(1)
    ..contrast(2)
    ..country(CpclCountryCode.usa)
    ..box(10, 10, 566, 310, thickness: 2)
    ..line(20, 60, 556, 60, thickness: 2)
    ..text(
      24,
      24,
      'SHIP TO',
      style: const CpclTextStyle(
        font: CpclFont.font4,
        xMultiplier: 2,
        yMultiplier: 2,
      ),
    )
    ..text(24, 76, 'Customer: John Doe')
    ..text(24, 106, 'Phone: 012 345 678')
    ..text(24, 136, 'Address: 123 Market Street')
    ..text(24, 166, 'Phnom Penh, Cambodia')
    ..inverseLine(22, 214, 340, 92)
    ..barcode(
      24,
      220,
      'PKG-2026-0001',
      options: const CpclBarcodeOptions(height: 80),
    )
    ..qrCode(
      390,
      76,
      'https://tracking.example.com/PKG-2026-0001',
      options: const CpclQrCodeOptions(
        ecc: CpclQrErrorCorrection.high,
        unit: 7,
      ),
    )
    ..form()
    ..print();

  final bytes = generator.build();
  // Send bytes over Bluetooth, USB, or TCP to the printer.
}
```

## Label Sizing

`CpclLabelSize(width, height)` uses printer dots, not millimeters.

Common starting points at 203 DPI:

- `const CpclLabelSize(384, 240)` for a 2 inch by 1.25 inch label
- `const CpclLabelSize(576, 320)` for roughly a 3 inch by 1.6 inch label
- `const CpclLabelSize(812, 1218)` for a 4 inch by 6 inch shipping label

If your printer uses a different DPI, scale the width and height accordingly.

## More Commands

The generator now also includes a few common CPCL control commands that are handy for real labels:

- `contrast()` for darkness tuning
- `country()` for locale-sensitive printer behavior
- `setLp()` for line-print text configuration
- `inverseLine()` for white-on-black highlight areas
- `verticalBarcode()` for rotated barcode layouts

## Khmer Text

For Khmer, the safest path is rendering text with Flutter and printing it as a bitmap:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

Future<void> printKhmer() async {
  final generator = CpclGenerator()
    ..initialize(const CpclLabelSize(576, 320));

  await generator.khmerText(
    20,
    20,
    'សួស្តី​ពិភពលោក',
    options: const CpclRenderedTextOptions(
      style: TextStyle(
        fontSize: 24,
        color: Color(0xFF000000),
        fontFamily: 'NotoSansKhmer',
      ),
      pixelRatio: 2,
      padding: 4,
    ),
  );

  generator
    ..form()
    ..print();
}
```

## Notes

- CPCL support varies a bit by printer model and firmware.
- Coordinates, widths, heights, and feed values in this package are expressed in printer dots.
- This package currently focuses on the most common building blocks and leaves escape hatches through `rawCommand()` and `rawBytes()`.
- `khmerText()` depends on a Khmer-capable Flutter font such as `NotoSansKhmer`.
- Text passed to `text()`, `barcode()`, and `qrCode()` is flattened to a single line because CPCL commands are line-oriented.
- This package is currently aimed at common Zebra-style CPCL command patterns and has not been validated against every vendor-specific CPCL dialect.
