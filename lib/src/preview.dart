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

/// Output formats supported by [CpclPreviewService].
enum CpclPreviewOutputFormat {
  png('image/png'),
  pdf('application/pdf');

  const CpclPreviewOutputFormat(this.mimeType);

  /// MIME type for the output format.
  final String mimeType;
}

/// Binary preview payload with MIME metadata.
class CpclPreviewResponse {
  /// Creates a preview response.
  const CpclPreviewResponse({required this.data, required this.mimeType});

  /// Encoded preview bytes.
  final Uint8List data;

  /// MIME type for [data].
  final String mimeType;
}

/// Flutter widget that renders a visual preview from a [CpclGenerator].
class CpclPreview extends StatefulWidget {
  /// Creates a CPCL preview widget.
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

  /// Generator containing declarative commands and configuration.
  final CpclGenerator generator;

  /// Label background color.
  final Color backgroundColor;

  /// Frame border color.
  final Color borderColor;

  /// Color behind the framed preview.
  final Color previewSurfaceColor;

  /// Whether to paint a checkerboard behind the frame.
  final bool showCheckerboard;

  /// Checkerboard square color.
  final Color checkerColor;

  /// Checkerboard square size.
  final double checkerSize;

  /// Optional loading widget.
  final Widget? loading;

  /// Optional error builder.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Box fit used for the preview content.
  final BoxFit fit;

  /// Render pixel ratio.
  final double pixelRatio;

  /// Padding around the preview frame.
  final EdgeInsets framePadding;

  /// Border radius for the frame.
  final double borderRadius;

  /// Shadow list for the frame.
  final List<BoxShadow> boxShadow;

  /// Whether pinch/zoom interaction is enabled.
  final bool enableInteraction;

  /// Minimum interaction scale.
  final double minScale;

  /// Maximum interaction scale.
  final double maxScale;

  /// Boundary margin for interactive transforms.
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

/// Utility that renders generator commands to image or PDF bytes.
class CpclPreviewService {
  /// Renders a generator to PNG bytes.
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

  /// Renders a generator to either PNG or PDF bytes.
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

    final justify = _PreviewJustify(config);
    for (final command in generator.commands) {
      await _paintCommand(canvas, command, justify);
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

  static Future<void> _paintCommand(
    Canvas canvas,
    CpclCommand command,
    _PreviewJustify justify,
  ) async {
    switch (command) {
      case CpclText():
        _paintText(canvas, command, justify);
        break;
      case CpclRenderedText():
        _paintRenderedText(canvas, command);
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
        _paintBarcode(canvas, command, justify);
        break;
      case CpclVerticalBarcode():
        _paintVerticalBarcode(canvas, command, justify);
        break;
      case CpclQrCode():
        _paintQrCode(canvas, command, justify);
        break;
      case CpclBitmap():
        await _paintBitmap(canvas, command);
        break;
      case CpclExpandedGraphics():
        await _paintBitmap(
          canvas,
          CpclBitmap(
            x: command.x,
            y: command.y,
            image: command.image,
            threshold: command.threshold,
          ),
        );
        break;
      case CpclRawCommand():
        justify.applyCommand(command.command);
        break;
      case CpclRawBytes():
        break;
    }
  }

  static void _paintText(
    Canvas canvas,
    CpclText command,
    _PreviewJustify justify,
  ) {
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

    final width = textPainter.width * style.xMultiplier;
    final height = textPainter.height * style.yMultiplier;
    final horizontalExtent = switch (style.rotation) {
      CpclRotation.angle0 || CpclRotation.angle180 => width,
      CpclRotation.angle90 || CpclRotation.angle270 => height,
    };

    canvas.save();
    _translateForRotation(
      canvas,
      x: justify.align(command.x.toDouble(), horizontalExtent),
      y: command.y.toDouble(),
      rotation: style.rotation,
      width: width,
      height: height,
    );
    canvas.scale(style.xMultiplier.toDouble(), style.yMultiplier.toDouble());
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  static void _paintRenderedText(Canvas canvas, CpclRenderedText command) {
    final options = command.options;
    final textPainter = TextPainter(
      textDirection: options.textDirection,
      textAlign: options.textAlign,
      text: TextSpan(text: command.text, style: options.style),
    )..layout(maxWidth: options.maxWidth ?? double.infinity);

    canvas.save();
    canvas.translate(command.x.toDouble(), command.y.toDouble());
    canvas.scale(options.pixelRatio, options.pixelRatio);
    textPainter.paint(canvas, Offset(options.padding, options.padding));
    canvas.restore();
  }

  static void _paintLine(Canvas canvas, CpclLine command) {
    final paint = Paint()..color = Colors.black;
    final x0 = command.x0.toDouble();
    final y0 = command.y0.toDouble();
    final x1 = command.x1.toDouble();
    final y1 = command.y1.toDouble();
    final thickness = math.max(1, command.thickness).toDouble();

    // Horizontal thickness extends downward. Vertical thickness extends
    // to the right. A centered stroke would paint above or left of the
    // coordinates the printer uses.
    if (y0 == y1) {
      final left = math.min(x0, x1);
      canvas.drawRect(
        Rect.fromLTWH(left, y0, (x1 - x0).abs(), thickness),
        paint,
      );
      return;
    }
    if (x0 == x1) {
      final top = math.min(y0, y1);
      canvas.drawRect(
        Rect.fromLTWH(x0, top, thickness, (y1 - y0).abs()),
        paint,
      );
      return;
    }

    final dx = x1 - x0;
    final dy = y1 - y0;
    final length = math.sqrt(dx * dx + dy * dy);
    var nx = -dy / length;
    var ny = dx / length;
    if (nx < 0 || (nx == 0 && ny < 0)) {
      nx = -nx;
      ny = -ny;
    }
    final half = thickness / 2;
    canvas.drawLine(
      Offset(x0 + nx * half, y0 + ny * half),
      Offset(x1 + nx * half, y1 + ny * half),
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.butt,
    );
  }

  static void _paintBox(Canvas canvas, CpclBox command) {
    final left = math.min(command.x0, command.x1).toDouble();
    final top = math.min(command.y0, command.y1).toDouble();
    final right = math.max(command.x0, command.x1).toDouble();
    final bottom = math.max(command.y0, command.y1).toDouble();
    final thickness = math.max(1, command.thickness).toDouble();
    final inset = thickness / 2;
    final rect = Rect.fromLTRB(
      left + inset,
      top + inset,
      right - inset,
      bottom - inset,
    );
    final paint = Paint()..color = Colors.black;
    if (rect.width <= 0 || rect.height <= 0) {
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
      return;
    }
    canvas.drawRect(
      rect,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );
  }

  static void _paintInverseLine(Canvas canvas, CpclInverseLine command) {
    final rect = Rect.fromLTWH(
      command.x.toDouble(),
      command.y.toDouble(),
      command.width.toDouble(),
      command.height.toDouble(),
    );
    // Composite an opaque white layer with difference so RGB inverts and
    // alpha stays opaque. Drawing the blend directly would also difference
    // alpha and punch a transparent hole through the label.
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.difference);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFFFFFFF));
    canvas.restore();
  }

  static void _paintBarcode(
    Canvas canvas,
    CpclBarcode command,
    _PreviewJustify justify,
  ) {
    final barcode = _barcodeFor(command.options.type);
    final width = _barcodeWidth(command.data, command.options);
    final recipe = barcode.make(
      command.data,
      width: width,
      height: command.options.height.toDouble(),
      drawText: false,
    );
    _paintBarcodeRecipe(
      canvas,
      recipe,
      x: justify.align(command.x.toDouble(), width),
      y: command.y.toDouble(),
    );
  }

  static void _paintVerticalBarcode(
    Canvas canvas,
    CpclVerticalBarcode command,
    _PreviewJustify justify,
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
    canvas.translate(
      justify.align(command.x.toDouble(), height),
      command.y.toDouble() + width,
    );
    canvas.rotate(-math.pi / 2);
    _paintBarcodeRecipe(canvas, recipe, x: 0, y: 0);
    canvas.restore();
  }

  static void _paintQrCode(
    Canvas canvas,
    CpclQrCode command,
    _PreviewJustify justify,
  ) {
    final qrCode = QrCode.fromData(
      data: command.data,
      errorCorrectLevel: _qrCorrectionLevel(command.options.ecc),
    );
    final qrImage = QrImage(qrCode);
    final moduleSize = command.options.unit.toDouble();
    final size = qrImage.moduleCount * moduleSize;
    final left = justify.align(command.x.toDouble(), size);
    final darkPaint = Paint()..color = Colors.black;
    final lightPaint = Paint()..color = Colors.white;
    final rect = Rect.fromLTWH(left, command.y.toDouble(), size, size);

    canvas.drawRect(rect, lightPaint);
    for (var row = 0; row < qrImage.moduleCount; row++) {
      for (var col = 0; col < qrImage.moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              left + col * moduleSize,
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
    final png = Uint8List.fromList(
      img.encodePng(_thresholdForPreview(command.image, command.threshold)),
    );
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

  /// Matches printer output: composite onto white stock, then threshold.
  ///
  /// The preview used to paint the source image, so gray and color pixels
  /// appeared on screen even when the CPCL bitmap would print them white.
  static img.Image _thresholdForPreview(img.Image source, int threshold) {
    final gray = img.grayscale(img.Image.from(source));
    final mono = img.Image(width: gray.width, height: gray.height);
    for (final pixel in gray) {
      final alpha = pixel.aNormalized.toDouble().clamp(0.0, 1.0);
      final composited = pixel.r * alpha + 255 * (1 - alpha);
      mono.setPixel(
        pixel.x,
        pixel.y,
        composited <= threshold
            ? img.ColorRgb8(0, 0, 0)
            : img.ColorRgb8(255, 255, 255),
      );
    }
    return mono;
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
      (data.length * (options.width + options.ratio) * 6).toDouble(),
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

enum _FieldJustify { left, center, right }

/// Horizontal placement for text, barcodes, and QR codes.
///
/// `LEFT` keeps the field `x`. `CENTER` and `RIGHT` use the page width when
/// the command has no end column. `CENTER end` centers inside `0..end`.
class _PreviewJustify {
  _PreviewJustify(CpclConfiguration config)
    : pageWidth = config.printWidth.toDouble(),
      _mode = switch (config.alignment) {
        CpclAlignment.center => _FieldJustify.center,
        CpclAlignment.right => _FieldJustify.right,
        CpclAlignment.left || null => _FieldJustify.left,
      };

  final double pageWidth;
  _FieldJustify _mode;
  double? _centerSpan;

  double align(double x, double fieldWidth) {
    final span = _mode == _FieldJustify.center
        ? (_centerSpan ?? pageWidth)
        : pageWidth;
    return switch (_mode) {
      _FieldJustify.left => x,
      _FieldJustify.center => (span - fieldWidth) / 2,
      _FieldJustify.right => span - fieldWidth,
    };
  }

  void applyCommand(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return;
    }
    switch (parts.first.toUpperCase()) {
      case 'LEFT':
        _mode = _FieldJustify.left;
        _centerSpan = null;
        break;
      case 'RIGHT':
        _mode = _FieldJustify.right;
        _centerSpan = null;
        break;
      case 'CENTER':
        _mode = _FieldJustify.center;
        _centerSpan = parts.length > 1 ? double.tryParse(parts[1]) : null;
        break;
    }
  }
}
