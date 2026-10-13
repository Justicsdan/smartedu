import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildJitsiView(String roomName, String userDisplayName, String schoolName, bool isProctoring) {
  String jitsiUrl = 
      'https://meet.jit.si/$roomName'
      '?userInfo.displayName="$userDisplayName"'
      '&config.prejoinPageEnabled=false'
      '&config.disableDeepLinking=true'
      '&interfaceConfig.SHOW_JITSI_WATERMARK=false'
      '&interfaceConfig.SHOW_WATERMARK_FOR_GUESTS=false';

    if (isProctoring) {
      // Exam Mode: Student mic muted, camera on. Chat removed to prevent full-screen overlay covering the exam.
      // "Raise Hand" is enabled so the student can signal the teacher for help.
      jitsiUrl += '&config.startWithVideoMuted=false'
                  '&config.startWithAudioMuted=true'
                  '&interfaceConfig.TOOLBAR_BUTTONS=["camera","raisehand"]';
    } else {
      // Class Mode: Tile view, raise hand, normal controls
      jitsiUrl += '&interfaceConfig.TOOLBAR_BUTTONS=["microphone","camera","desktop","chat","raisehand","tileview"]'
                  '&config.startWithVideoMuted=false'
                  '&config.startWithAudioMuted=false';
    }

  final controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(jitsiUrl));

  return Stack(
    children: [
      WebViewWidget(controller: controller),
      Positioned(
        top: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            schoolName,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );
}
