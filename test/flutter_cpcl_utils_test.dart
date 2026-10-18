import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds common CPCL commands with chainable API', () {
    final generator = CpclGenerator()
      ..initialize(const CpclLabelSize(576, 320))
      ..speed(3)
      ..tone(1)
      ..contrast(2)
      ..text(20, 30, 'Hello CPCL')
      ..line(20, 70, 200, 70, thickness: 2)
      ..barcode(20, 90, '1234567890')
      ..qrCode(20, 210, 'https://example.com')
      ..form()
      ..print();

    expect(
      generator.preview(),
      '! 0 203 203 320 1\r\n'
      'PAGE-WIDTH 576\r\n'
      'SPEED 3\r\n'
      'TONE 1\r\n'
      'CONTRAST 2\r\n'
      'TEXT 0 0 20 30 Hello CPCL\r\n'
      'LINE 20 70 200 70 2\r\n'
      'BARCODE 128 1 1 100 20 90 1234567890\r\n'
      'B QR 20 210 M 2 U 6\r\n'
      'MA,https://example.com\r\n'
      'ENDQR\r\n'
      'FORM\r\n'
      'PRINT\r\n',
    );
  });

  test('initialize defaults to 203 dpi and accepts an explicit resolution', () {
    final standard = CpclGenerator()..initialize(const CpclLabelSize(100, 50));
    expect(
      standard.preview(),
      startsWith('! 0 203 203 50 1\r\nPAGE-WIDTH 100\r\n'),
    );

    final explicit = CpclGenerator()
      ..initialize(
        const CpclLabelSize(100, 50),
        horizontalDpi: 200,
        verticalDpi: 200,
      );
    expect(explicit.preview(), startsWith('! 0 200 200 50 1\r\n'));
  });

  test('builds CPCL commands with declarative config and command list', () {
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

    expect(
      generator.preview(),
      '! 0 203 203 203 1\r\n'
      'PAGE-WIDTH 406\r\n'
      'TEXT 0 0 20 20 Hello World!\r\n'
      'BARCODE 128 1 1 50 20 60 12345\r\n'
      'FORM\r\n'
      'PRINT\r\n',
    );
  });

  test('supports text rotation, magnification, and layout commands', () {
    final generator = CpclGenerator()
      ..country(CpclCountryCode.usa)
      ..center()
      ..setLp(const CpclLinePrintOptions(font: CpclFont.font2, size: 1))
      ..text(
        10,
        12,
        'Scaled',
        style: const CpclTextStyle(
          font: CpclFont.font4,
          size: 2,
          rotation: CpclRotation.angle90,
          xMultiplier: 2,
          yMultiplier: 3,
        ),
      )
      ..left()
      ..box(5, 6, 30, 40, thickness: 3)
      ..inverseLine(8, 9, 10, 11)
      ..prefeed(24)
      ..postfeed(48);

    expect(
      generator.preview(),
      'COUNTRY USA\r\n'
      'CENTER\r\n'
      '! U1 SETLP 2 1 24\r\n'
      'SETMAG 2 3\r\n'
      'TEXT90 4 2 10 12 Scaled\r\n'
      'SETMAG 0 0\r\n'
      'LEFT\r\n'
      'BOX 5 6 30 40 3\r\n'
      'INVERSE-LINE 8 9 18 9 11\r\n'
      'PREFEED 24\r\n'
      'POSTFEED 48\r\n',
    );
  });

  test('sanitizes line breaks in text, barcode, and QR payloads', () {
    final generator = CpclGenerator()
      ..text(10, 12, 'Line 1\nLine 2')
      ..barcode(20, 40, 'ABC\r\n123')
      ..qrCode(30, 60, 'https://example.com/\npath');

    expect(
      generator.preview(),
      'TEXT 0 0 10 12 Line 1 Line 2\r\n'
      'BARCODE 128 1 1 100 20 40 ABC 123\r\n'
      'B QR 30 60 M 2 U 6\r\n'
      'MA,https://example.com/ path\r\n'
      'ENDQR\r\n',
    );
  });

  test('supports typed barcode and qr options including vertical barcode', () {
    final generator = CpclGenerator()
      ..barcode(
        24,
        40,
        'ABC123',
        options: const CpclBarcodeOptions(
          type: CpclBarcodeType.code39,
          narrow: 2,
          wide: 3,
          height: 88,
        ),
      )
      ..verticalBarcode(
        180,
        20,
        'ZX-9',
        options: const CpclBarcodeOptions(
          type: CpclBarcodeType.codabar,
          narrow: 1,
          wide: 2,
          height: 70,
        ),
      )
      ..qrCode(
        30,
        60,
        'payload',
        options: const CpclQrCodeOptions(
          ecc: CpclQrErrorCorrection.high,
          model: 1,
          unit: 8,
        ),
      );

    expect(
      generator.preview(),
      'BARCODE 39 2 3 88 24 40 ABC123\r\n'
      'VBARCODE CODABAR 1 2 70 180 20 ZX-9\r\n'
      'B QR 30 60 M 1 U 8\r\n'
      'HA,payload\r\n'
      'ENDQR\r\n',
    );
  });

  test('supports a richer shipping-label style command sequence', () {
    final generator = CpclGenerator()
      ..initialize(const CpclLabelSize(576, 320))
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

    expect(
      generator.preview(),
      '! 0 203 203 320 1\r\n'
      'PAGE-WIDTH 576\r\n'
      'BOX 10 10 566 310 2\r\n'
      'LINE 20 60 556 60 2\r\n'
      'SETMAG 2 2\r\n'
      'TEXT 4 0 24 24 SHIP TO\r\n'
      'SETMAG 0 0\r\n'
      'TEXT 0 0 24 76 Customer: John Doe\r\n'
      'BARCODE 128 1 1 80 24 220 PKG-2026-0001\r\n'
      'FORM\r\n'
      'PRINT\r\n',
    );
  });

  test('bitmap rasterization emits expected bytes', () {
    final image = img.Image(width: 8, height: 1);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    image.setPixelRgb(0, 0, 0, 0, 0);
    image.setPixelRgb(1, 0, 0, 0, 0);

    final generator = CpclGenerator()..bitmap(10, 20, image);
    final bytes = generator.build();

    expect(
      latin1.decode(bytes.sublist(0, 'CG 1 1 10 20 '.length)),
      'CG 1 1 10 20 ',
    );
    expect(bytes['CG 1 1 10 20 '.length], 0xC0);
    expect(latin1.decode(bytes.sublist(bytes.length - 2)), '\r\n');
  });

  test('transparent pixels stay unprinted when rasterized', () {
    final image = img.Image(width: 8, height: 1, numChannels: 4);
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
    image.setPixelRgba(0, 0, 0, 0, 0, 255);
    image.setPixelRgba(2, 0, 0, 0, 0, 255);

    final generator = CpclGenerator()..bitmap(0, 0, image);
    final bytes = generator.build();
    final pixelByte = bytes['CG 1 1 0 0 '.length];

    // Bits 7 and 5 are the opaque black dots. The transparent black pixels
    // around them must not set a bit.
    expect(pixelByte, 0xA0);
  });

  test('preview thresholds bitmaps to printed black and white', () async {
    final image = img.Image(width: 2, height: 1, numChannels: 3);
    image.setPixelRgb(0, 0, 180, 255, 180);
    image.setPixelRgb(1, 0, 120, 0, 0);

    Future<img.Image> render(int threshold) async {
      final generator = CpclGenerator(
        config: const CpclConfiguration(
          printWidth: 8,
          labelLength: 4,
          autoForm: false,
          autoPrint: false,
        ),
        commands: [CpclBitmap(x: 1, y: 1, image: image, threshold: threshold)],
      );
      final png = await CpclPreviewService.renderPngFromGenerator(
        generator,
        pixelRatio: 1,
      );
      return img.decodePng(png)!;
    }

    final atDefault = await render(127);
    // Light green is above the threshold, so the printer leaves it white.
    expect(_isLight(atDefault.getPixel(1, 1)), isTrue);
    // Dark red is below the threshold, so it prints as black rather than red.
    expect(_isBlack(atDefault.getPixel(2, 1)), isTrue);

    final darker = await render(250);
    expect(_isBlack(darker.getPixel(1, 1)), isTrue);
  });

  test('inverseLine emits the documented five-parameter CPCL form', () {
    final generator = CpclGenerator()..inverseLine(0, 45, 145, 45);

    expect(generator.preview(), 'INVERSE-LINE 0 45 145 45 45\r\n');
  });

  test('declarative inverse line matches the fluent rectangle mapping', () {
    final generator = CpclGenerator(
      config: const CpclConfiguration(
        printWidth: 200,
        labelLength: 120,
        autoForm: false,
        autoPrint: false,
      ),
      commands: const [CpclInverseLine(x: 0, y: 45, width: 145, height: 45)],
    );

    expect(
      generator.preview(),
      '! 0 203 203 120 1\r\n'
      'PAGE-WIDTH 200\r\n'
      'INVERSE-LINE 0 45 145 45 45\r\n',
    );
  });

  test('preview inverts earlier pixels inside an inverse line', () async {
    final black = img.Image(width: 8, height: 8);
    img.fill(black, color: img.ColorRgb8(0, 0, 0));
    final white = img.Image(width: 8, height: 8);
    img.fill(white, color: img.ColorRgb8(255, 255, 255));

    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 64, labelLength: 32),
      commands: [
        CpclBitmap(x: 4, y: 4, image: black),
        const CpclInverseLine(x: 4, y: 4, width: 8, height: 8),
        const CpclInverseLine(x: 24, y: 4, width: 8, height: 8),
        const CpclInverseLine(x: 40, y: 4, width: 16, height: 16),
        CpclBitmap(x: 44, y: 8, image: white),
      ],
    );

    final png = await CpclPreviewService.renderPngFromGenerator(
      generator,
      pixelRatio: 1,
    );
    final rendered = img.decodePng(png);
    expect(rendered, isNotNull);

    // Black bitmap drawn before the inverse line becomes white.
    expect(_isLight(rendered!.getPixel(6, 6)), isTrue);
    // Empty label stock inside an inverse line becomes black.
    expect(_isLight(rendered.getPixel(28, 8)), isFalse);
    // The inverse line is painted before the white bitmap, so that bitmap
    // stays white instead of being inverted to black.
    expect(_isLight(rendered.getPixel(46, 10)), isTrue);
    // Stock beside that bitmap, still inside the later inverse line, is black.
    expect(_isLight(rendered.getPixel(41, 6)), isFalse);
    // Untouched stock stays white.
    expect(_isLight(rendered.getPixel(1, 1)), isTrue);
  });

  test('renderedText renders text through bitmap output', () async {
    final generator = CpclGenerator();

    await generator.renderedText(
      12,
      18,
      'Hello / ជំរាបសួរ',
      options: const CpclRenderedTextOptions(
        style: TextStyle(fontSize: 20, color: Color(0xFF000000)),
        pixelRatio: 1,
      ),
    );

    final bytes = generator.build();
    final prefix = _asciiPrefix(bytes, maxLength: 64);

    expect(prefix, startsWith('CG '));
    expect(bytes.length, greaterThan(prefix.length + 2));
    expect(latin1.decode(bytes.sublist(bytes.length - 2)), '\r\n');
  });

  test(
    'renderedText pixelRatio scales glyphs instead of adding blank margin',
    () async {
      final normal = await _renderedGraphic('Ag', pixelRatio: 1);
      final scaled = await _renderedGraphic('Ag', pixelRatio: 2);

      expect(scaled.height, closeTo(normal.height * 2, 1));
      expect(scaled.widthBytes, closeTo(normal.widthBytes * 2, 1));
      expect(_lowestInkFraction(normal), greaterThan(0.7));
      expect(_lowestInkFraction(scaled), greaterThan(0.7));
    },
  );

  test(
    'khmerText renders text through bitmap output (backward compatibility)',
    () async {
      final generator = CpclGenerator();

      await generator.khmerText(
        12,
        18,
        'សួស្តី',
        options: const CpclRenderedTextOptions(
          style: TextStyle(fontSize: 20, color: Color(0xFF000000)),
          pixelRatio: 1,
        ),
      );

      final bytes = generator.build();
      final prefix = _asciiPrefix(bytes, maxLength: 64);

      expect(prefix, startsWith('CG '));
      expect(bytes.length, greaterThan(prefix.length + 2));
      expect(latin1.decode(bytes.sublist(bytes.length - 2)), '\r\n');
    },
  );

  test('buildAsync supports declarative CpclRenderedText', () async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 320, labelLength: 200),
      commands: const [
        CpclRenderedText(
          x: 12,
          y: 18,
          text: 'Rendered Unicode / ភាសាខ្មែរ',
          options: CpclRenderedTextOptions(
            style: TextStyle(fontSize: 20, color: Color(0xFF000000)),
            pixelRatio: 1,
          ),
        ),
      ],
    );

    expect(() => generator.build(), throwsStateError);

    final bytes = await generator.buildAsync();
    final preview = latin1.decode(bytes);

    expect(preview, startsWith('! 0 203 203 200 1\r\nPAGE-WIDTH 320\r\nCG '));
    expect(preview, contains('FORM\r\nPRINT\r\n'));
  });

  test('synchronous build rejects async rendered-text commands', () {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 320, labelLength: 200),
      commands: const [
        CpclRenderedText(
          x: 10,
          y: 10,
          text: 'Async Required',
          options: CpclRenderedTextOptions(
            style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
          ),
        ),
      ],
    );

    expect(
      () => generator.build(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('includes async commands'),
        ),
      ),
    );

    const renderedCommand = CpclRenderedText(
      x: 0,
      y: 0,
      text: 'Test',
      options: CpclRenderedTextOptions(style: TextStyle()),
    );
    expect(
      () => renderedCommand.apply(generator),
      throwsA(
        isA<UnsupportedError>().having(
          (e) => e.message,
          'message',
          contains('CpclRenderedText must be built with buildAsync()'),
        ),
      ),
    );
  });

  test('declarative CpclKhmerText retains backward compatibility', () async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 320, labelLength: 200),
      commands: const [
        CpclKhmerText(
          x: 12,
          y: 18,
          text: 'សួស្តី',
          options: CpclRenderedTextOptions(
            style: TextStyle(fontSize: 20, color: Color(0xFF000000)),
            pixelRatio: 1,
          ),
        ),
      ],
    );

    expect(() => generator.build(), throwsStateError);

    final bytes = await generator.buildAsync();
    final preview = latin1.decode(bytes);

    expect(preview, startsWith('! 0 203 203 200 1\r\nPAGE-WIDTH 320\r\nCG '));
    expect(preview, contains('FORM\r\nPRINT\r\n'));

    const khmerCommand = CpclKhmerText(
      x: 0,
      y: 0,
      text: 'សួស្តី',
      options: CpclRenderedTextOptions(style: TextStyle()),
    );
    expect(khmerCommand.requiresAsync, isTrue);
    expect(
      () => khmerCommand.apply(generator),
      throwsA(
        isA<UnsupportedError>().having(
          (e) => e.message,
          'message',
          contains('CpclKhmerText must be built with buildAsync()'),
        ),
      ),
    );
    expect(khmerCommand, isA<CpclRenderedText>());
  });

  test(
    'preview and export support CpclRenderedText and CpclKhmerText',
    () async {
      final generator = CpclGenerator(
        config: const CpclConfiguration(printWidth: 320, labelLength: 200),
        commands: const [
          CpclRenderedText(
            x: 10,
            y: 10,
            text: 'Rendered Script',
            options: CpclRenderedTextOptions(
              style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
            ),
          ),
          CpclKhmerText(
            x: 10,
            y: 40,
            text: 'អក្សរខ្មែរ',
            options: CpclRenderedTextOptions(
              style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
            ),
          ),
        ],
      );

      final png = await CpclPreviewService.renderFromGenerator(generator);
      final pdf = await CpclPreviewService.renderFromGenerator(
        generator,
        outputFormat: CpclPreviewOutputFormat.pdf,
      );

      expect(png.mimeType, 'image/png');
      expect(
        png.data.take(8).toList(),
        orderedEquals([137, 80, 78, 71, 13, 10, 26, 10]),
      );
      expect(pdf.mimeType, 'application/pdf');
      expect(latin1.decode(pdf.data.take(4).toList()), '%PDF');
    },
  );

  test('renders preview export as png and pdf', () async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [
        CpclText(x: 20, y: 20, text: 'Preview'),
        CpclBarcode(
          x: 20,
          y: 60,
          data: '12345',
          options: CpclBarcodeOptions(height: 50),
        ),
        CpclQrCode(x: 280, y: 40, data: 'https://example.com'),
      ],
    );

    final png = await CpclPreviewService.renderFromGenerator(generator);
    final pdf = await CpclPreviewService.renderFromGenerator(
      generator,
      outputFormat: CpclPreviewOutputFormat.pdf,
    );

    expect(png.mimeType, 'image/png');
    expect(
      png.data.take(8).toList(),
      orderedEquals([137, 80, 78, 71, 13, 10, 26, 10]),
    );
    expect(pdf.mimeType, 'application/pdf');
    expect(latin1.decode(pdf.data.take(4).toList()), '%PDF');
  });

  testWidgets('builds CpclPreview widget', (tester) async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [CpclText(x: 20, y: 20, text: 'Preview')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CpclPreview(generator: generator)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CpclPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds CpclPreview widget with CpclRenderedText', (
    tester,
  ) async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [
        CpclRenderedText(
          x: 20,
          y: 20,
          text: 'Rendered Widget Preview',
          options: CpclRenderedTextOptions(
            style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CpclPreview(generator: generator)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CpclPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds CpclPreview widget inside bounded layouts', (
    tester,
  ) async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [CpclText(x: 20, y: 20, text: 'Preview')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: CpclPreview(generator: generator),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CpclPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds CpclPreview with interactive mode enabled', (
    tester,
  ) async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [CpclText(x: 20, y: 20, text: 'Preview')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 280,
            child: CpclPreview(
              generator: generator,
              enableInteraction: true,
              maxScale: 6,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final preview = tester.widget<CpclPreview>(find.byType(CpclPreview));

    expect(preview.enableInteraction, isTrue);
    expect(preview.maxScale, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accepts custom preview frame styling', (tester) async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [CpclText(x: 20, y: 20, text: 'Preview')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CpclPreview(
            generator: generator,
            framePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 20,
            ),
            borderRadius: 20,
            boxShadow: const [],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(CpclPreview), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports preview surface styling', (tester) async {
    final generator = CpclGenerator(
      config: const CpclConfiguration(printWidth: 406, labelLength: 203),
      commands: const [CpclText(x: 20, y: 20, text: 'Preview')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CpclPreview(
            generator: generator,
            previewSurfaceColor: const Color(0xFFF6F7F9),
            showCheckerboard: true,
            checkerColor: const Color(0xFFE3E8EE),
            checkerSize: 10,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final preview = tester.widget<CpclPreview>(find.byType(CpclPreview));

    expect(preview.previewSurfaceColor, const Color(0xFFF6F7F9));
    expect(preview.showCheckerboard, isTrue);
    expect(preview.checkerSize, 10);
    expect(tester.takeException(), isNull);
  });

  test('rejects invalid numeric ranges', () {
    expect(() => CpclGenerator().speed(6), throwsA(isA<RangeError>()));
    expect(
      () => CpclTextStyle(xMultiplier: 17),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => CpclGenerator().qrCode(
        0,
        0,
        'bad',
        options: CpclQrCodeOptions(unit: 0),
      ),
      throwsA(isA<RangeError>()),
    );
    expect(() => CpclGenerator().inverseLine(-1, 0, 10, 10), throwsRangeError);
    expect(() => CpclGenerator().inverseLine(0, 0, 0, 10), throwsRangeError);
    expect(() => CpclGenerator().inverseLine(65535, 0, 1, 1), throwsRangeError);
  });

  group('CPCL protocol correctness golden tests', () {
    test(
      'golden: CG binary exact byte preservation with 0x00, 0x0A, 0x0D, 0x80, 0xFF',
      () {
        // 8 pixels wide, 5 rows high -> 1 byte per row, 5 bytes total.
        final image = img.Image(width: 8, height: 5);
        img.fill(image, color: img.ColorRgb8(255, 255, 255));

        // Row 0: 0x00 (all white)
        // Row 1: 0x0A (binary 00001010 -> bits 4 and 6 black)
        image.setPixelRgb(4, 1, 0, 0, 0);
        image.setPixelRgb(6, 1, 0, 0, 0);
        // Row 2: 0x0D (binary 00001101 -> bits 4, 5, 7 black)
        image.setPixelRgb(4, 2, 0, 0, 0);
        image.setPixelRgb(5, 2, 0, 0, 0);
        image.setPixelRgb(7, 2, 0, 0, 0);
        // Row 3: 0x80 (binary 10000000 -> bit 0 black)
        image.setPixelRgb(0, 3, 0, 0, 0);
        // Row 4: 0xFF (binary 11111111 -> all 8 pixels black)
        for (var x = 0; x < 8; x++) {
          image.setPixelRgb(x, 4, 0, 0, 0);
        }

        final generator = CpclGenerator()..bitmap(10, 20, image);
        final bytes = generator.build();

        const prefix = 'CG 1 5 10 20 ';
        expect(latin1.decode(bytes.sublist(0, prefix.length)), prefix);

        final payload = bytes.sublist(prefix.length, prefix.length + 5);
        expect(payload, [0x00, 0x0A, 0x0D, 0x80, 0xFF]);

        // Command terminator must be exact CRLF
        expect(latin1.decode(bytes.sublist(prefix.length + 5)), '\r\n');
      },
    );

    test(
      'golden: CG padded image width calculation (10px wide -> 2 bytes/row)',
      () {
        // 10 pixels wide -> (10 + 7) ~/ 8 = 2 bytes per row.
        final image = img.Image(width: 10, height: 2);
        img.fill(image, color: img.ColorRgb8(255, 255, 255));
        // First row, pixel 0 black -> 0x80 in byte 0, 0x00 in byte 1
        image.setPixelRgb(0, 0, 0, 0, 0);
        // Second row, pixel 9 black (second byte bit 1) -> 0x00 in byte 0, 0x40 in byte 1
        image.setPixelRgb(9, 1, 0, 0, 0);

        final generator = CpclGenerator()..compressedGraphics(0, 0, image);
        final bytes = generator.build();

        const prefix = 'CG 2 2 0 0 ';
        expect(latin1.decode(bytes.sublist(0, prefix.length)), prefix);
        expect(bytes.sublist(prefix.length, prefix.length + 4), [
          0x80,
          0x00,
          0x00,
          0x40,
        ]);
        expect(latin1.decode(bytes.sublist(prefix.length + 4)), '\r\n');
      },
    );

    test('golden: EG expanded graphics uppercase ASCII hex representation', () {
      final image = img.Image(width: 8, height: 5);
      img.fill(image, color: img.ColorRgb8(255, 255, 255));
      image.setPixelRgb(4, 1, 0, 0, 0);
      image.setPixelRgb(6, 1, 0, 0, 0);
      image.setPixelRgb(4, 2, 0, 0, 0);
      image.setPixelRgb(5, 2, 0, 0, 0);
      image.setPixelRgb(7, 2, 0, 0, 0);
      image.setPixelRgb(0, 3, 0, 0, 0);
      for (var x = 0; x < 8; x++) {
        image.setPixelRgb(x, 4, 0, 0, 0);
      }

      final generator = CpclGenerator()..expandedGraphics(5, 10, image);
      expect(generator.preview(), 'EG 1 5 5 10 000A0D80FF\r\n');
    });

    test('golden: SETMAG factor semantics, 1x clean state, and reset', () {
      final generator = CpclGenerator()
        // 1x / 1x does not emit SETMAG if clean
        ..text(
          0,
          0,
          'Normal 1x',
          style: const CpclTextStyle(xMultiplier: 1, yMultiplier: 1),
        )
        // 2x / 2x emits SETMAG 2 2 and resets to SETMAG 0 0
        ..text(
          0,
          20,
          'Double 2x',
          style: const CpclTextStyle(xMultiplier: 2, yMultiplier: 2),
        )
        // 2x / 3x asymmetric magnification
        ..text(
          0,
          50,
          'Tall 2x3',
          style: const CpclTextStyle(xMultiplier: 2, yMultiplier: 3),
        )
        // Direct setMag call
        ..setMag(3, 4)
        ..setMag(0, 0);

      expect(
        generator.preview(),
        'TEXT 0 0 0 0 Normal 1x\r\n'
        'SETMAG 2 2\r\n'
        'TEXT 0 0 0 20 Double 2x\r\n'
        'SETMAG 0 0\r\n'
        'SETMAG 2 3\r\n'
        'TEXT 0 0 0 50 Tall 2x3\r\n'
        'SETMAG 0 0\r\n'
        'SETMAG 3 4\r\n'
        'SETMAG 0 0\r\n',
      );
    });

    test('golden: SETLP resident 3-argument and utility prefix ! U1', () {
      final generator = CpclGenerator()
        ..setLp(
          const CpclResidentLinePrintOptions(
            font: CpclFont.font5,
            size: 2,
            lineSpacing: 46,
          ),
        )
        ..setLinePrint(
          const CpclResidentLinePrintOptions(
            font: CpclFont.font7,
            size: 0,
            lineSpacing: 24,
          ),
        );

      expect(
        generator.preview(),
        '! U1 SETLP 5 2 46\r\n'
        '! U1 SETLP 7 0 24\r\n',
      );
    });

    test(
      'golden: SETLP TrueType 4-argument and legacy constructor compatibility',
      () {
        final generator = CpclGenerator()
          // TrueType font emits ! U1 SETLP <fontName> <xScale> <yScale> <lineSpacing>
          ..setLinePrint(
            const CpclTrueTypeLinePrintOptions(
              fontName: 'Swiss721',
              xScale: 2,
              yScale: 3,
              lineSpacing: 36,
            ),
          )
          // Legacy setLp also safely emits ! U1 SETLP with 3 arguments
          ..setLp(
            const CpclLinePrintOptions(
              font: CpclFont.font0,
              size: 0,
              unitWidth: 20,
              unitHeight: 30,
            ),
          );

        expect(
          generator.preview(),
          '! U1 SETLP Swiss721 2 3 36\r\n'
          '! U1 SETLP 0 0 30\r\n',
        );
      },
    );

    test(
      'golden: declarative CpclConfiguration emits ! U1 SETLP before label session',
      () {
        final generator = CpclGenerator(
          config: const CpclConfiguration(
            printWidth: 400,
            labelLength: 200,
            linePrintOptions: CpclResidentLinePrintOptions(
              font: CpclFont.font7,
              size: 0,
              lineSpacing: 24,
            ),
          ),
          commands: const [CpclText(x: 10, y: 10, text: 'Declarative Label')],
        );

        final preview = generator.preview();

        // Must begin with the utility session command BEFORE the label session header
        expect(
          preview,
          startsWith(
            '! U1 SETLP 7 0 24\r\n'
            '! 0 203 203 200 1\r\n'
            'PAGE-WIDTH 400\r\n',
          ),
        );
        expect(preview, contains('TEXT 0 0 10 10 Declarative Label\r\n'));
        expect(preview, contains('FORM\r\nPRINT\r\n'));

        // Ensure there is NO bare SETLP inside the label session between header and PRINT
        final labelSessionBody = preview.substring(
          preview.indexOf('! 0 203 203'),
        );
        expect(labelSessionBody, isNot(contains('SETLP')));
      },
    );

    test('golden: BARCODE ratio validation covers complete CPCL code sets', () {
      // Valid CPCL ratios: 0, 4, 20, 21, 25, 29, 30
      final generator = CpclGenerator()
        ..barcode(0, 0, 'R0', options: const CpclBarcodeOptions(ratio: 0))
        ..barcode(0, 10, 'R4', options: const CpclBarcodeOptions(ratio: 4))
        ..barcode(0, 20, 'R20', options: const CpclBarcodeOptions(ratio: 20))
        ..barcode(0, 30, 'R21', options: const CpclBarcodeOptions(ratio: 21))
        ..barcode(0, 40, 'R25', options: const CpclBarcodeOptions(ratio: 25))
        ..barcode(0, 50, 'R29', options: const CpclBarcodeOptions(ratio: 29))
        ..barcode(0, 60, 'R30', options: const CpclBarcodeOptions(ratio: 30));

      expect(
        generator.preview(),
        'BARCODE 128 1 0 100 0 0 R0\r\n'
        'BARCODE 128 1 4 100 0 10 R4\r\n'
        'BARCODE 128 1 20 100 0 20 R20\r\n'
        'BARCODE 128 1 21 100 0 30 R21\r\n'
        'BARCODE 128 1 25 100 0 40 R25\r\n'
        'BARCODE 128 1 29 100 0 50 R29\r\n'
        'BARCODE 128 1 30 100 0 60 R30\r\n',
      );

      // Invalid ratios: 5, 19, 31 must throw RangeError
      expect(
        () =>
            CpclGenerator()
              ..barcode(0, 0, 'X', options: const CpclBarcodeOptions(ratio: 5)),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => CpclGenerator()
          ..barcode(0, 0, 'X', options: const CpclBarcodeOptions(ratio: 19)),
        throwsA(isA<RangeError>()),
      );
      expect(
        () => CpclGenerator()
          ..barcode(0, 0, 'X', options: const CpclBarcodeOptions(ratio: 31)),
        throwsA(isA<RangeError>()),
      );
    });

    test(
      'golden: BARCODE accepts broad command-valid width without artificial bounds',
      () {
        // Width 40 is greater than arbitrary 1..32 range and is valid in CPCL
        final generator = CpclGenerator()
          ..barcode(
            10,
            20,
            'WIDE-BARCODE',
            options: const CpclBarcodeOptions(width: 40, ratio: 1),
          );

        expect(
          generator.preview(),
          'BARCODE 128 40 1 100 10 20 WIDE-BARCODE\r\n',
        );
      },
    );

    test('golden: BARCODE Code 39, ratio codes, and VBARCODE parity', () {
      final generator = CpclGenerator()
        // Code 39 with ratio 1 (2.0:1)
        ..barcode(
          10,
          20,
          'CODE39',
          options: const CpclBarcodeOptions(
            type: CpclBarcodeType.code39,
            width: 1,
            ratio: 1,
            height: 50,
          ),
        )
        // Ratio code 0 (1.5:1)
        ..barcode(
          10,
          80,
          'RATIO0',
          options: const CpclBarcodeOptions(
            type: CpclBarcodeType.code39,
            width: 2,
            ratio: 0,
            height: 60,
          ),
        )
        // Ratio code 3 (3.0:1) using CpclBarcodeRatio
        ..barcode(
          10,
          150,
          'RATIO3',
          options: CpclBarcodeOptions(
            type: CpclBarcodeType.code39,
            width: 2,
            ratio: CpclBarcodeRatio.ratio3_0.code,
            height: 70,
          ),
        )
        // Vertical barcode parity
        ..verticalBarcode(
          200,
          20,
          'VCODE',
          options: const CpclBarcodeOptions(
            type: CpclBarcodeType.code128,
            width: 2,
            ratio: 1,
            height: 80,
          ),
        );

      expect(
        generator.preview(),
        'BARCODE 39 1 1 50 10 20 CODE39\r\n'
        'BARCODE 39 2 0 60 10 80 RATIO0\r\n'
        'BARCODE 39 2 3 70 10 150 RATIO3\r\n'
        'VBARCODE 128 2 1 80 200 20 VCODE\r\n',
      );

      // Verify options backward compatibility getters
      const options = CpclBarcodeOptions(narrow: 3, wide: 2);
      expect(options.width, 3);
      expect(options.narrow, 3);
      expect(options.ratio, 2);
      expect(options.wide, 2);
    });

    test(
      'golden: BARCODE parameter range validation conforms to Zebra CPCL specification',
      () {
        final gen = CpclGenerator();

        // Width 0 accepted
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(width: 0),
          ),
          returnsNormally,
        );
        // Width 65535 accepted
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(width: 65535),
          ),
          returnsNormally,
        );
        // Width 65536 rejected
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(width: 65536),
          ),
          throwsA(isA<RangeError>()),
        );
        // Width -1 rejected
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(width: -1),
          ),
          throwsA(isA<RangeError>()),
        );

        // Height 0 accepted
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(height: 0),
          ),
          returnsNormally,
        );
        // Height 65535 accepted
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(height: 65535),
          ),
          returnsNormally,
        );
        // Height -1 rejected
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(height: -1),
          ),
          throwsA(isA<RangeError>()),
        );
        // Height 65536 rejected
        expect(
          () => gen.barcode(
            10,
            10,
            'TEST',
            options: const CpclBarcodeOptions(height: 65536),
          ),
          throwsA(isA<RangeError>()),
        );

        // X 0 accepted
        expect(() => gen.barcode(0, 10, 'TEST'), returnsNormally);
        // X 65535 accepted
        expect(() => gen.barcode(65535, 10, 'TEST'), returnsNormally);
        // X -1 rejected
        expect(() => gen.barcode(-1, 10, 'TEST'), throwsA(isA<RangeError>()));
        // X 65536 rejected
        expect(
          () => gen.barcode(65536, 10, 'TEST'),
          throwsA(isA<RangeError>()),
        );

        // Equivalent Y tests
        // Y 0 accepted
        expect(() => gen.barcode(10, 0, 'TEST'), returnsNormally);
        // Y 65535 accepted
        expect(() => gen.barcode(10, 65535, 'TEST'), returnsNormally);
        // Y -1 rejected
        expect(() => gen.barcode(10, -1, 'TEST'), throwsA(isA<RangeError>()));
        // Y 65536 rejected
        expect(
          () => gen.barcode(10, 65536, 'TEST'),
          throwsA(isA<RangeError>()),
        );

        // VBARCODE uses identical validation rules
        expect(
          () => gen.verticalBarcode(
            0,
            0,
            'TEST',
            options: const CpclBarcodeOptions(width: 0, height: 0),
          ),
          returnsNormally,
        );
        expect(
          () => gen.verticalBarcode(-1, 0, 'TEST'),
          throwsA(isA<RangeError>()),
        );
        expect(
          () => gen.verticalBarcode(0, -1, 'TEST'),
          throwsA(isA<RangeError>()),
        );
        expect(
          () => gen.verticalBarcode(
            0,
            0,
            'TEST',
            options: const CpclBarcodeOptions(width: -1),
          ),
          throwsA(isA<RangeError>()),
        );
        expect(
          () => gen.verticalBarcode(
            0,
            0,
            'TEST',
            options: const CpclBarcodeOptions(height: -1),
          ),
          throwsA(isA<RangeError>()),
        );

        // Payload exceeds 8191 bytes rejected
        final oversizedPayload = 'A' * 8192;
        expect(
          () => gen.barcode(10, 10, oversizedPayload),
          throwsA(isA<ArgumentError>()),
        );
        final maxValidPayload = 'A' * 8191;
        expect(() => gen.barcode(10, 10, maxValidPayload), returnsNormally);
      },
    );

    test(
      'golden: CpclBarcodeOptions alias precedence gives canonical properties priority',
      () {
        // width takes precedence over narrow
        const optionsWithBothWidth = CpclBarcodeOptions(width: 5, narrow: 2);
        expect(optionsWithBothWidth.width, 5);
        expect(optionsWithBothWidth.narrow, 5);

        // ratio takes precedence over wide
        const optionsWithBothRatio = CpclBarcodeOptions(ratio: 3, wide: 1);
        expect(optionsWithBothRatio.ratio, 3);
        expect(optionsWithBothRatio.wide, 3);
      },
    );
  });
}

Future<({int widthBytes, int height, List<int> pixels})> _renderedGraphic(
  String value, {
  required double pixelRatio,
}) async {
  final generator = CpclGenerator();
  await generator.renderedText(
    0,
    0,
    value,
    options: CpclRenderedTextOptions(
      style: const TextStyle(fontSize: 24, color: Color(0xFF000000)),
      pixelRatio: pixelRatio,
    ),
  );
  return _parseCg(generator.build());
}

({int widthBytes, int height, List<int> pixels}) _parseCg(List<int> bytes) {
  var index = 0;
  String readToken() {
    final start = index;
    while (index < bytes.length && bytes[index] != 0x20) {
      index++;
    }
    final token = latin1.decode(bytes.sublist(start, index));
    if (index < bytes.length && bytes[index] == 0x20) {
      index++;
    }
    return token;
  }

  expect(readToken(), 'CG');
  final widthBytes = int.parse(readToken());
  final height = int.parse(readToken());
  readToken();
  readToken();
  final pixels = bytes.sublist(index, index + widthBytes * height);
  return (widthBytes: widthBytes, height: height, pixels: pixels);
}

double _lowestInkFraction(
  ({int widthBytes, int height, List<int> pixels}) graphic,
) {
  var lowest = -1;
  for (var y = 0; y < graphic.height; y++) {
    final offset = y * graphic.widthBytes;
    for (var x = 0; x < graphic.widthBytes; x++) {
      if (graphic.pixels[offset + x] != 0) {
        lowest = y;
        break;
      }
    }
  }
  expect(lowest, isNonNegative);
  return lowest / (graphic.height - 1);
}

bool _isLight(img.Pixel pixel) {
  return pixel.a > 200 && pixel.r > 200 && pixel.g > 200 && pixel.b > 200;
}

bool _isBlack(img.Pixel pixel) {
  return pixel.a > 200 && pixel.r < 30 && pixel.g < 30 && pixel.b < 30;
}

String _asciiPrefix(List<int> bytes, {required int maxLength}) {
  final values = <int>[];

  for (final byte in bytes.take(maxLength)) {
    if (byte == 10 || byte == 13) {
      break;
    }
    if (byte < 32 || byte > 126) {
      break;
    }
    values.add(byte);
  }

  return latin1.decode(values);
}
