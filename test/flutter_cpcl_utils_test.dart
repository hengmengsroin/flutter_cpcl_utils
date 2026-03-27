import 'dart:convert';

import 'package:flutter/painting.dart';
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
      '! 0 200 200 320 1\r\n'
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
      'SETLP 2 1 24 24\r\n'
      'SETMAG 1 2\r\n'
      'TEXT90 4 2 10 12 Scaled\r\n'
      'SETMAG 0 0\r\n'
      'LEFT\r\n'
      'BOX 5 6 30 40 3\r\n'
      'INVERSE-LINE 8 9 10 11\r\n'
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
      '! 0 200 200 320 1\r\n'
      'PAGE-WIDTH 576\r\n'
      'BOX 10 10 566 310 2\r\n'
      'LINE 20 60 556 60 2\r\n'
      'SETMAG 1 1\r\n'
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
      latin1.decode(bytes.sublist(0, 'EG 1 1 10 20 '.length)),
      'EG 1 1 10 20 ',
    );
    expect(bytes['EG 1 1 10 20 '.length], 0xC0);
    expect(latin1.decode(bytes.sublist(bytes.length - 2)), '\r\n');
  });

  test('khmerText renders text through bitmap output', () async {
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

    expect(prefix, startsWith('EG '));
    expect(bytes.length, greaterThan(prefix.length + 2));
    expect(latin1.decode(bytes.sublist(bytes.length - 2)), '\r\n');
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
  });
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
