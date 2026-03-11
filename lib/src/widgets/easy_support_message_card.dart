import 'package:flutter/material.dart';

import 'easy_support_color_utils.dart';

class EasySupportMessageCard extends StatelessWidget {
  const EasySupportMessageCard({
    super.key,
    required this.message,
    required this.primaryColor,
  });

  final String message;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final border =
        EasySupportColorUtils.blend(primaryColor, Colors.white, 0.84);
    final iconBackground =
        EasySupportColorUtils.blend(primaryColor, Colors.white, 0.86);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_chat_unread_outlined,
              size: 18,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
