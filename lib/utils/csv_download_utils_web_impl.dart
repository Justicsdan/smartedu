import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadCsvBytes(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)..setAttribute('download', fileName)..click();
  html.Url.revokeObjectUrl(url);
}

Future<void> downloadCsv(List<dynamic> headers, List<List<dynamic>> rows, String fileName) async {
  final buffer = StringBuffer();
  buffer.writeln(headers.map((h) => '"${h.toString().replaceAll('"', '""')}"').join(','));
  for (final row in rows) {
    buffer.writeln(row.map((v) => '"${v.toString().replaceAll('"', '""')}"').join(','));
  }
  final bytes = Uint8List.fromList(buffer.toString().codeUnits);
  await downloadCsvBytes(bytes, fileName);
}
