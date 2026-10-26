import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadHtmlBytes(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)..setAttribute('download', fileName)..click();
  html.Url.revokeObjectUrl(url);
}
