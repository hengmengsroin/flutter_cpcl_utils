import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;

import 'commands.dart';
import 'enums.dart';
import 'label_size.dart';
import 'rendered_text_options.dart';
import 'text_style.dart';

typedef Generator = CpclGenerator;

class CpclGenerator {
  CpclGenerator({this.newLine = '\r\n', this.codec = latin1})
    : _commands = CpclCommandBuffer(codec: codec, newLine: newLine);

  final String newLine;
  final Encoding codec;
  final CpclCommandBuffer _commands;

  CpclGenerator reset() {
    _commands.clear();
    return this;
  }

  Uint8List build() => _commands.build();

  List<int> bytes() => build();

  String preview() => String.fromCharCodes(build());

  CpclGenerator rawBytes(List<int> bytes) {
    _commands.addRawBytes(bytes);
    return this;
  }

  CpclGenerator rawCommand(String command) {
    _commands.addCommand(command);
    return this;
  }

  CpclGenerator initialize(
    CpclLabelSize size, {
    int copies = 1,
    int offset = 0,
    int horizontalDpi = 200,
    int verticalDpi = 200,
  }) {
    requirePositive(size.width, 'size.width');
    requirePositive(size.height, 'size.height');
    requirePositive(copies, 'copies');
    requireNonNegative(offset, 'offset');
    requirePositive(horizontalDpi, 'horizontalDpi');
    requirePositive(verticalDpi, 'verticalDpi');

    return this
      ..rawCommand(
        '! $offset $horizontalDpi $verticalDpi ${size.height} $copies',
      )
      ..pageWidth(size.width);
  }

  CpclGenerator pageWidth(int width) {
    requirePositive(width, 'width');
    return rawCommand('PAGE-WIDTH $width');
  }

  CpclGenerator speed(int value) {
    requireRange(value, 0, 5, 'value');
    return rawCommand('SPEED $value');
  }

  CpclGenerator tone(int value) {
    requireRange(value, 0, 3, 'value');
    return rawCommand('TONE $value');
  }

  CpclGenerator prefeed(int dots) {
    requireNonNegative(dots, 'dots');
    return rawCommand('PREFEED $dots');
  }

  CpclGenerator postfeed(int dots) {
    requireNonNegative(dots, 'dots');
    return rawCommand('POSTFEED $dots');
  }

  CpclGenerator center() => rawCommand('CENTER');

  CpclGenerator left() => rawCommand('LEFT');

  CpclGenerator right() => rawCommand('RIGHT');

  CpclGenerator text(
    int x,
    int y,
    String value, {
    CpclTextStyle style = const CpclTextStyle(),
  }) {
    _validateTextStyle(style);
    final sanitized = sanitizeCpclText(value);
    final hasMagnification = style.xMultiplier > 1 || style.yMultiplier > 1;

    if (hasMagnification) {
      rawCommand('SETMAG ${style.xMultiplier - 1} ${style.yMultiplier - 1}');
    }

    rawCommand(
      '${style.rotation.textCommand} ${style.font.value} ${style.size} $x $y $sanitized',
    );

    if (hasMagnification) {
      rawCommand('SETMAG 0 0');
    }

    return this;
  }

  CpclGenerator line(int x0, int y0, int x1, int y1, {int thickness = 1}) {
    requirePositive(thickness, 'thickness');
    return rawCommand('LINE $x0 $y0 $x1 $y1 $thickness');
  }

  CpclGenerator box(int x0, int y0, int x1, int y1, {int thickness = 1}) {
    requirePositive(thickness, 'thickness');
    return rawCommand('BOX $x0 $y0 $x1 $y1 $thickness');
  }

  CpclGenerator barcode(
    int x,
    int y,
    String content, {
    CpclBarcodeType type = CpclBarcodeType.code128,
    int narrow = 1,
    int wide = 1,
    int height = 100,
  }) {
    requirePositive(narrow, 'narrow');
    requirePositive(wide, 'wide');
    requirePositive(height, 'height');
    return rawCommand(
      'BARCODE ${type.value} $narrow $wide $height $x $y ${sanitizeCpclText(content)}',
    );
  }

  CpclGenerator qrCode(
    int x,
    int y,
    String content, {
    CpclQrErrorCorrection ecc = CpclQrErrorCorrection.medium,
    int model = 2,
    int unit = 6,
  }) {
    requireRange(model, 1, 2, 'model');
    requireRange(unit, 1, 32, 'unit');

    return this
      ..rawCommand('B QR $x $y M $model U $unit')
      ..rawCommand('${ecc.value}A,${sanitizeCpclText(content)}')
      ..rawCommand('ENDQR');
  }

  CpclGenerator bitmap(int x, int y, img.Image image, {int threshold = 127}) {
    requireRange(threshold, 0, 255, 'threshold');
    final raster = _rasterize(image, threshold: threshold);
    _commands.addEncodedText('EG ${raster.widthBytes} ${raster.height} $x $y ');
    _commands.addRawBytes(raster.bytes);
    _commands.addEncodedText(newLine);
    return this;
  }

  Future<CpclGenerator> khmerText(
    int x,
    int y,
    String value, {
    required CpclRenderedTextOptions options,
  }) async {
    final rendered = await _renderFlutterText(value, options: options);
    return bitmap(x, y, rendered, threshold: options.threshold);
  }

  CpclGenerator form() => rawCommand('FORM');

  CpclGenerator print() => rawCommand('PRINT');

  void _validateTextStyle(CpclTextStyle style) {
    requireNonNegative(style.size, 'style.size');
    requireRange(style.xMultiplier, 1, 16, 'style.xMultiplier');
    requireRange(style.yMultiplier, 1, 16, 'style.yMultiplier');
  }

  Future<img.Image> _renderFlutterText(
    String value, {
    required CpclRenderedTextOptions options,
  }) async {
    if (value.isEmpty) {
      throw ArgumentError.value(value, 'value', 'Must not be empty');
    }

    requirePositive(options.pixelRatio, 'options.pixelRatio');
    requireNonNegative(options.padding, 'options.padding');
    requireRange(options.threshold, 0, 255, 'options.threshold');

    final textPainter = TextPainter(
      text: TextSpan(text: value, style: options.style),
      textAlign: options.textAlign,
      textDirection: options.textDirection,
    );

    textPainter.layout(maxWidth: options.maxWidth ?? double.infinity);

    final contentWidth = textPainter.width.ceil();
    final contentHeight = textPainter.height.ceil();
    final padding = options.padding.ceil();
    final imageWidth = (contentWidth + padding * 2).clamp(1, 65535);
    final imageHeight = (contentHeight + padding * 2).clamp(1, 65535);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()..color = options.backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageWidth.toDouble(), imageHeight.toDouble()),
      backgroundPaint,
    );
    textPainter.paint(canvas, Offset(options.padding, options.padding));

    final picture = recorder.endRecording();
    final rendered = await picture.toImage(
      (imageWidth * options.pixelRatio).ceil(),
      (imageHeight * options.pixelRatio).ceil(),
    );
    final byteData = await rendered.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) {
      throw StateError('Failed to convert rendered text to bytes.');
    }

    final bytes = byteData.buffer.asUint8List();
    return img.Image.fromBytes(
      width: rendered.width,
      height: rendered.height,
      bytes: bytes.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  _RasterizedBitmap _rasterize(img.Image source, {required int threshold}) {
    final grayscaleImage = img.grayscale(img.Image.from(source));
    final widthBytes = (grayscaleImage.width + 7) ~/ 8;
    final paddedWidth = widthBytes * 8;
    final bytes = Uint8List(widthBytes * grayscaleImage.height);

    for (var y = 0; y < grayscaleImage.height; y++) {
      for (var x = 0; x < paddedWidth; x++) {
        final isBlack = x < grayscaleImage.width
            ? grayscaleImage.getPixel(x, y).r <= threshold
            : false;
        if (isBlack) {
          final byteIndex = y * widthBytes + (x ~/ 8);
          final bitIndex = 7 - (x % 8);
          bytes[byteIndex] |= 1 << bitIndex;
        }
      }
    }

    return _RasterizedBitmap(
      widthBytes: widthBytes,
      height: grayscaleImage.height,
      bytes: bytes,
    );
  }
}

class _RasterizedBitmap {
  const _RasterizedBitmap({
    required this.widthBytes,
    required this.height,
    required this.bytes,
  });

  final int widthBytes;
  final int height;
  final Uint8List bytes;
}
