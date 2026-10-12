import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

Future<void> downloadPdfBytes(Uint8List bytes, String fileName) async {
  await Share.shareXFiles(
    [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
    text: fileName,
  );
}
