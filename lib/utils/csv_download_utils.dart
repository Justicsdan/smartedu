// Cross-platform CSV download utility.
// Web: uses dart:html for browser download.
// Mobile: uses path_provider + share_plus for native share sheet.
export 'csv_download_utils_stub.dart'
    if (dart.library.html) 'csv_download_utils_web_impl.dart';
