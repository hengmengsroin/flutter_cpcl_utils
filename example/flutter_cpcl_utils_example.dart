import 'package:flutter/material.dart';
import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

void main() {
  runApp(const PreviewExampleApp());
}

class PreviewExampleApp extends StatelessWidget {
  const PreviewExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final generator = CpclGenerator(
      config: const CpclConfiguration(
        printWidth: 406,
        labelLength: 203,
        printDensity: CpclPrintDensity.d8,
      ),
      commands: const [
        CpclBox(x0: 8, y0: 8, x1: 398, y1: 195, thickness: 2),
        CpclText(x: 20, y: 20, text: 'Hello World!'),
        CpclLine(x0: 20, y0: 50, x1: 386, y1: 50, thickness: 2),
        CpclBarcode(
          x: 20,
          y: 70,
          data: '12345',
          options: CpclBarcodeOptions(height: 50),
        ),
        CpclQrCode(x: 300, y: 70, data: 'https://example.com'),
      ],
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('CPCL Preview')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CpclPreview(generator: generator),
          ),
        ),
      ),
    );
  }
}
