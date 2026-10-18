# flutter_cpcl_utils

Generate CPCL label commands from Flutter, build labels with either a fluent or declarative API, preview them locally in-app, and export preview images as PNG or PDF.

This package is aimed at CPCL-compatible mobile and label printers. It focuses on common label-building primitives while still leaving raw command escape hatches for printer-specific behavior.

## Why This Package

- Build CPCL labels with a familiar Dart API
- Choose between a fluent builder and a declarative `config + commands` style
- Preview declarative labels directly in Flutter during development
- Export preview output as PNG or PDF for QA, demos, or sharing
- Render any Flutter-supported script (Khmer, Thai, Arabic, CJK, etc.) or custom font as a bitmap

## Features

- `CpclGenerator` for CPCL command generation
- Declarative `CpclConfiguration` and typed commands like `CpclText`, `CpclBarcode`, and `CpclQrCode`
- Fluent methods for text, boxes, lines, barcodes, QR codes, and printer control commands
- `CpclPreview` widget for local live preview
- `CpclPreviewService` for PNG or PDF export
- Raw binary bitmap rasterization through standard CPCL `CG` (with `EG` available for ASCII-hex graphics)
- `renderedText()` and `CpclRenderedText` for Flutter-rendered Unicode text using the corrected bitmap path (with `khmerText()` and `CpclKhmerText` preserved as backward-compatible aliases)
- Raw command and raw byte hooks for unsupported features
- Input validation for common parameter ranges

## Quick Start

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

`CpclConfiguration` automatically writes the CPCL header, `PAGE-WIDTH`, `FORM`, and `PRINT` commands.

### Fluent Builder

```dart
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

Future<void> main() async {
  final generator = CpclGenerator()
    ..initialize(const CpclLabelSize(576, 320))
    ..speed(3)
    ..contrast(2)
    ..box(10, 10, 566, 310, thickness: 2)
    ..text(24, 24, 'SHIP TO')
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

## Live Preview

You can preview declarative labels directly inside Flutter:

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
          child: CpclPreview(
            generator: generator,
            enableInteraction: true,
            framePadding: const EdgeInsets.all(20),
            previewSurfaceColor: Color(0xFFF6F7F9),
            showCheckerboard: true,
          ),
        ),
      ),
    );
  }
}
```

`CpclPreview` keeps the rendered preview stable across ordinary rebuilds, supports pinch-to-zoom for larger labels, and can draw a subtle preview surface behind the label so white stock is easier to see.

Important:
- The preview is a local Flutter approximation of the declarative command list.
- It is not a printer-firmware-exact CPCL renderer.
- The preview currently targets the declarative `CpclConfiguration + commands` API.

## Preview Export

You can export the local preview to PNG or PDF bytes:

```dart
final response = await CpclPreviewService.renderFromGenerator(
  generator,
  outputFormat: CpclPreviewOutputFormat.pdf,
);

await File('label.pdf').writeAsBytes(response.data);
```

This is useful for QA snapshots, attachments, internal tooling, and sharing labels without printing.

## Rendered Text And Unicode Support

For scripts that printer hardware fonts do not natively support (such as Khmer, Thai, Arabic, Devanagari, or CJK) or for custom brand typography, you can render text with Flutter and print it as a monochrome bitmap:

```dart
import 'package:flutter/painting.dart';
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

Future<void> printRenderedText() async {
  final generator = CpclGenerator()
    ..initialize(const CpclLabelSize(576, 320));

  await generator.renderedText(
    20,
    20,
    'សួស្តី​ពិភពលោក / Hello World',
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

For declarative labels that include `CpclRenderedText` (or `CpclKhmerText`), use `buildAsync()` or `previewAsync()`:

```dart
final generator = CpclGenerator(
  config: const CpclConfiguration(printWidth: 406, labelLength: 203),
  commands: const [
    CpclRenderedText(
      x: 20,
      y: 20,
      text: 'សួស្តី​ពិភពលោក',
      options: CpclRenderedTextOptions(
        style: TextStyle(fontSize: 20, color: Color(0xFF000000)),
      ),
    ),
  ],
);

final bytes = await generator.buildAsync();
```

> **Backward Compatibility Note:** `khmerText()` and `CpclKhmerText` remain fully supported as wrappers/aliases around `renderedText()` and `CpclRenderedText`. See [`doc/rendered_text_compatibility.md`](doc/rendered_text_compatibility.md) for architectural details.

## Label Sizing

All measurements in this package use printer dots, not millimeters.

Common starting points at 203 DPI:

- `const CpclLabelSize(384, 240)` for a 2 inch by 1.25 inch label
- `const CpclLabelSize(576, 320)` for roughly a 3 inch by 1.6 inch label
- `const CpclLabelSize(812, 1218)` for a 4 inch by 6 inch shipping label

If your printer uses a different DPI, scale width and height accordingly.

## Supported Building Blocks

Common CPCL features available through the fluent and declarative APIs include:

- Text and rotated text
- Lines, boxes, and inverse blocks
- 1D barcodes and QR codes
- Printer controls such as `speed()`, `tone()`, `contrast()`, `country()`, and `setLinePrint()` (prefer `setLinePrint()` over deprecated `setLp()`)
- Bitmap printing (`bitmap()` / `compressedGraphics()` with `CG`, `expandedGraphics()` with `EG`)
- Flutter-rendered text (`renderedText()` / `CpclRenderedText`, `khmerText()` / `CpclKhmerText`)
- Raw commands and raw bytes

## Notes

- `inverseLine()` and `CpclInverseLine` describe a rectangle. The generator writes Zebra's `INVERSE-LINE x y (x+width) y height`, which inverts content drawn earlier in that rectangle.
- CPCL support varies by printer model and firmware.
- Text passed to `text()`, `barcode()`, and `qrCode()` is flattened to a single line because CPCL commands are line-oriented.
- This package focuses on common CPCL building blocks and leaves unsupported features to `rawCommand()` and `rawBytes()`.
- Rendered text depends on a font capable of displaying the requested script or characters (e.g., `NotoSansKhmer` for Khmer).
- The preview widget and export service are intended for development convenience, not printer-accurate certification.
