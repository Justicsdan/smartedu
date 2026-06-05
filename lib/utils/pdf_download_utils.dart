import 'dart:html' as html;
import 'dart:typed_data';

/// Downloads PDF bytes as a file on Flutter Web.
/// Replaces Printing.layoutPdf which is broken on Flutter 3.38+.
void downloadPdfBytes(Uint8List bytes, String fileName) {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrl(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
