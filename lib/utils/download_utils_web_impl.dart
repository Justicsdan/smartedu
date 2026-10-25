// Web implementation using dart:html (only loaded on web).
import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytesWeb(Uint8List bytes, String filename, {String mimeType = 'application/octet-stream'}) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void downloadTextWeb(String text, String filename, {String mimeType = 'text/plain'}) {
  downloadBytesWeb(Uint8List.fromList(text.codeUnits), filename, mimeType: mimeType);
}

void openHtmlInNewTabWeb(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadAndShareMobile(Uint8List bytes, String filename, {String mimeType = 'application/octet-stream'}) async {
  downloadBytesWeb(bytes, filename, mimeType: mimeType);
}

Future<void> downloadAndShareTextMobile(String text, String filename, {String mimeType = 'text/plain'}) async {
  downloadTextWeb(text, filename, mimeType: mimeType);
}
