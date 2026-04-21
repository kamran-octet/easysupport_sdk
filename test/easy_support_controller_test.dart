import 'package:easysupport_sdk/src/easy_support_controller.dart';
import 'package:easysupport_sdk/src/easy_support_repository.dart';
import 'package:easysupport_sdk/src/easy_support_retry_scheduler.dart';
import 'package:easysupport_sdk/src/models/easy_support_channel_configuration.dart';
import 'package:easysupport_sdk/src/models/easy_support_chat_messages_response.dart';
import 'package:easysupport_sdk/src/models/easy_support_config.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_action.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = EasySupportConfig(
    baseUrl: 'https://api.example.com',
    channelToken: 'api_test_123',
  );

  test('controller moves to ready when repository GET succeeds', () async {
    final controller = EasySupportController(
      repository: _FakeSuccessRepository(),
    );

    expect(controller.value.status, EasySupportInitStatus.initial);
    final channelConfiguration = await controller.initialize(config);
    expect(controller.value.status, EasySupportInitStatus.ready);
    expect(channelConfiguration.token, 'api_test_123');
    expect(controller.value.channelConfiguration?.name, "Noman's Channel");
  });

  test('controller moves to error when repository GET fails', () async {
    final controller = EasySupportController(
      repository: _FakeFailureRepository(),
    );

    expect(controller.value.status, EasySupportInitStatus.initial);
    await expectLater(controller.initialize(config), throwsException);
    expect(controller.value.status, EasySupportInitStatus.error);
  });

  test('controller retries on network error and succeeds automatically',
      () async {
    final controller = EasySupportController(
      repository: _FakeNetworkThenSuccessRepository(),
      retryScheduler: EasySupportRetryScheduler(
        interval: const Duration(milliseconds: 10),
      ),
    );

    final channelConfiguration = await controller.initialize(config);
    expect(controller.value.status, EasySupportInitStatus.ready);
    expect(channelConfiguration.token, 'api_test_123');
  });
}

class _FakeSuccessRepository implements EasySupportRepository {
  @override
  Future<EasySupportChannelConfiguration> fetchChannelKey(
    EasySupportConfig config,
  ) async {
    return const EasySupportChannelConfiguration(
      name: "Noman's Channel",
      token: 'api_test_123',
      isEmojiEnabled: false,
      isMediaEnabled: false,
      welcomeHeading: 'Hi there ! How can we help you ',
    );
  }

  @override
  Future<EasySupportCustomerResponse> fetchCustomerById({
    required EasySupportConfig config,
    required String customerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EasySupportCustomerResponse> postCustomer({
    required EasySupportConfig config,
    required EasySupportCustomerAction action,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EasySupportChatMessagesResponse> fetchCustomerChatMessages({
    required EasySupportConfig config,
    required String chatId,
    int limit = 20,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> submitFeedback({
    required EasySupportConfig config,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadCustomerMedia({
    required EasySupportConfig config,
    required String workspaceId,
    required String filePath,
    required String fileName,
  }) {
    throw UnimplementedError();
  }
}

class _FakeFailureRepository implements EasySupportRepository {
  @override
  Future<EasySupportChannelConfiguration> fetchChannelKey(
    EasySupportConfig config,
  ) async {
    throw const EasySupportApiException(
      message: 'GET failed',
      statusCode: 500,
    );
  }

  @override
  Future<EasySupportCustomerResponse> fetchCustomerById({
    required EasySupportConfig config,
    required String customerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EasySupportCustomerResponse> postCustomer({
    required EasySupportConfig config,
    required EasySupportCustomerAction action,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EasySupportChatMessagesResponse> fetchCustomerChatMessages({
    required EasySupportConfig config,
    required String chatId,
    int limit = 20,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> submitFeedback({
    required EasySupportConfig config,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadCustomerMedia({
    required EasySupportConfig config,
    required String workspaceId,
    required String filePath,
    required String fileName,
  }) {
    throw UnimplementedError();
  }
}

class _FakeNetworkThenSuccessRepository implements EasySupportRepository {
  int _count = 0;

  @override
  Future<EasySupportChannelConfiguration> fetchChannelKey(
    EasySupportConfig config,
  ) async {
    _count += 1;
    if (_count == 1) {
      throw const EasySupportApiException(
        message: 'No internet',
        statusCode: -1,
        isNetworkError: true,
      );
    }

    return const EasySupportChannelConfiguration(
      name: "Noman's Channel",
      token: 'api_test_123',
    );
  }

  @override
  Future<EasySupportCustomerResponse> fetchCustomerById({
    required EasySupportConfig config,
    required String customerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EasySupportCustomerResponse> postCustomer({
    required EasySupportConfig config,
    required EasySupportCustomerAction action,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<EasySupportChatMessagesResponse> fetchCustomerChatMessages({
    required EasySupportConfig config,
    required String chatId,
    int limit = 20,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> submitFeedback({
    required EasySupportConfig config,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<String> uploadCustomerMedia({
    required EasySupportConfig config,
    required String workspaceId,
    required String filePath,
    required String fileName,
  }) {
    throw UnimplementedError();
  }
}
