import 'package:flutter/widgets.dart';

class JitsiEmbedView extends StatelessWidget {
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
  Widget build(BuildContext context) => const SizedBox.shrink();
}
