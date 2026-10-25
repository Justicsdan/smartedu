// Non-web stub. Uses share_plus on mobile.
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

Future<void> downloadBytesWeb(Uint8List bytes, String filename, {String mimeType = 'application/octet-stream'}) async {
  final dir = await getTemporaryDirectory();
  final file = File('\${dir.path}/\$filename');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path, mimeType: mimeType, name: filename)]);
}

Future<void> downloadTextWeb(String text, String filename, {String mimeType = 'text/plain'}) async {
  await downloadBytesWeb(Uint8List.fromList(text.codeUnits), filename, mimeType: mimeType);
}

void openHtmlInNewTabWeb(String htmlContent) {
  // No-op on mobile.
}

Future<void> downloadAndShareMobile(Uint8List bytes, String filename, {String mimeType = 'application/octet-stream'}) async {
  await downloadBytesWeb(bytes, filename, mimeType: mimeType);
}

Future<void> downloadAndShareTextMobile(String text, String filename, {String mimeType = 'text/plain'}) async {
  await downloadTextWeb(text, filename, mimeType: mimeType);
}
