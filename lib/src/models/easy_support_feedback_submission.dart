class EasySupportFeedbackSubmission {
  const EasySupportFeedbackSubmission({
    required this.rating,
    required this.comment,
  });

  factory EasySupportFeedbackSubmission.fromJson(Map<String, dynamic> json) {
    return EasySupportFeedbackSubmission(
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
    );
  }

  final int rating;
  final String comment;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rating': rating,
      'comment': comment,
    };
  }
}
