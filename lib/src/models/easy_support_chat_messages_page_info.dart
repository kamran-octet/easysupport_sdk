class EasySupportChatMessagesPageInfo {
  const EasySupportChatMessagesPageInfo({
    this.limit,
    this.hasMore,
    this.nextCursor,
  });

  factory EasySupportChatMessagesPageInfo.fromJson(Map<String, dynamic> json) {
    return EasySupportChatMessagesPageInfo(
      limit: json['limit'] as int?,
      hasMore: json['has_more'] as bool?,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  final int? limit;
  final bool? hasMore;
  final String? nextCursor;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (hasMore != null) 'has_more': hasMore,
      if (nextCursor != null) 'next_cursor': nextCursor,
    };
  }
}
