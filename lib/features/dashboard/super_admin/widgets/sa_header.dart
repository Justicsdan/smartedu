import 'package:flutter/material.dart';

class SaHeader extends StatelessWidget {
  final String adminName;
  final int schoolCount;

  const SaHeader({
    super.key,
    this.adminName = 'Platform Owner',
    this.schoolCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Dashboard",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3C72),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Manage all schools across the globe",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
