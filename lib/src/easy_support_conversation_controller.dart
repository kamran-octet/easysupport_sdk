import 'easy_support_customer_local_storage.dart';
import 'easy_support_repository.dart';
import 'easy_support_socket_service.dart';
import 'easy_support_socket_service_resolver.dart';
import 'models/easy_support_config.dart';
import 'models/easy_support_customer_action.dart';
import 'models/easy_support_customer_response.dart';
import 'models/easy_support_customer_session.dart';
import 'models/easy_support_customer_submission.dart';

class EasySupportConversationController {
  EasySupportConversationController({
    required EasySupportRepository repository,
    required EasySupportCustomerLocalStorage localStorage,
    EasySupportSocketService? socketService,
  })  : _repository = repository,
        _localStorage = localStorage,
        _socketService = socketService ?? EasySupportSocketServiceResolver();

  final EasySupportRepository _repository;
  final EasySupportCustomerLocalStorage _localStorage;
  final EasySupportSocketService _socketService;

  Future<EasySupportCustomerSession> loadSession() {
    return _localStorage.readSession();
  }

  Future<EasySupportCustomerResponse> fetchCustomerById({
    required EasySupportConfig config,
    required String customerId,
  }) {
    return _repository.fetchCustomerById(
      config: config,
      customerId: customerId,
    );
  }

  Future<EasySupportCustomerSession> startConversation({
    required EasySupportConfig config,
    required EasySupportCustomerSubmission submission,
    String? channelId,
  }) async {
    final existingSession = await _localStorage.readSession();
    final resolvedChannelId =
        _normalize(channelId) ?? existingSession.channelId;

    final action = submission.hasCustomerId
        ? EasySupportCustomerAction.update
        : EasySupportCustomerAction.create;
    final requestBody = submission.toRequestBody(action: action);
    final response = await _repository.postCustomer(
      config: config,
      action: action,
      body: requestBody,
    );

    final resolvedCustomerId = response.customerId ?? submission.customerId;
    if (resolvedCustomerId == null || resolvedCustomerId.trim().isEmpty) {
      throw const EasySupportApiException(
        message: 'Customer API response is missing customer_id',
        statusCode: -1,
      );
    }
    final resolvedChatId = await _resolveChatId(
      config: config,
      customerId: resolvedCustomerId,
      apiChatId: response.chatId,
    );

    final session = EasySupportCustomerSession(
      customerId: resolvedCustomerId,
      chatId: resolvedChatId,
      channelId: resolvedChannelId,
    );

    await _localStorage.writeSession(session);
    return session;
  }

  Future<String> _resolveChatId({
    required EasySupportConfig config,
    required String customerId,
    required String? apiChatId,
  }) async {
    try {
      return await _socketService.joinChat(
        config: config,
        customerId: customerId,
        chatId: apiChatId,
      );
    } catch (_) {
      if (apiChatId != null && apiChatId.trim().isNotEmpty) {
        return apiChatId;
      }
      rethrow;
    }
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
