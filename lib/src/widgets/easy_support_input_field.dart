import 'package:flutter/material.dart';

import 'easy_support_color_utils.dart';

class EasySupportInputField extends StatelessWidget {
  const EasySupportInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.requiredField,
    required this.keyboardType,
    required this.validator,
    required this.primaryColor,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final bool requiredField;
  final TextInputType keyboardType;
  final String? Function(String?) validator;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final starColor =
        EasySupportColorUtils.blend(primaryColor, Colors.white, 0.2);
    final displayLabel = _normalizeLabel(label);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: displayLabel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
              children: [
                if (requiredField)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: starColor),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: placeholder,
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 1.4),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _normalizeLabel(String value) {
    return value.trim().replaceFirst(RegExp(r'\s*\*+$'), '');
  }
}
