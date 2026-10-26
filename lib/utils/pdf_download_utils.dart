import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadPdfBytes(Uint8List bytes, String fileName) async {
  // Write to a temp file with the proper filename
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  
  // Verify the file was written
  final exists = await file.exists();
  if (!exists) {
    throw Exception('Failed to write PDF file: $filePath');
  }
  
  // Share the file (this opens the share dialog)
  await Share.shareXFiles(
    [XFile(filePath, mimeType: 'application/pdf', name: fileName)],
    text: fileName,
  );
}
