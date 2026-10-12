import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

Widget buildJitsiView(String roomName, String userDisplayName, String schoolName) {
  final String jitsiUrl = 
      'https://meet.jit.si/$roomName'
      '?userInfo.displayName="$userDisplayName"'
      '&config.prejoinPageEnabled=false'
      '&interfaceConfig.SHOW_JITSI_WATERMARK=false'
      '&interfaceConfig.SHOW_WATERMARK_FOR_GUESTS=false'
      '&interfaceConfig.TOOLBAR_BUTTONS=["microphone","camera","desktop","chat","raisehand","tileview"]';

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
