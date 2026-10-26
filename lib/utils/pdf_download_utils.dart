// Cross-platform PDF download utility.
// Web: uses dart:html for browser download.
// Mobile: uses path_provider + share_plus for native share sheet.
export 'pdf_download_utils_stub.dart'
    if (dart.library.html) 'pdf_download_utils_web_impl.dart';
