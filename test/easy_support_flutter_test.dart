import 'package:easysupport_sdk/src/models/easy_support_channel_configuration.dart';
import 'package:easysupport_sdk/src/models/easy_support_chat_messages_response.dart';
import 'package:easysupport_sdk/src/models/easy_support_config.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_action.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_response.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_result.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_session.dart';
import 'package:easysupport_sdk/src/models/easy_support_customer_submission.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes baseUrl and apiBaseUrl', () {
    const config = EasySupportConfig(
      baseUrl: 'https://api.example.com///',
      channelToken: 'api_test_123',
    );

    expect(config.normalizedBaseUrl, 'https://api.example.com/');
    expect(config.normalizedApiBaseUrl, 'https://api.example.com/api/v1');
  });

  test('creates js options with required values', () {
    const config = EasySupportConfig(
      baseUrl: 'https://api.example.com',
      channelToken: 'api_test_123',
      autoOpen: false,
      isEmojiEnabled: false,
    );

    final options = config.toJavaScriptOptions();

    expect(options['channelToken'], 'api_test_123');
    expect(options['baseUrl'], 'https://api.example.com/');
    expect(options['apiBaseUrl'], 'https://api.example.com/api/v1');
    expect(options['autoOpen'], false);
    expect(options['isEmojiEnabled'], false);
    expect(options['isMediaEnabled'], true);
    expect(options['additionalHeaders'], <String, String>{
      'channelkey': 'api_test_123',
    });
  });

  test('always injects channelkey header from channelToken', () {
    const config = EasySupportConfig(
      baseUrl: 'https://api.example.com',
      channelToken: 'api_test_123',
      additionalHeaders: <String, String>{
        'authorization': 'Bearer token',
        'channelkey': 'wrong_value',
      },
    );

    expect(config.resolvedHeaders, <String, String>{
      'authorization': 'Bearer token',
      'channelkey': 'api_test_123',
    });
  });

  test('uses explicit apiBaseUrl when provided', () {
    const config = EasySupportConfig(
      baseUrl: 'https://socket.example.com',
      apiBaseUrl: 'https://backend.example.com/api/v1/',
      channelToken: 'api_test_123',
    );

    expect(config.normalizedApiBaseUrl, 'https://backend.example.com/api/v1');
    expect(
      config.toJavaScriptOptions()['apiBaseUrl'],
      'https://backend.example.com/api/v1',
    );
  });

  test('parses channel response and merges returned configuration', () {
    final response = EasySupportChannelKeyResponse.fromJson(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'name': "Noman's Channel",
        'welcome_heading': 'Hi there ! How can we help you ',
        'is_emoji_enabled': false,
        'is_media_enabled': false,
        'token': 'api_nat1ht02fmlq45lps',
        'is_form_enabled': true,
        'chat_form': <String, dynamic>{
          'id': '1bb2b3b5-7f63-46ab-9b8a-f9755d52cf33',
          'form_message': 'testing',
          'is_active': true,
          'is_email_enabled': true,
          'is_email_required': true,
          'email_field_label': 'Email Id',
          'email_field_placeholder': 'emailAddress',
          'is_phone_enabled': true,
          'is_phone_required': true,
          'phone_field_label': 'Phone number',
          'phone_field_placeholder': 'phoneNumber',
          'is_name_enabled': true,
          'is_name_required': true,
          'name_field_label': 'Full name',
          'name_field_placeholder': 'fullName',
        },
      },
    });

    const inputConfig = EasySupportConfig(
      baseUrl: 'https://api.example.com',
      channelToken: 'api_nat1ht02fmlq45lps',
      widgetTitle: 'Default title',
      isEmojiEnabled: true,
      isMediaEnabled: true,
    );

    final mergedConfig = inputConfig.mergeWithChannelConfiguration(
      response.data!,
    );

    expect(response.success, true);
    expect(response.data?.name, "Noman's Channel");
    expect(response.data?.token, 'api_nat1ht02fmlq45lps');
    expect(response.data?.chatForm?.isEmailRequired, true);
    expect(response.data?.chatForm?.emailFieldLabel, 'Email Id');
    expect(response.data?.hasActiveForm, true);
    expect(mergedConfig.widgetTitle, 'Hi there ! How can we help you ');
    expect(mergedConfig.isEmojiEnabled, false);
    expect(mergedConfig.isMediaEnabled, false);
  });

  test(
      'shows chat form when chat_form is active even if is_form_enabled is false',
      () {
    final response = EasySupportChannelKeyResponse.fromJson(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'is_form_enabled': false,
        'chat_form': <String, dynamic>{
          'is_active': true,
          'is_email_enabled': true,
          'is_email_required': true,
        },
      },
    });

    expect(response.data?.hasActiveForm, true);
  });

  test('parses create-customer response with result object', () {
    final response = EasySupportCustomerResponse.fromJson(<String, dynamic>{
      'success': true,
      'result': <String, dynamic>{
        'id': 'c3034058-70d0-491e-8e8e-1f48a6aebf1f',
        'name': 'John Doe',
        'email': 'john.doe@email.com',
        'phone': '+923001234567',
        'is_blocked': false,
        'workspace_id': '89feb5a3-c054-4111-94f5-eb3a58f409e2',
        'channel_id': 'ad7ccf1c-7250-410a-b741-05103e695b37',
        'created_at': '2026-02-19T06:02:07.899Z',
        'updated_at': '2026-02-19T06:02:07.899Z',
      },
    });

    expect(response.success, true);
    expect(response.customerId, 'c3034058-70d0-491e-8e8e-1f48a6aebf1f');
    expect(response.result?.name, 'John Doe');
    expect(response.result?.email, 'john.doe@email.com');
    expect(response.result?.phone, '+923001234567');
  });

  test('customer models support toJson and fromJson', () {
    final session = EasySupportCustomerSession.fromJson(<String, dynamic>{
      'customer_id': 'customer_1',
      'chat_id': 'chat_1',
    });
    expect(session.toJson(), <String, dynamic>{
      'customer_id': 'customer_1',
      'chat_id': 'chat_1',
    });

    final result = EasySupportCustomerResult.fromJson(<String, dynamic>{
      'id': 'customer_1',
      'name': 'John',
      'email': 'john@example.com',
    });
    expect(result.toJson()['id'], 'customer_1');
    expect(result.toJson()['name'], 'John');

    final submission = EasySupportCustomerSubmission.fromJson(
      <String, dynamic>{
        'customer_id': 'customer_1',
        'name': 'John',
        'email': 'john@example.com',
      },
    );
    expect(submission.toJson()['customer_id'], 'customer_1');
    expect(
      EasySupportCustomerActionJson.fromJson('update'),
      EasySupportCustomerAction.update,
    );
    expect(EasySupportCustomerAction.update.toJson(), 'update');
  });

  test('channel models support toJson and fromJson', () {
    final response = EasySupportChannelKeyResponse.fromJson(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{
        'id': 'channel_1',
        'name': 'Channel',
        'chat_form': <String, dynamic>{
          'id': 'form_1',
          'is_active': true,
          'is_name_enabled': true,
        },
      },
    });

    final serialized = response.toJson();
    expect(serialized['success'], true);
    expect((serialized['data'] as Map<String, dynamic>)['id'], 'channel_1');
    expect(
      ((serialized['data'] as Map<String, dynamic>)['chat_form']
          as Map<String, dynamic>)['id'],
      'form_1',
    );
  });

  test('config model supports toJson and fromJson', () {
    final config = EasySupportConfig.fromJson(<String, dynamic>{
      'base_url': 'https://api.example.com',
      'channel_token': 'api_test_123',
      'additional_headers': <String, dynamic>{'x-test': 1},
    });

    final serialized = config.toJson();
    expect(serialized['base_url'], 'https://api.example.com');
    expect(serialized['channel_token'], 'api_test_123');
    expect(
      serialized['additional_headers'],
      <String, String>{'x-test': '1'},
    );
  });

  test('parses chat messages response with page_info', () {
    final response = EasySupportChatMessagesResponse.fromJson(<String, dynamic>{
      'success': true,
      'data': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '42ad0dad-cf05-45db-a515-a813fadd5eb8',
          'chat_id': '96177bd5-ddbc-4810-bae8-643f20ca3123',
          'customer_id': 'c9a9f69c-4d37-4a1e-ba18-a5d4a56cc752',
          'agent_id': null,
          'content': 'hi',
          'type': 'message',
          'is_seen': true,
          'created_at': '2026-02-19T06:32:52.904Z',
        },
        <String, dynamic>{
          'id': '75675f43-8d58-4019-af2d-bde7fa91d93c',
          'chat_id': '96177bd5-ddbc-4810-bae8-643f20ca3123',
          'customer_id': null,
          'agent_id': '2821a505-8b63-4975-868f-6f3f6a44b79c',
          'content': 'Agent joined the chat',
          'type': 'notification',
          'is_seen': true,
          'created_at': '2026-02-19T06:30:37.808Z',
        },
      ],
      'page_info': <String, dynamic>{
        'limit': 20,
        'has_more': false,
        'next_cursor': null,
      },
    });

    expect(response.success, true);
    expect(response.data.length, 2);
    expect(response.data.first.content, 'hi');
    expect(response.data.last.isNotification, true);
    expect(response.pageInfo?.limit, 20);
    expect(response.pageInfo?.hasMore, false);

    final encoded = response.toJson();
    expect(encoded['success'], true);
    expect((encoded['data'] as List).length, 2);
    expect(
      (encoded['page_info'] as Map<String, dynamic>)['has_more'],
      false,
    );
  });
}
