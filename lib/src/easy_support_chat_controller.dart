import 'package:flutter/foundation.dart';

import 'easy_support_repository.dart';
import 'models/easy_support_chat_message.dart';
import 'models/easy_support_config.dart';

enum EasySupportChatStatus {
  initial,
  loading,
  ready,
  error,
}

@immutable
class EasySupportChatState {
  const EasySupportChatState({
    required this.status,
    this.messages = const <EasySupportChatMessage>[],
    this.error,
  });

  const EasySupportChatState.initial()
      : this(status: EasySupportChatStatus.initial);

  final EasySupportChatStatus status;
  final List<EasySupportChatMessage> messages;
  final Object? error;

  bool get isLoading => status == EasySupportChatStatus.loading;
}

class EasySupportChatController extends ValueNotifier<EasySupportChatState> {
  EasySupportChatController({
    required EasySupportRepository repository,
  })  : _repository = repository,
        super(const EasySupportChatState.initial());

  final EasySupportRepository _repository;

  Future<void> loadMessages({
    required EasySupportConfig config,
    required String chatId,
    int limit = 20,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) async {
    value = EasySupportChatState(
      status: EasySupportChatStatus.loading,
      messages: value.messages,
    );

    try {
      final response = await _repository.fetchCustomerChatMessages(
        config: config,
        chatId: chatId,
        limit: limit,
        sortOrder: sortOrder,
        sortBy: sortBy,
      );
      final chronologicalMessages = response.data.reversed.toList();
      value = EasySupportChatState(
        status: EasySupportChatStatus.ready,
        messages: chronologicalMessages,
      );
    } catch (error) {
      value = EasySupportChatState(
        status: EasySupportChatStatus.error,
        messages: value.messages,
        error: error,
      );
    }
  }

  void addLocalCustomerMessage({
    required String customerId,
    required String chatId,
    required String body,
  }) {
    final content = body.trim();
    if (content.isEmpty) {
      return;
    }

    final newMessage = EasySupportChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      customerId: customerId,
      content: content,
      type: 'message',
      isSeen: false,
      createdAt: DateTime.now().toIso8601String(),
    );

    final updated = <EasySupportChatMessage>[...value.messages, newMessage];

    value = EasySupportChatState(
      status: EasySupportChatStatus.ready,
      messages: updated,
    );
  }

  void addIncomingMessage(EasySupportChatMessage message) {
    final content = (message.content ?? '').trim();
    if (content.isEmpty && !message.isNotification) {
      return;
    }

    final existing = value.messages;
    if (message.isNotification &&
        existing.any((item) => _isDuplicateNotification(item, message))) {
      return;
    }

    final incomingId = message.id?.trim();
    if (incomingId != null &&
        incomingId.isNotEmpty &&
        existing.any((item) => item.id == incomingId)) {
      return;
    }

    // Some socket events come without id; dedupe by semantic fingerprint.
    if ((incomingId == null || incomingId.isEmpty) &&
        existing.any((item) => _isSemanticallySameMessage(item, message))) {
      return;
    }

    value = EasySupportChatState(
      status: EasySupportChatStatus.ready,
      messages: <EasySupportChatMessage>[...existing, message],
    );
  }

  void ensureGreetingMessage({
    required String greetingMessage,
    required String chatId,
  }) {
    final normalizedGreeting = greetingMessage.trim();
    final normalizedChatId = chatId.trim();
    if (normalizedGreeting.isEmpty || normalizedChatId.isEmpty) {
      return;
    }

    final existing = value.messages;
    final greetingExists = existing.any(
      (item) =>
          (item.content ?? '').trim().toLowerCase() ==
              normalizedGreeting.toLowerCase() &&
          (item.chatId ?? '').trim() == normalizedChatId,
    );
    if (greetingExists) {
      return;
    }

    final greeting = EasySupportChatMessage(
      id: 'local_greeting_$normalizedChatId',
      chatId: normalizedChatId,
      customerId: null,
      agentId: 'system',
      content: normalizedGreeting,
      type: 'message',
      isSeen: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
    );

    value = EasySupportChatState(
      status: value.status == EasySupportChatStatus.initial
          ? EasySupportChatStatus.ready
          : value.status,
      messages: <EasySupportChatMessage>[greeting, ...existing],
      error: value.error,
    );
  }

  bool _isSemanticallySameMessage(
    EasySupportChatMessage a,
    EasySupportChatMessage b,
  ) {
    final aContent = (a.content ?? '').trim().toLowerCase();
    final bContent = (b.content ?? '').trim().toLowerCase();
    if (aContent.isEmpty || bContent.isEmpty || aContent != bContent) {
      return false;
    }

    final aType = (a.type ?? '').trim().toLowerCase();
    final bType = (b.type ?? '').trim().toLowerCase();
    if (aType != bType) {
      return false;
    }

    final aChat = (a.chatId ?? '').trim();
    final bChat = (b.chatId ?? '').trim();
    if (aChat.isNotEmpty && bChat.isNotEmpty && aChat != bChat) {
      return false;
    }

    final aCustomer = (a.customerId ?? '').trim();
    final bCustomer = (b.customerId ?? '').trim();
    if (aCustomer != bCustomer) {
      return false;
    }

    final aAgent = (a.agentId ?? '').trim();
    final bAgent = (b.agentId ?? '').trim();
    if (aAgent != bAgent) {
      return false;
    }

    final aCreatedAt = DateTime.tryParse((a.createdAt ?? '').trim());
    final bCreatedAt = DateTime.tryParse((b.createdAt ?? '').trim());
    if (aCreatedAt != null && bCreatedAt != null) {
      final delta = aCreatedAt.difference(bCreatedAt).inSeconds.abs();
      if (delta > 120) {
        return false;
      }
    }

    return true;
  }

  bool _isDuplicateNotification(
    EasySupportChatMessage a,
    EasySupportChatMessage b,
  ) {
    if (!a.isNotification || !b.isNotification) {
      return false;
    }

    final aContent = (a.content ?? '').trim().toLowerCase();
    final bContent = (b.content ?? '').trim().toLowerCase();
    if (aContent.isEmpty || bContent.isEmpty || aContent != bContent) {
      return false;
    }

    final aChat = (a.chatId ?? '').trim();
    final bChat = (b.chatId ?? '').trim();
    if (aChat.isNotEmpty && bChat.isNotEmpty && aChat != bChat) {
      return false;
    }

    final aCreatedAt = DateTime.tryParse((a.createdAt ?? '').trim());
    final bCreatedAt = DateTime.tryParse((b.createdAt ?? '').trim());
    if (aCreatedAt != null && bCreatedAt != null) {
      final delta = aCreatedAt.difference(bCreatedAt).inSeconds.abs();
      if (delta > 300) {
        return false;
      }
    }

    return true;
  }
}
