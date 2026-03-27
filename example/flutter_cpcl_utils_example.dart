import 'package:flutter_cpcl_utils/flutter_cpcl_utils.dart';

void main() {
  final generator = CpclGenerator()
    ..initialize(const CpclLabelSize(576, 320))
    ..text(20, 30, 'Hello CPCL')
    ..line(20, 70, 300, 70, thickness: 2)
    ..barcode(20, 90, '1234567890')
    ..qrCode(20, 210, 'https://example.com')
    ..form()
    ..print();

  print(generator.preview());
}
