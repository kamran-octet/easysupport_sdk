import 'package:flutter/material.dart';

class EasySupportColorUtils {
  const EasySupportColorUtils._();

  static Color parseHexColor(String? hex, {required Color fallback}) {
    final raw = hex?.trim();
    if (raw == null || raw.isEmpty) {
      return fallback;
    }

    var value = raw.replaceFirst('#', '');
    if (value.length == 3) {
      value = value.split('').map((char) => '$char$char').join();
    }
    if (value.length == 6) {
      value = 'FF$value';
    }
    if (value.length != 8) {
      return fallback;
    }

    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) {
      return fallback;
    }
    return Color(parsed);
  }

  static Color blend(Color first, Color second, double amount) {
    return Color.lerp(first, second, amount) ?? second;
  }

  static Color onColor(Color background) {
    return background.computeLuminance() > 0.5
        ? const Color(0xFF111827)
        : Colors.white;
  }
}
