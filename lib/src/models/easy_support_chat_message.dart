class EasySupportChatMessage {
  const EasySupportChatMessage({
    this.id,
    this.chatId,
    this.customerId,
    this.replyToId,
    this.mailId,
    this.agentId,
    this.aiBotId,
    this.content,
    this.type,
    this.source,
    this.senderType,
    this.isSeen,
    this.metadata,
    this.createdAt,
    this.attachments = const <dynamic>[],
    this.parentMessage,
  });

  factory EasySupportChatMessage.fromJson(Map<String, dynamic> json) {
    final rawMetadata = json['metadata'];
    final rawAttachments = json['attachments'];
    final rawParentMessage = json['parent_message'];

    return EasySupportChatMessage(
      id: json['id'] as String?,
      chatId: json['chat_id'] as String?,
      customerId: json['customer_id'] as String?,
      replyToId: json['reply_to_id'] as String?,
      mailId: json['mail_id'] as String?,
      agentId: json['agent_id'] as String?,
      aiBotId: json['ai_bot_id'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String?,
      source: json['source'] as String?,
      senderType: json['sender_type'] as String?,
      isSeen: json['is_seen'] as bool?,
      metadata: rawMetadata is Map<String, dynamic>
          ? rawMetadata
          : rawMetadata is Map
              ? Map<String, dynamic>.from(rawMetadata)
              : null,
      createdAt: json['created_at'] as String?,
      attachments: rawAttachments is List ? List<dynamic>.from(rawAttachments) : const <dynamic>[],
      parentMessage: rawParentMessage is Map
          ? EasySupportChatMessage.fromJson(
              Map<String, dynamic>.from(rawParentMessage),
            )
          : null,
    );
  }

  final String? id;
  final String? chatId;
  final String? customerId;
  final String? replyToId;
  final String? mailId;
  final String? agentId;
  final String? aiBotId;
  final String? content;
  final String? type;
  final String? source;
  final String? senderType;
  final bool? isSeen;
  final Map<String, dynamic>? metadata;
  final String? createdAt;
  final List<dynamic> attachments;
  final EasySupportChatMessage? parentMessage;

  bool get isNotification => type == 'notification';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (customerId != null) 'customer_id': customerId,
      if (replyToId != null) 'reply_to_id': replyToId,
      if (mailId != null) 'mail_id': mailId,
      if (agentId != null) 'agent_id': agentId,
      if (aiBotId != null) 'ai_bot_id': aiBotId,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (source != null) 'source': source,
      if (senderType != null) 'sender_type': senderType,
      if (isSeen != null) 'is_seen': isSeen,
      if (metadata != null) 'metadata': metadata,
      if (createdAt != null) 'created_at': createdAt,
      if (attachments.isNotEmpty) 'attachments': List<dynamic>.from(attachments),
      if (parentMessage != null) 'parent_message': parentMessage!.toJson(),
    };
  }
}
