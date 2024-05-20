import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

Future<String> scanBarcode() async {
  try {
    var ScanMode;
    var FlutterBarcodeScanner;
    String result = await FlutterBarcodeScanner.scanBarcode(
      '#ff6666',
      'Cancel',
      true,
      ScanMode.BARCODE,
    );
    return result;
  } catch (e) {
    print('Error scanning barcode: $e');
    return '';
  }
}
