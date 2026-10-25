import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadPdfBytes(Uint8List bytes, String fileName) async {
  // Write to a temp file with the proper filename
  final dir = await getTemporaryDirectory();
  final file = File('\${dir.path}/\$fileName');
  await file.writeAsBytes(bytes);
  
  // Share the file path (preserves the filename when saved)
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
    text: fileName,
  );
}
