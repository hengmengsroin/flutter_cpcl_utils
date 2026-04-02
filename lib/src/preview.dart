import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode/barcode.dart' as bc;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

import 'declarative_commands.dart';
import 'enums.dart';
import 'generator.dart';
import 'options.dart';
import 'text_style.dart';

enum CpclPreviewOutputFormat {
  png('image/png'),
  pdf('application/pdf');

  const CpclPreviewOutputFormat(this.mimeType);

  final String mimeType;
}

class CpclPreviewResponse {
  const CpclPreviewResponse({required this.data, required this.mimeType});

  final Uint8List data;
  final String mimeType;
}

class CpclPreview extends StatefulWidget {
  const CpclPreview({
    super.key,
    required this.generator,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFD0D7DE),
    this.previewSurfaceColor = const Color(0xFFF4F6F8),
    this.showCheckerboard = false,
    this.checkerColor = const Color(0xFFE7EBF0),
    this.checkerSize = 12,
    this.loading,
    this.errorBuilder,
    this.fit = BoxFit.contain,
    this.pixelRatio = 2,
    this.framePadding = const EdgeInsets.all(_defaultFramePadding),
    this.borderRadius = _defaultBorderRadius,
    this.boxShadow = const [
      BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
    this.enableInteraction = false,
    this.minScale = 1,
    this.maxScale = 4,
    this.interactionBoundaryMargin = const EdgeInsets.all(24),
  });

  final CpclGenerator generator;
  final Color backgroundColor;
  final Color borderColor;
  final Color previewSurfaceColor;
  final bool showCheckerboard;
  final Color checkerColor;
  final double checkerSize;
  final Widget? loading;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final BoxFit fit;
  final double pixelRatio;
  final EdgeInsets framePadding;
  final double borderRadius;
  final List<BoxShadow> boxShadow;
  final bool enableInteraction;
  final double minScale;
  final double maxScale;
  final EdgeInsets interactionBoundaryMargin;
  static const double _defaultFramePadding = 16;
  static const double _defaultBorderRadius = 12;

  @override
  State<CpclPreview> createState() => _CpclPreviewState();
}

class _CpclPreviewState extends State<CpclPreview> {
  late Future<Uint8List> _previewFuture;

  @override
  void initState() {
    super.initState();
    _previewFuture = _createPreviewFuture();
  }

  @override
  void didUpdateWidget(covariant CpclPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generator != widget.generator ||
        oldWidget.backgroundColor != widget.backgroundColor ||
        oldWidget.pixelRatio != widget.pixelRatio) {
      _previewFuture = _createPreviewFuture();
    }
  }

  Future<Uint8List> _createPreviewFuture() {
    return CpclPreviewService.renderPngFromGenerator(
      widget.generator,
      backgroundColor: widget.backgroundColor,
      pixelRatio: widget.pixelRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.generator.config;
    if (config == null) {
      return _buildError(
        context,
        StateError(
          'CpclPreview requires a generator created with CpclConfiguration.',
        ),
      );
    }

    return FutureBuilder<Uint8List>(
      future: _previewFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildError(context, snapshot.error!);
        }

        if (!snapshot.hasData) {
          return Center(
            child:
                widget.loading ??
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          );
        }

        final labelSize = Size(
          config.printWidth.toDouble(),
          config.labelLength.toDouble(),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedWidth = constraints.maxWidth.isFinite;
            final hasBoundedHeight = constraints.maxHeight.isFinite;
            final availableSize = Size(
              hasBoundedWidth
                  ? math.max(
                      1,
                      constraints.maxWidth - widget.framePadding.horizontal,
                    )
                  : labelSize.width,
              hasBoundedHeight
                  ? math.max(
                      1,
                      constraints.maxHeight - widget.framePadding.vertical,
                    )
                  : labelSize.height,
            );
            final destinationSize = applyBoxFit(
              widget.fit,
              labelSize,
              availableSize,
            ).destination;

            final preview = _buildPreviewFrame(
              width: destinationSize.width,
              height: destinationSize.height,
              bytes: snapshot.data!,
            );
            final previewContent = widget.enableInteraction
                ? InteractiveViewer(
                    minScale: widget.minScale,
                    maxScale: widget.maxScale,
                    boundaryMargin: widget.interactionBoundaryMargin,
                    child: preview,
                  )
                : preview;

            if (!hasBoundedWidth && !hasBoundedHeight) {
              return previewContent;
            }

            return DecoratedBox(
              decoration: BoxDecoration(color: widget.previewSurfaceColor),
              child: CustomPaint(
                painter: widget.showCheckerboard
                    ? _CheckerboardPainter(
                        color: widget.checkerColor,
                        squareSize: widget.checkerSize,
                      )
                    : null,
                child: SizedBox.expand(
                  child: Padding(
                    padding: widget.framePadding,
                    child: Center(child: previewContent),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreviewFrame({
    required double width,
    required double height,
    required Uint8List bytes,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        border: Border.all(color: widget.borderColor),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: Image.memory(
            bytes,
            width: width,
            height: height,
            fit: BoxFit.fill,
            gaplessPlayback: true,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        border: Border.all(color: const Color(0xFFF1AEB5)),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          error.toString(),
          style: const TextStyle(color: Color(0xFF842029)),
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({required this.color, required this.squareSize});

  final Color color;
  final double squareSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cellSize = math.max(2.0, squareSize);
    final columns = (size.width / cellSize).ceil();
    final rows = (size.height / cellSize).ceil();

    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        if ((row + column).isOdd) {
          continue;
        }

        canvas.drawRect(
          Rect.fromLTWH(column * cellSize, row * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.squareSize != squareSize;
  }
}

class CpclPreviewService {
  static Future<Uint8List> renderPngFromGenerator(
    CpclGenerator generator, {
    Color backgroundColor = Colors.white,
    double pixelRatio = 2,
  }) async {
    final image = await _renderImage(
      generator,
      backgroundColor: backgroundColor,
      pixelRatio: pixelRatio,
    );

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode preview image as PNG.');
    }

    return byteData.buffer.asUint8List();
  }

  static Future<CpclPreviewResponse> renderFromGenerator(
    CpclGenerator generator, {
    CpclPreviewOutputFormat outputFormat = CpclPreviewOutputFormat.png,
    Color backgroundColor = Colors.white,
    double pixelRatio = 2,
  }) async {
    final pngBytes = await renderPngFromGenerator(
      generator,
      backgroundColor: backgroundColor,
      pixelRatio: pixelRatio,
    );

    if (outputFormat == CpclPreviewOutputFormat.png) {
      return CpclPreviewResponse(
        data: pngBytes,
        mimeType: outputFormat.mimeType,
      );
    }

    final config = _requireConfig(generator);
    final pdf = pw.Document();
    final pageFormat = PdfPageFormat(
      config.printWidth / config.resolvedHorizontalDpi * PdfPageFormat.inch,
      config.labelLength / config.resolvedVerticalDpi * PdfPageFormat.inch,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.SizedBox.expand(
            child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.fill),
          );
        },
      ),
    );

    return CpclPreviewResponse(
      data: Uint8List.fromList(await pdf.save()),
      mimeType: outputFormat.mimeType,
    );
  }

  static Future<ui.Image> _renderImage(
    CpclGenerator generator, {
    required Color backgroundColor,
    required double pixelRatio,
  }) async {
    final config = _requireConfig(generator);
    final width = math.max(1, (config.printWidth * pixelRatio).round());
    final height = math.max(1, (config.labelLength * pixelRatio).round());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.scale(pixelRatio, pixelRatio);

    final backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        config.printWidth.toDouble(),
        config.labelLength.toDouble(),
      ),
      backgroundPaint,
    );

    for (final command in generator.commands) {
      await _paintCommand(canvas, command);
    }

    return recorder.endRecording().toImage(width, height);
  }

  static CpclConfiguration _requireConfig(CpclGenerator generator) {
    final config = generator.config;
    if (config == null) {
      throw StateError(
        'Preview requires a generator created with CpclConfiguration.',
      );
    }
    return config;
  }

  static Future<void> _paintCommand(Canvas canvas, CpclCommand command) async {
    switch (command) {
      case CpclText():
        _paintText(canvas, command);
        break;
      case CpclKhmerText():
        _paintKhmerText(canvas, command);
        break;
      case CpclLine():
        _paintLine(canvas, command);
        break;
      case CpclBox():
        _paintBox(canvas, command);
        break;
      case CpclInverseLine():
        _paintInverseLine(canvas, command);
        break;
      case CpclBarcode():
        _paintBarcode(canvas, command);
        break;
      case CpclVerticalBarcode():
        _paintVerticalBarcode(canvas, command);
        break;
      case CpclQrCode():
        _paintQrCode(canvas, command);
        break;
      case CpclBitmap():
        await _paintBitmap(canvas, command);
        break;
      case CpclRawBytes():
      case CpclRawCommand():
        break;
    }
  }

  static void _paintText(Canvas canvas, CpclText command) {
    final style = command.style;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: command.text,
        style: TextStyle(
          color: Colors.black,
          fontSize: _fontSizeFor(style),
          height: 1,
        ),
      ),
    )..layout();

    canvas.save();
    _translateForRotation(
      canvas,
      x: command.x.toDouble(),
      y: command.y.toDouble(),
      rotation: style.rotation,
      width: textPainter.width * style.xMultiplier,
      height: textPainter.height * style.yMultiplier,
    );
    canvas.scale(style.xMultiplier.toDouble(), style.yMultiplier.toDouble());
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  static void _paintKhmerText(Canvas canvas, CpclKhmerText command) {
    final textPainter = TextPainter(
      textDirection: command.options.textDirection,
      textAlign: command.options.textAlign,
      text: TextSpan(text: command.text, style: command.options.style),
    )..layout(maxWidth: command.options.maxWidth ?? double.infinity);

    textPainter.paint(
      canvas,
      Offset(command.x.toDouble(), command.y.toDouble()),
    );
  }

  static void _paintLine(Canvas canvas, CpclLine command) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = command.thickness.toDouble()
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(command.x0.toDouble(), command.y0.toDouble()),
      Offset(command.x1.toDouble(), command.y1.toDouble()),
      paint,
    );
  }

  static void _paintBox(Canvas canvas, CpclBox command) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = command.thickness.toDouble()
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTRB(
        command.x0.toDouble(),
        command.y0.toDouble(),
        command.x1.toDouble(),
        command.y1.toDouble(),
      ),
      paint,
    );
  }

  static void _paintInverseLine(Canvas canvas, CpclInverseLine command) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        command.x.toDouble(),
        command.y.toDouble(),
        command.width.toDouble(),
        command.height.toDouble(),
      ),
      paint,
    );
  }

  static void _paintBarcode(Canvas canvas, CpclBarcode command) {
    final barcode = _barcodeFor(command.options.type);
    final recipe = barcode.make(
      command.data,
      width: _barcodeWidth(command.data, command.options),
      height: command.options.height.toDouble(),
      drawText: false,
    );
    _paintBarcodeRecipe(
      canvas,
      recipe,
      x: command.x.toDouble(),
      y: command.y.toDouble(),
    );
  }

  static void _paintVerticalBarcode(
    Canvas canvas,
    CpclVerticalBarcode command,
  ) {
    final barcode = _barcodeFor(command.options.type);
    final width = _barcodeWidth(command.data, command.options);
    final height = command.options.height.toDouble();
    final recipe = barcode.make(
      command.data,
      width: width,
      height: height,
      drawText: false,
    );

    canvas.save();
    canvas.translate(command.x.toDouble(), command.y.toDouble() + width);
    canvas.rotate(-math.pi / 2);
    _paintBarcodeRecipe(canvas, recipe, x: 0, y: 0);
    canvas.restore();
  }

  static void _paintQrCode(Canvas canvas, CpclQrCode command) {
    final qrCode = QrCode.fromData(
      data: command.data,
      errorCorrectLevel: _qrCorrectionLevel(command.options.ecc),
    );
    final qrImage = QrImage(qrCode);
    final moduleSize = command.options.unit.toDouble();
    final size = qrImage.moduleCount * moduleSize;
    final darkPaint = Paint()..color = Colors.black;
    final lightPaint = Paint()..color = Colors.white;
    final rect = Rect.fromLTWH(
      command.x.toDouble(),
      command.y.toDouble(),
      size,
      size,
    );

    canvas.drawRect(rect, lightPaint);
    for (var row = 0; row < qrImage.moduleCount; row++) {
      for (var col = 0; col < qrImage.moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              command.x + col * moduleSize,
              command.y + row * moduleSize,
              moduleSize,
              moduleSize,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  static Future<void> _paintBitmap(Canvas canvas, CpclBitmap command) async {
    final png = Uint8List.fromList(img.encodePng(command.image));
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(
        command.x.toDouble(),
        command.y.toDouble(),
        command.image.width.toDouble(),
        command.image.height.toDouble(),
      ),
      image: frame.image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
    );
  }

  static void _translateForRotation(
    Canvas canvas, {
    required double x,
    required double y,
    required CpclRotation rotation,
    required double width,
    required double height,
  }) {
    switch (rotation) {
      case CpclRotation.angle0:
        canvas.translate(x, y);
        break;
      case CpclRotation.angle90:
        canvas.translate(x + height, y);
        canvas.rotate(math.pi / 2);
        break;
      case CpclRotation.angle180:
        canvas.translate(x + width, y + height);
        canvas.rotate(math.pi);
        break;
      case CpclRotation.angle270:
        canvas.translate(x, y + width);
        canvas.rotate(-math.pi / 2);
        break;
    }
  }

  static double _fontSizeFor(CpclTextStyle style) {
    return switch (style.font) {
      CpclFont.font0 || CpclFont.font1 => 12 + style.size * 2,
      CpclFont.font2 || CpclFont.font3 => 14 + style.size * 2,
      CpclFont.font4 || CpclFont.font5 => 16 + style.size * 2,
      CpclFont.font6 || CpclFont.font7 => 18 + style.size * 2,
    };
  }

  static bc.Barcode _barcodeFor(CpclBarcodeType type) {
    return switch (type) {
      CpclBarcodeType.code128 => bc.Barcode.code128(),
      CpclBarcodeType.code39 => bc.Barcode.code39(),
      CpclBarcodeType.ean13 => bc.Barcode.ean13(),
      CpclBarcodeType.ean8 => bc.Barcode.ean8(),
      CpclBarcodeType.upcA => bc.Barcode.upcA(),
      CpclBarcodeType.upcE => bc.Barcode.upcE(),
      CpclBarcodeType.codabar => bc.Barcode.codabar(),
      CpclBarcodeType.interleaved2of5 => bc.Barcode.itf(),
    };
  }

  static double _barcodeWidth(String data, CpclBarcodeOptions options) {
    return math.max(
      80,
      (data.length * (options.narrow + options.wide) * 6).toDouble(),
    );
  }

  static int _qrCorrectionLevel(CpclQrErrorCorrection correction) {
    return switch (correction) {
      CpclQrErrorCorrection.low => QrErrorCorrectLevel.L,
      CpclQrErrorCorrection.medium => QrErrorCorrectLevel.M,
      CpclQrErrorCorrection.quartile => QrErrorCorrectLevel.Q,
      CpclQrErrorCorrection.high => QrErrorCorrectLevel.H,
    };
  }

  static void _paintBarcodeRecipe(
    Canvas canvas,
    Iterable<bc.BarcodeElement> recipe, {
    required double x,
    required double y,
  }) {
    final paint = Paint()..color = Colors.black;
    for (final element in recipe) {
      if (element case bc.BarcodeBar(black: true)) {
        canvas.drawRect(
          Rect.fromLTWH(
            x + element.left,
            y + element.top,
            element.width,
            element.height,
          ),
          paint,
        );
      }
    }
  }
}
