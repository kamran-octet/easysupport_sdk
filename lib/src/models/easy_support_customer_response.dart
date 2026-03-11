import 'easy_support_customer_result.dart';

class EasySupportCustomerResponse {
  const EasySupportCustomerResponse({
    required this.success,
    this.customerId,
    this.chatId,
    this.result,
    this.data,
  });

  factory EasySupportCustomerResponse.fromJson(Map<String, dynamic> json) {
    final resultMap = _asMap(json['result']);
    final result = resultMap == null
        ? null
        : EasySupportCustomerResult.fromJson(resultMap);
    final data = _asMap(json['data']);
    final customerId = result?.id ??
        _readString(data, const ['customer_id', 'customerId', 'id']) ??
        _readString(_asMap(data?['customer']), const ['id', 'customer_id']) ??
        _readString(json, const ['customer_id', 'customerId']);
    final chatId = _readString(data, const ['chat_id', 'chatId']) ??
        _readString(_asMap(data?['chat']), const ['id', 'chat_id']) ??
        _readString(json, const ['chat_id', 'chatId']);

    return EasySupportCustomerResponse(
      success: json['success'] == true,
      customerId: customerId,
      chatId: chatId,
      result: result,
      data: data,
    );
  }

  final bool success;
  final String? customerId;
  final String? chatId;
  final EasySupportCustomerResult? result;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      if (result != null) 'result': result!.toJson(),
      if (customerId != null) 'customer_id': customerId,
      if (chatId != null) 'chat_id': chatId,
      if (data != null) 'data': data,
    };
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String? _readString(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) {
      return null;
    }
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
