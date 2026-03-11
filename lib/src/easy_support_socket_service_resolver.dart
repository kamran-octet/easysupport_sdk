import 'easy_support_socket_service.dart';
import 'easy_support_web_socket_channel_service.dart';
import 'models/easy_support_chat_emit_payload.dart';
import 'models/easy_support_chat_message.dart';
import 'models/easy_support_config.dart';
import 'easy_support_chat_socket_connection.dart';

class EasySupportSocketServiceResolver implements EasySupportSocketService {
  EasySupportSocketServiceResolver({
    EasySupportSocketService? socketIoService,
    EasySupportSocketService? webSocketChannelService,
  })  : _socketIoService = socketIoService ?? EasySupportSocketIoService(),
        _webSocketChannelService =
            webSocketChannelService ?? EasySupportWebSocketChannelService();

  final EasySupportSocketService _socketIoService;
  final EasySupportSocketService _webSocketChannelService;

  EasySupportSocketService _resolve(EasySupportConfig config) {
    if (config.useWebSocketChannel) {
      return _webSocketChannelService;
    }
    return _socketIoService;
  }

  @override
  Future<String> joinChat({
    required EasySupportConfig config,
    required String customerId,
    String? chatId,
  }) {
    return _resolve(config).joinChat(
      config: config,
      customerId: customerId,
      chatId: chatId,
    );
  }

  @override
  Future<EasySupportChatSocketConnection> connectToChat({
    required EasySupportConfig config,
    required String customerId,
    required String chatId,
    required void Function(EasySupportChatMessage message) onMessage,
    void Function(Object error)? onError,
  }) {
    return _resolve(config).connectToChat(
      config: config,
      customerId: customerId,
      chatId: chatId,
      onMessage: onMessage,
      onError: onError,
    );
  }

  @override
  Future<void> sendChatMessage({
    required EasySupportConfig config,
    required EasySupportChatEmitPayload payload,
  }) {
    return _resolve(config).sendChatMessage(
      config: config,
      payload: payload,
    );
  }
}
