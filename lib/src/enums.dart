enum CpclRotation {
  angle0('TEXT'),
  angle90('TEXT90'),
  angle180('TEXT180'),
  angle270('TEXT270');

  const CpclRotation(this.textCommand);

  final String textCommand;
}

enum CpclFont {
  font0(0),
  font1(1),
  font2(2),
  font3(3),
  font4(4),
  font5(5),
  font6(6),
  font7(7);

  const CpclFont(this.value);

  final int value;
}

enum CpclBarcodeType {
  code128('128'),
  code39('39'),
  ean13('EAN13'),
  ean8('EAN8'),
  upcA('UPCA'),
  upcE('UPCE'),
  codabar('CODABAR'),
  interleaved2of5('I2OF5');

  const CpclBarcodeType(this.value);

  final String value;
}

enum CpclQrErrorCorrection {
  low('L'),
  medium('M'),
  quartile('Q'),
  high('H');

  const CpclQrErrorCorrection(this.value);

  final String value;
}

enum CpclCountryCode {
  usa('USA'),
  france('FRANCE'),
  germany('GERMANY'),
  uk('UK'),
  spain('SPAIN'),
  italy('ITALY'),
  sweden('SWEDEN'),
  norway('NORWAY');

  const CpclCountryCode(this.value);

  final String value;
}
