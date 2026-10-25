// Cross-platform router for Jitsi embed view.
// Web: HTML iframe via dart:html (jitsi_embed_view_web.dart)
// Mobile: WebView (jitsi_embed_view_mobile.dart)
// Stub: no-op (jitsi_embed_view_stub.dart)
export 'jitsi_embed_view_stub.dart'
    if (dart.library.html) 'jitsi_embed_view_web.dart'
    if (dart.library.io) 'jitsi_embed_view_mobile.dart';
