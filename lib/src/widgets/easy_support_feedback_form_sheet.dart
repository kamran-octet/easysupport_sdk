import 'package:flutter/material.dart';

import '../models/easy_support_feedback_submission.dart';

class EasySupportFeedbackFormSheet extends StatefulWidget {
  const EasySupportFeedbackFormSheet({
    super.key,
    required this.primaryColor,
    required this.feedbackMessage,
    required this.showStars,
  });

  final Color primaryColor;
  final String? feedbackMessage;
  final bool showStars;

  @override
  State<EasySupportFeedbackFormSheet> createState() =>
      _EasySupportFeedbackFormSheetState();
}

class _EasySupportFeedbackFormSheetState
    extends State<EasySupportFeedbackFormSheet> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !widget.showStars || _rating > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        16,
        18,
        18 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rate your conversation',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (widget.feedbackMessage ?? 'feedback form').trim().isEmpty
                ? 'feedback form'
                : widget.feedbackMessage!.trim(),
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF6B7280),
            ),
          ),
          if (widget.showStars) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(5, (index) {
                final starIndex = index + 1;
                final selected = _rating >= starIndex;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                  iconSize: 52,
                  padding: EdgeInsets.zero,
                  splashRadius: 28,
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: TextField(
              controller: _commentController,
              minLines: 4,
              maxLines: 4,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(18),
                hintText: 'Share your experience with the agent',
                hintStyle: TextStyle(
                  color: Color(0xFF737373),
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 280,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () {
                        Navigator.of(context).pop(
                          EasySupportFeedbackSubmission(
                            rating: _rating,
                            comment: _commentController.text.trim(),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF87171),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFF87171).withOpacity(0.45),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text(
                  'Submit Feedback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
