import 'package:shared_preferences/shared_preferences.dart';

import 'models/easy_support_customer_session.dart';

abstract class EasySupportCustomerLocalStorage {
  Future<EasySupportCustomerSession> readSession();

  Future<void> writeSession(EasySupportCustomerSession session);

  Future<void> writeChannelId(String? channelId) async {}
}

class EasySupportSharedPrefsCustomerLocalStorage
    implements EasySupportCustomerLocalStorage {
  static const String _customerIdKey = 'easy_support_customer_id';
  static const String _chatIdKey = 'easy_support_chat_id';
  static const String _channelIdKey = 'easy_support_channel_id';

  @override
  Future<EasySupportCustomerSession> readSession() async {
    final preferences = await SharedPreferences.getInstance();
    final customerId = _normalize(preferences.getString(_customerIdKey));
    final chatId = _normalize(preferences.getString(_chatIdKey));
    final channelId = _normalize(preferences.getString(_channelIdKey));
    return EasySupportCustomerSession(
      customerId: customerId,
      chatId: chatId,
      channelId: channelId,
    );
  }

  @override
  Future<void> writeSession(EasySupportCustomerSession session) async {
    final preferences = await SharedPreferences.getInstance();

    if (session.hasCustomerId) {
      await preferences.setString(_customerIdKey, session.customerId!.trim());
    } else {
      await preferences.remove(_customerIdKey);
    }

    if (session.hasChatId) {
      await preferences.setString(_chatIdKey, session.chatId!.trim());
    } else {
      await preferences.remove(_chatIdKey);
    }

    await writeChannelId(session.channelId);
  }

  @override
  Future<void> writeChannelId(String? channelId) async {
    final preferences = await SharedPreferences.getInstance();
    final normalizedChannelId = _normalize(channelId);
    if (normalizedChannelId != null) {
      await preferences.setString(_channelIdKey, normalizedChannelId);
    } else {
      await preferences.remove(_channelIdKey);
    }
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
