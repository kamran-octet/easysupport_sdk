import 'package:flutter/material.dart';

class EasySupportActionBar extends StatelessWidget {
  const EasySupportActionBar({
    super.key,
    required this.onPressed,
    required this.label,
    required this.actionColor,
    required this.onActionColor,
    required this.bottomPadding,
  });

  final VoidCallback? onPressed;
  final String label;
  final Color actionColor;
  final Color onActionColor;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final disabledBackground = actionColor.withOpacity(0.45);
    final disabledForeground = onActionColor.withOpacity(0.85);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding + 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: onActionColor,
            disabledBackgroundColor: disabledBackground,
            disabledForegroundColor: disabledForeground,
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
