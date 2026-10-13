import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

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

  final String viewType = 'jitsi-embed-$roomName';
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final iframe = html.IFrameElement()
        ..src = jitsiUrl
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'camera; microphone; fullscreen; display-capture; autoplay';
      return iframe;
    },
  );

  return Stack(
    children: [
      HtmlElementView(viewType: viewType),
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
