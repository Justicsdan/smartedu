import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadHtmlBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(filePath, mimeType: 'text/html', name: fileName)]);
}
