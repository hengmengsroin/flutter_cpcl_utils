# flutter_cpcl_utils

Utilities for generating CPCL printer commands from Flutter and Dart.

This package follows the same general shape as `flutter_tsc_utils`, but targets CPCL-compatible mobile and label printers.

## Features

- Chainable `CpclGenerator` API for building labels
- Label setup with `initialize()` and `PAGE-WIDTH`
- Text, lines, boxes, 1D barcodes, and QR codes
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
    ..text(20, 30, 'Hello CPCL')
    ..barcode(20, 90, '1234567890')
    ..qrCode(20, 210, 'https://example.com')
    ..form()
    ..print();

  final bytes = generator.build();
  // Send bytes over Bluetooth, USB, or TCP to the printer.
}
```

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
- This package currently focuses on the most common building blocks and leaves escape hatches through `rawCommand()` and `rawBytes()`.
- `khmerText()` depends on a Khmer-capable Flutter font such as `NotoSansKhmer`.
