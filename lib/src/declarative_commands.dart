import 'package:image/image.dart' as img;

import 'generator.dart';
import 'options.dart';
import 'rendered_text_options.dart';
import 'text_style.dart';

abstract class CpclCommand {
  const CpclCommand();

  bool get requiresAsync => false;

  void apply(CpclGenerator generator);

  Future<void> applyAsync(CpclGenerator generator) async {
    apply(generator);
  }
}

class CpclText extends CpclCommand {
  const CpclText({
    required this.x,
    required this.y,
    required this.text,
    this.style = const CpclTextStyle(),
  });

  final int x;
  final int y;
  final String text;
  final CpclTextStyle style;

  @override
  void apply(CpclGenerator generator) {
    generator.text(x, y, text, style: style);
  }
}

class CpclBarcode extends CpclCommand {
  const CpclBarcode({
    required this.x,
    required this.y,
    required this.data,
    this.options = const CpclBarcodeOptions(),
  });

  final int x;
  final int y;
  final String data;
  final CpclBarcodeOptions options;

  @override
  void apply(CpclGenerator generator) {
    generator.barcode(x, y, data, options: options);
  }
}

class CpclVerticalBarcode extends CpclCommand {
  const CpclVerticalBarcode({
    required this.x,
    required this.y,
    required this.data,
    this.options = const CpclBarcodeOptions(),
  });

  final int x;
  final int y;
  final String data;
  final CpclBarcodeOptions options;

  @override
  void apply(CpclGenerator generator) {
    generator.verticalBarcode(x, y, data, options: options);
  }
}

class CpclQrCode extends CpclCommand {
  const CpclQrCode({
    required this.x,
    required this.y,
    required this.data,
    this.options = const CpclQrCodeOptions(),
  });

  final int x;
  final int y;
  final String data;
  final CpclQrCodeOptions options;

  @override
  void apply(CpclGenerator generator) {
    generator.qrCode(x, y, data, options: options);
  }
}

class CpclLine extends CpclCommand {
  const CpclLine({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    this.thickness = 1,
  });

  final int x0;
  final int y0;
  final int x1;
  final int y1;
  final int thickness;

  @override
  void apply(CpclGenerator generator) {
    generator.line(x0, y0, x1, y1, thickness: thickness);
  }
}

class CpclBox extends CpclCommand {
  const CpclBox({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    this.thickness = 1,
  });

  final int x0;
  final int y0;
  final int x1;
  final int y1;
  final int thickness;

  @override
  void apply(CpclGenerator generator) {
    generator.box(x0, y0, x1, y1, thickness: thickness);
  }
}

class CpclInverseLine extends CpclCommand {
  const CpclInverseLine({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  @override
  void apply(CpclGenerator generator) {
    generator.inverseLine(x, y, width, height);
  }
}

class CpclBitmap extends CpclCommand {
  const CpclBitmap({
    required this.x,
    required this.y,
    required this.image,
    this.threshold = 127,
  });

  final int x;
  final int y;
  final img.Image image;
  final int threshold;

  @override
  void apply(CpclGenerator generator) {
    generator.bitmap(x, y, image, threshold: threshold);
  }
}

class CpclKhmerText extends CpclCommand {
  const CpclKhmerText({
    required this.x,
    required this.y,
    required this.text,
    required this.options,
  });

  final int x;
  final int y;
  final String text;
  final CpclRenderedTextOptions options;

  @override
  bool get requiresAsync => true;

  @override
  void apply(CpclGenerator generator) {
    throw UnsupportedError('CpclKhmerText must be built with buildAsync().');
  }

  @override
  Future<void> applyAsync(CpclGenerator generator) {
    return generator.khmerText(x, y, text, options: options);
  }
}

class CpclRawCommand extends CpclCommand {
  const CpclRawCommand(this.command);

  final String command;

  @override
  void apply(CpclGenerator generator) {
    generator.rawCommand(command);
  }
}

class CpclRawBytes extends CpclCommand {
  const CpclRawBytes(this.bytes);

  final List<int> bytes;

  @override
  void apply(CpclGenerator generator) {
    generator.rawBytes(bytes);
  }
}
