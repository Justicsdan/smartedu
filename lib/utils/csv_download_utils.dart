import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

void downloadCsv(List<String> headers, List<List<dynamic>> rows, [String fileName = 'report.csv']) {
  final buffer = StringBuffer();
  buffer.writeln(headers.join(','));
  for (final row in rows) {
    buffer.writeln(row.map((e) => e?.toString() ?? '').join(','));
  }
  final bytes = Uint8List.fromList(buffer.toString().codeUnits);
  Share.shareXFiles([XFile.fromData(bytes, name: fileName, mimeType: 'text/csv')]);
}
