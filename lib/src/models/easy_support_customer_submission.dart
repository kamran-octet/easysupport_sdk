import 'easy_support_customer_action.dart';

class EasySupportCustomerSubmission {
  const EasySupportCustomerSubmission({
    this.customerId,
    this.name,
    this.email,
    this.phone,
  });

  factory EasySupportCustomerSubmission.fromJson(Map<String, dynamic> json) {
    return EasySupportCustomerSubmission(
      customerId:
          json['customer_id'] as String? ?? json['customerId'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }

  final String? customerId;
  final String? name;
  final String? email;
  final String? phone;

  bool get hasCustomerId => customerId != null && customerId!.trim().isNotEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (customerId != null) 'customer_id': customerId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  Map<String, dynamic> toRequestBody({
    required EasySupportCustomerAction action,
  }) {
    final body = <String, dynamic>{};

    if (action == EasySupportCustomerAction.update && hasCustomerId) {
      final normalizedId = customerId!.trim();
      body['id'] = normalizedId;
      body['customer_id'] = normalizedId;
    }

    final normalizedName = _normalize(name);
    final normalizedEmail = _normalize(email);
    final normalizedPhone = _normalize(phone);

    if (normalizedName != null) {
      body['name'] = normalizedName;
    }
    if (normalizedEmail != null) {
      body['email'] = normalizedEmail;
    }
    if (normalizedPhone != null) {
      body['phone'] = normalizedPhone;
    }

    return body;
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
