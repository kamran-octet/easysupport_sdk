import 'package:flutter/material.dart';

import 'easy_support_color_utils.dart';

class EasySupportFormCard extends StatelessWidget {
  const EasySupportFormCard({
    super.key,
    required this.primaryColor,
    required this.children,
    this.title,
  });

  final Color primaryColor;
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final borderColor = EasySupportColorUtils.blend(
        primaryColor, const Color(0xFFE5E7EB), 0.86);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (title != null && title!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ...children,
        ],
      ),
    );
  }
}
