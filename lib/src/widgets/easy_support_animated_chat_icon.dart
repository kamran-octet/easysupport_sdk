import 'dart:math' as math;

import 'package:flutter/material.dart';

class EasySupportAnimatedChatIcon extends StatefulWidget {
  const EasySupportAnimatedChatIcon({
    super.key,
    required this.borderColor,
  });

  final Color borderColor;

  @override
  State<EasySupportAnimatedChatIcon> createState() =>
      _EasySupportAnimatedChatIconState();
}

class _EasySupportAnimatedChatIconState
    extends State<EasySupportAnimatedChatIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final floatOffset = math.sin(t * 2 * math.pi) * 3.0;
        final pulseScale = 1 + (0.02 * math.sin(t * 2 * math.pi));
        final glowOpacity = 0.12 + (0.08 * (math.sin(t * 2 * math.pi) + 1) / 2);

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: pulseScale,
            child: Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: widget.borderColor),
                boxShadow: [
                  BoxShadow(
                    color: widget.borderColor.withOpacity(glowOpacity),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        size: 62,
        color: Color(0xFF111827),
      ),
    );
  }
}
