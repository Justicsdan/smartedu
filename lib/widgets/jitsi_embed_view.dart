import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class JitsiEmbedView extends StatelessWidget {
  final String roomName;
  final String userDisplayName;
  final String schoolName;

  const JitsiEmbedView({
    Key? key,
    required this.roomName,
    required this.userDisplayName,
    required this.schoolName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String jitsiUrl = 
        'https://meet.jit.si/$roomName'
        '?userInfo.displayName="$userDisplayName"'
        '&config.prejoinPageEnabled=false'
        '&interfaceConfig.SHOW_JITSI_WATERMARK=false'
        '&interfaceConfig.SHOW_WATERMARK_FOR_GUESTS=false'
        '&interfaceConfig.TOOLBAR_BUTTONS=["microphone","camera","desktop","chat","raisehand","tileview"]';

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
}
