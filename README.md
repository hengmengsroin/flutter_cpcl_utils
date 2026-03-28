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

### Declarative Generator

```dart
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

Future<void> main() async {
  final generator = CpclGenerator(
    config: const CpclConfiguration(
      printWidth: 406,
      labelLength: 203,
      printDensity: CpclPrintDensity.d8,
    ),
    commands: const [
      CpclText(x: 20, y: 20, text: 'Hello World!'),
      CpclBarcode(
        x: 20,
        y: 60,
        data: '12345',
        options: CpclBarcodeOptions(height: 50),
      ),
    ],
  );

  final bytes = await generator.buildAsync();
  // Send bytes over Bluetooth, USB, or TCP to the printer.
}
```

`CpclConfiguration` automatically writes the CPCL header, `PAGE-WIDTH`, `FORM`, and `PRINT` commands for you.

### Live Preview Widget

For declarative labels, you can render a live Flutter preview locally:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

class LabelPreviewScreen extends StatelessWidget {
  LabelPreviewScreen({super.key});

  final generator = CpclGenerator(
    config: const CpclConfiguration(
      printWidth: 406,
      labelLength: 203,
      printDensity: CpclPrintDensity.d8,
    ),
    commands: const [
      CpclText(x: 20, y: 20, text: 'Hello World!'),
      CpclBarcode(
        x: 20,
        y: 60,
        data: '12345',
        options: CpclBarcodeOptions(height: 50),
      ),
      CpclQrCode(x: 290, y: 50, data: 'https://example.com'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CpclPreview(generator: generator),
        ),
      ),
    );
  }
}
```

`CpclPreview` re-renders whenever the widget rebuilds. It currently targets the declarative `config + commands` API, which gives the previewer a structured layout model to paint.

### Preview Export

You can also render the preview to PNG or PDF bytes without showing the widget:

```dart
final response = await CpclPreviewService.renderFromGenerator(
  generator,
  outputFormat: CpclPreviewOutputFormat.pdf,
);

await File('label.pdf').writeAsBytes(response.data);
```

### Fluent Builder

If you prefer the existing chainable style, it still works:

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
    ..barcode(
      24,
      220,
      'PKG-2026-0001',
      options: const CpclBarcodeOptions(height: 80),
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

The generator includes both fluent methods and declarative command objects for common CPCL features:

- `contrast()` for darkness tuning
- `country()` for locale-sensitive printer behavior
- `setLp()` for line-print text configuration
- `inverseLine()` for white-on-black highlight areas
- `verticalBarcode()` for rotated barcode layouts
- `CpclText`, `CpclBarcode`, `CpclQrCode`, `CpclLine`, `CpclBox`, and `CpclKhmerText` for config-driven labels
- `CpclPreview` and `CpclPreviewService` for local preview and export

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

For declarative labels that include `CpclKhmerText`, call `buildAsync()` or `previewAsync()` because Flutter text rendering happens asynchronously.

## Notes

- CPCL support varies a bit by printer model and firmware.
- Coordinates, widths, heights, and feed values in this package are expressed in printer dots.
- This package currently focuses on the most common building blocks and leaves escape hatches through `rawCommand()` and `rawBytes()`.
- `khmerText()` depends on a Khmer-capable Flutter font such as `NotoSansKhmer`.
- Text passed to `text()`, `barcode()`, and `qrCode()` is flattened to a single line because CPCL commands are line-oriented.
- This package is currently aimed at common Zebra-style CPCL command patterns and has not been validated against every vendor-specific CPCL dialect.
- The preview widget is a local approximation of the declarative command list, not a printer-firmware-exact rasterizer.
