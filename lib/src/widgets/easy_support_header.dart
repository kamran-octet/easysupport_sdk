import 'package:flutter/material.dart';

import 'easy_support_color_utils.dart';

class EasySupportHeader extends StatelessWidget {
  const EasySupportHeader({
    super.key,
    required this.title,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.onClose,
    required this.isFullScreen,
  });

  final String title;
  final Color primaryColor;
  final Color onPrimaryColor;
  final VoidCallback onClose;
  final bool isFullScreen;

  @override
  Widget build(BuildContext context) {
    final closeBackground =
        EasySupportColorUtils.blend(primaryColor, Colors.white, 0.7);
    final closeIconColor =
        EasySupportColorUtils.blend(onPrimaryColor, Colors.white, 0.12);
    final shape = isFullScreen
        ? const BorderRadius.vertical(bottom: Radius.circular(26))
        : const BorderRadius.vertical(
            top: Radius.circular(30),
            bottom: Radius.circular(22),
          );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EasySupportColorUtils.blend(primaryColor, Colors.black, 0.08),
            EasySupportColorUtils.blend(primaryColor, Colors.white, 0.03),
          ],
        ),
        borderRadius: shape,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 18, 16, 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onPrimaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: closeBackground,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  color: closeIconColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
