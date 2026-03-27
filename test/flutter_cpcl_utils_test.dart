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
      ..center()
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
      ..prefeed(24)
      ..postfeed(48);

    expect(
      generator.preview(),
      'CENTER\r\n'
      'SETMAG 1 2\r\n'
      'TEXT90 4 2 10 12 Scaled\r\n'
      'SETMAG 0 0\r\n'
      'LEFT\r\n'
      'BOX 5 6 30 40 3\r\n'
      'PREFEED 24\r\n'
      'POSTFEED 48\r\n',
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
      () => CpclGenerator().qrCode(0, 0, 'bad', unit: 0),
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
