import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

void main() {
  final generator = CpclGenerator()
    ..initialize(const CpclLabelSize(576, 320))
    ..speed(3)
    ..tone(1)
    ..contrast(2)
    ..country(CpclCountryCode.usa)
    ..box(10, 10, 566, 310, thickness: 2)
    ..line(20, 60, 556, 60, thickness: 2)
    ..text(
      24,
      24,
      'SHIP TO',
      style: const CpclTextStyle(
        font: CpclFont.font4,
        size: 0,
        xMultiplier: 2,
        yMultiplier: 2,
      ),
    )
    ..text(24, 76, 'Customer: John Doe')
    ..text(24, 106, 'Phone: 012 345 678')
    ..text(24, 136, 'Address: 123 Market Street')
    ..text(24, 166, 'Phnom Penh, Cambodia')
    ..inverseLine(22, 214, 340, 92)
    ..line(20, 206, 556, 206, thickness: 1)
    ..barcode(
      24,
      220,
      'PKG-2026-0001',
      options: const CpclBarcodeOptions(
        type: CpclBarcodeType.code128,
        height: 80,
      ),
    )
    ..qrCode(
      390,
      76,
      'https://tracking.example.com/PKG-2026-0001',
      options: const CpclQrCodeOptions(
        ecc: CpclQrErrorCorrection.high,
        unit: 7,
      ),
    )
    ..form()
    ..print();

  final bytes = generator.build();
  assert(bytes.isNotEmpty);
}
