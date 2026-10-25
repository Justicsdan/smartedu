import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JitsiEmbedView extends StatefulWidget {
  final String roomName;
  final String? displayName;
  final String? userDisplayName;
  final String? schoolName;
  final bool isProctoring;

  const JitsiEmbedView({
    Key? key,
    required this.roomName,
    this.displayName,
    this.userDisplayName,
    this.schoolName,
    this.isProctoring = false,
  }) : super(key: key);

  @override
  State<JitsiEmbedView> createState() => _JitsiEmbedViewState();
}

class _JitsiEmbedViewState extends State<JitsiEmbedView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(_buildUrl()));
  }

  String _buildUrl() {
    final name = widget.userDisplayName ?? widget.schoolName ?? widget.displayName ?? 'Guest';
    final params = <String, String>{
      'config.disableDeepLinking': 'true',
      'config.startWithAudioMuted': 'true',
      'config.startWithVideoMuted': 'false',
      'userInfo.displayName': name,
    };
    if (widget.isProctoring) {
      params['config.disableChat'] = 'true';
      params['config.enableRaiseHand'] = 'true';
    }
    final query = params.entries.map((e) => '\${e.key}=\${Uri.encodeComponent(e.value)}').join('&');
    return 'https://meet.jit.si/\${widget.roomName}?\$query';
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}
