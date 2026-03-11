import 'models/easy_support_chat_emit_payload.dart';

abstract class EasySupportChatSocketConnection {
  Future<void> sendChatMessage(EasySupportChatEmitPayload payload,
      {Duration timeout});

  Future<void> leaveChat(String chatId, {Duration timeout});

  Future<void> dispose();
}
