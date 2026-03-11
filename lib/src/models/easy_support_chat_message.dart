class EasySupportChatMessage {
  const EasySupportChatMessage({
    this.id,
    this.chatId,
    this.customerId,
    this.agentId,
    this.content,
    this.type,
    this.isSeen,
    this.createdAt,
  });

  factory EasySupportChatMessage.fromJson(Map<String, dynamic> json) {
    return EasySupportChatMessage(
      id: json['id'] as String?,
      chatId: json['chat_id'] as String?,
      customerId: json['customer_id'] as String?,
      agentId: json['agent_id'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String?,
      isSeen: json['is_seen'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }

  final String? id;
  final String? chatId;
  final String? customerId;
  final String? agentId;
  final String? content;
  final String? type;
  final bool? isSeen;
  final String? createdAt;

  bool get isNotification => type == 'notification';

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (chatId != null) 'chat_id': chatId,
      if (customerId != null) 'customer_id': customerId,
      if (agentId != null) 'agent_id': agentId,
      if (content != null) 'content': content,
      if (type != null) 'type': type,
      if (isSeen != null) 'is_seen': isSeen,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
