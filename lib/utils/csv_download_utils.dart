import 'dart:html' as html;

void downloadCsv(List<String> headers, List<dynamic> rows, String fileName) {
  String escape(dynamic field) {
    final s = field?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
  final buffer = StringBuffer();
  buffer.writeln(headers.map(escape).join(','));
  for (final row in rows) {
    if (row is List) {
      buffer.writeln(row.map(escape).join(','));
    }
  }
  final bytes = buffer.toString().codeUnits;
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrl(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
