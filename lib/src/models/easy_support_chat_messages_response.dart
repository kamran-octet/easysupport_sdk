import 'easy_support_chat_message.dart';
import 'easy_support_chat_messages_page_info.dart';

enum EasySupportChatStatus {
  closed('closed'),
  inProgress('in_progress'),
  open('open'),
  unknown('unknown');

  const EasySupportChatStatus(this.value);

  final String value;

  static EasySupportChatStatus? fromValue(String? value) {
    if (value == null) {
      return null;
    }

    for (final status in values) {
      if (status.value == value) {
        return status;
      }
    }

    return EasySupportChatStatus.unknown;
  }
}

class EasySupportChatSummary {
  const EasySupportChatSummary({
    this.id,
    this.status,
  });

  factory EasySupportChatSummary.fromJson(Map<String, dynamic> json) {
    return EasySupportChatSummary(
      id: json['id'] as String?,
      status: EasySupportChatStatus.fromValue(json['status'] as String?),
    );
  }

  final String? id;
  final EasySupportChatStatus? status;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (status != null) 'status': status!.value,
    };
  }
}

class EasySupportChatMessagesResponse {
  const EasySupportChatMessagesResponse({
    required this.success,
    this.data = const <EasySupportChatMessage>[],
    this.chat,
    this.pageInfo,
  });

  factory EasySupportChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<EasySupportChatMessage> messages = const <EasySupportChatMessage>[];
    EasySupportChatSummary? chat;

    if (rawData is List) {
      messages = rawData
          .whereType<Map>()
          .map(
            (item) => EasySupportChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } else if (rawData is Map) {
      final rawMessages = rawData['messages'];
      final rawChat = rawData['chat'];

      if (rawMessages is List) {
        messages = rawMessages
            .whereType<Map>()
            .map(
              (item) => EasySupportChatMessage.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false);
      }

      if (rawChat is Map) {
        chat = EasySupportChatSummary.fromJson(
          Map<String, dynamic>.from(rawChat),
        );
      }
    }

    final rawPageInfo = json['page_info'];
    final pageInfo = rawPageInfo is Map
        ? EasySupportChatMessagesPageInfo.fromJson(
            Map<String, dynamic>.from(rawPageInfo),
          )
        : null;

    return EasySupportChatMessagesResponse(
      success: json['success'] == true,
      data: messages,
      chat: chat,
      pageInfo: pageInfo,
    );
  }

  final bool success;
  final List<EasySupportChatMessage> data;
  final EasySupportChatSummary? chat;
  final EasySupportChatMessagesPageInfo? pageInfo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'data': <String, dynamic>{
        'messages': data.map((message) => message.toJson()).toList(
              growable: false,
            ),
        if (chat != null) 'chat': chat!.toJson(),
      },
      if (pageInfo != null) 'page_info': pageInfo!.toJson(),
    };
  }
}
