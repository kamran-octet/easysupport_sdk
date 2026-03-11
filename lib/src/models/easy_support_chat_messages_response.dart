import 'easy_support_chat_message.dart';
import 'easy_support_chat_messages_page_info.dart';

class EasySupportChatMessagesResponse {
  const EasySupportChatMessagesResponse({
    required this.success,
    this.data = const <EasySupportChatMessage>[],
    this.pageInfo,
  });

  factory EasySupportChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final messages = rawData is List
        ? rawData
            .whereType<Map>()
            .map(
              (item) => EasySupportChatMessage.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList(growable: false)
        : const <EasySupportChatMessage>[];

    final rawPageInfo = json['page_info'];
    final pageInfo = rawPageInfo is Map
        ? EasySupportChatMessagesPageInfo.fromJson(
            Map<String, dynamic>.from(rawPageInfo),
          )
        : null;

    return EasySupportChatMessagesResponse(
      success: json['success'] == true,
      data: messages,
      pageInfo: pageInfo,
    );
  }

  final bool success;
  final List<EasySupportChatMessage> data;
  final EasySupportChatMessagesPageInfo? pageInfo;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'data': data.map((message) => message.toJson()).toList(growable: false),
      if (pageInfo != null) 'page_info': pageInfo!.toJson(),
    };
  }
}
