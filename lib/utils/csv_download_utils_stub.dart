import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadCsvBytes(Uint8List bytes, String fileName) async {
  final dir = await getTemporaryDirectory();
  final filePath = '${dir.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(filePath, mimeType: 'text/csv', name: fileName)]);
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
