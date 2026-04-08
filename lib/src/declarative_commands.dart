import 'package:image/image.dart' as img;

import 'generator.dart';
import 'options.dart';
import 'rendered_text_options.dart';
import 'text_style.dart';

/// Base type for declarative commands that can be applied to a generator.
abstract class CpclCommand {
  /// Creates a declarative CPCL command.
  const CpclCommand();

  /// Whether this command requires asynchronous processing.
  bool get requiresAsync => false;

  /// Applies this command synchronously.
  void apply(CpclGenerator generator);

  /// Applies this command asynchronously.
  Future<void> applyAsync(CpclGenerator generator) async {
    apply(generator);
  }
}

/// Declarative `TEXT` command.
class CpclText extends CpclCommand {
  /// Creates a text command.
  const CpclText({
    required this.x,
    required this.y,
    required this.text,
    this.style = const CpclTextStyle(),
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// Text value to print.
  final String text;

  /// Text styling options.
  final CpclTextStyle style;

  @override
  /// Applies this text command to [generator].
  void apply(CpclGenerator generator) {
    generator.text(x, y, text, style: style);
  }
}

/// Declarative `BARCODE` command.
class CpclBarcode extends CpclCommand {
  /// Creates a barcode command.
  const CpclBarcode({
    required this.x,
    required this.y,
    required this.data,
    this.options = const CpclBarcodeOptions(),
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// Barcode data content.
  final String data;

  /// Barcode options.
  final CpclBarcodeOptions options;

  @override
  /// Applies this barcode command to [generator].
  void apply(CpclGenerator generator) {
    generator.barcode(x, y, data, options: options);
  }
}

/// Declarative `VBARCODE` command.
class CpclVerticalBarcode extends CpclCommand {
  /// Creates a vertical barcode command.
  const CpclVerticalBarcode({
    required this.x,
    required this.y,
    required this.data,
    this.options = const CpclBarcodeOptions(),
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// Barcode data content.
  final String data;

  /// Barcode options.
  final CpclBarcodeOptions options;

  @override
  /// Applies this vertical barcode command to [generator].
  void apply(CpclGenerator generator) {
    generator.verticalBarcode(x, y, data, options: options);
  }
}

/// Declarative `QRCODE` command.
class CpclQrCode extends CpclCommand {
  /// Creates a QR code command.
  const CpclQrCode({
    required this.x,
    required this.y,
    required this.data,
    this.options = const CpclQrCodeOptions(),
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// QR payload content.
  final String data;

  /// QR options.
  final CpclQrCodeOptions options;

  @override
  /// Applies this QR code command to [generator].
  void apply(CpclGenerator generator) {
    generator.qrCode(x, y, data, options: options);
  }
}

/// Declarative `LINE` command.
class CpclLine extends CpclCommand {
  /// Creates a line command.
  const CpclLine({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    this.thickness = 1,
  });

  /// Start X coordinate in dots.
  final int x0;

  /// Start Y coordinate in dots.
  final int y0;

  /// End X coordinate in dots.
  final int x1;

  /// End Y coordinate in dots.
  final int y1;

  /// Line thickness in dots.
  final int thickness;

  @override
  /// Applies this line command to [generator].
  void apply(CpclGenerator generator) {
    generator.line(x0, y0, x1, y1, thickness: thickness);
  }
}

/// Declarative `BOX` command.
class CpclBox extends CpclCommand {
  /// Creates a box command.
  const CpclBox({
    required this.x0,
    required this.y0,
    required this.x1,
    required this.y1,
    this.thickness = 1,
  });

  /// Top-left X coordinate in dots.
  final int x0;

  /// Top-left Y coordinate in dots.
  final int y0;

  /// Bottom-right X coordinate in dots.
  final int x1;

  /// Bottom-right Y coordinate in dots.
  final int y1;

  /// Border thickness in dots.
  final int thickness;

  @override
  /// Applies this box command to [generator].
  void apply(CpclGenerator generator) {
    generator.box(x0, y0, x1, y1, thickness: thickness);
  }
}

/// Declarative `INVERSE-LINE` command.
class CpclInverseLine extends CpclCommand {
  /// Creates an inverse-line command.
  const CpclInverseLine({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// Inversion width in dots.
  final int width;

  /// Inversion height in dots.
  final int height;

  @override
  /// Applies this inverse-line command to [generator].
  void apply(CpclGenerator generator) {
    generator.inverseLine(x, y, width, height);
  }
}

/// Declarative `EG` bitmap command.
class CpclBitmap extends CpclCommand {
  /// Creates a bitmap command.
  const CpclBitmap({
    required this.x,
    required this.y,
    required this.image,
    this.threshold = 127,
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// Source bitmap image.
  final img.Image image;

  /// Monochrome threshold (`0..255`).
  final int threshold;

  @override
  /// Applies this bitmap command to [generator].
  void apply(CpclGenerator generator) {
    generator.bitmap(x, y, image, threshold: threshold);
  }
}

/// Declarative Khmer text command that renders text using Flutter first.
class CpclKhmerText extends CpclCommand {
  /// Creates a Khmer text command.
  const CpclKhmerText({
    required this.x,
    required this.y,
    required this.text,
    required this.options,
  });

  /// X position in dots.
  final int x;

  /// Y position in dots.
  final int y;

  /// Text value to render.
  final String text;

  /// Rasterization options for rendering Flutter text.
  final CpclRenderedTextOptions options;

  @override
  bool get requiresAsync => true;

  @override
  /// Khmer text commands require asynchronous rendering.
  void apply(CpclGenerator generator) {
    throw UnsupportedError('CpclKhmerText must be built with buildAsync().');
  }

  @override
  /// Applies this Khmer text command asynchronously.
  Future<void> applyAsync(CpclGenerator generator) {
    return generator.khmerText(x, y, text, options: options);
  }
}

/// Inserts a raw text command into the command stream.
class CpclRawCommand extends CpclCommand {
  /// Creates a raw command wrapper.
  const CpclRawCommand(this.command);

  /// Raw command line to append.
  final String command;

  @override
  /// Applies this raw command to [generator].
  void apply(CpclGenerator generator) {
    generator.rawCommand(command);
  }
}

/// Inserts raw bytes into the command stream.
class CpclRawBytes extends CpclCommand {
  /// Creates a raw-bytes command wrapper.
  const CpclRawBytes(this.bytes);

  /// Raw bytes to append.
  final List<int> bytes;

  @override
  /// Applies these raw bytes to [generator].
  void apply(CpclGenerator generator) {
    generator.rawBytes(bytes);
  }
}
