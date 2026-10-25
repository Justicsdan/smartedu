// Cross-platform image picker using image_picker package.
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

Future<Uint8List?> pickImageBytes({double maxWidth = 1024, double maxHeight = 1024}) async {
  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    imageQuality: 85,
  );
  if (xfile == null) return null;
  return await xfile.readAsBytes();
}
