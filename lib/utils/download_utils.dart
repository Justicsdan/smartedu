// Cross-platform download utility.
// Web: browser download via dart:html. Mobile: share_plus.
export 'download_utils_stub.dart'
    if (dart.library.html) 'download_utils_web_impl.dart';
