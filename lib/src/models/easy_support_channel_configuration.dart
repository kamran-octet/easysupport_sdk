import 'easy_support_config.dart';

class EasySupportChannelKeyResponse {
  const EasySupportChannelKeyResponse({
    required this.success,
    this.data,
  });

  factory EasySupportChannelKeyResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return EasySupportChannelKeyResponse(
      success: json['success'] == true,
      data: data is Map<String, dynamic>
          ? EasySupportChannelConfiguration.fromJson(data)
          : data is Map
              ? EasySupportChannelConfiguration.fromJson(
                  Map<String, dynamic>.from(data),
                )
              : null,
    );
  }

  final bool success;
  final EasySupportChannelConfiguration? data;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      if (data != null) 'data': data!.toJson(),
    };
  }
}

class EasySupportChannelConfiguration {
  const EasySupportChannelConfiguration({
    this.id,
    this.name,
    this.details,
    this.welcomeHeading,
    this.welcomeTagline,
    this.isGreetingEnabled,
    this.greetingMessage,
    this.widgetColor,
    this.widgetPosition,
    this.isFormEnabled,
    this.isEmojiEnabled,
    this.isMediaEnabled,
    this.isFeedbackEnabled,
    this.feedbackMessage,
    this.feedbackDisplayType,
    this.websiteToken,
    this.script,
    this.type,
    this.domain,
    this.token,
    this.workspaceId,
    this.createdAt,
    this.updatedAt,
    this.chatForm,
  });

  factory EasySupportChannelConfiguration.fromJson(Map<String, dynamic> json) {
    return EasySupportChannelConfiguration(
      id: json['id'] as String?,
      name: json['name'] as String?,
      details: json['details'] as String?,
      welcomeHeading: json['welcome_heading'] as String?,
      welcomeTagline: json['welcome_tagline'] as String?,
      isGreetingEnabled: json['is_greeting_enabled'] as bool?,
      greetingMessage: json['greeting_message'] as String?,
      widgetColor: json['widget_color'] as String?,
      widgetPosition: json['widget_position'] as String?,
      isFormEnabled: json['is_form_enabled'] as bool?,
      isEmojiEnabled: json['is_emoji_enabled'] as bool?,
      isMediaEnabled: json['is_media_enabled'] as bool?,
      isFeedbackEnabled: json['is_feedback_enabled'] as bool?,
      feedbackMessage: json['feedback_message'] as String?,
      feedbackDisplayType: json['feedback_display_type'] as String?,
      websiteToken: json['website_token'] as String?,
      script: json['script'] as String?,
      type: json['type'] as String?,
      domain: json['domain'] as String?,
      token: json['token'] as String?,
      workspaceId: json['workspace_id'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      chatForm: _parseChatForm(json['chat_form']),
    );
  }

  static EasySupportChatFormConfiguration? _parseChatForm(dynamic value) {
    if (value is Map<String, dynamic>) {
      return EasySupportChatFormConfiguration.fromJson(value);
    }
    if (value is Map) {
      return EasySupportChatFormConfiguration.fromJson(
        Map<String, dynamic>.from(value),
      );
    }
    return null;
  }

  final String? id;
  final String? name;
  final String? details;
  final String? welcomeHeading;
  final String? welcomeTagline;
  final bool? isGreetingEnabled;
  final String? greetingMessage;
  final String? widgetColor;
  final String? widgetPosition;
  final bool? isFormEnabled;
  final bool? isEmojiEnabled;
  final bool? isMediaEnabled;
  final bool? isFeedbackEnabled;
  final String? feedbackMessage;
  final String? feedbackDisplayType;
  final String? websiteToken;
  final String? script;
  final String? type;
  final String? domain;
  final String? token;
  final String? workspaceId;
  final String? createdAt;
  final String? updatedAt;
  final EasySupportChatFormConfiguration? chatForm;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (details != null) 'details': details,
      if (welcomeHeading != null) 'welcome_heading': welcomeHeading,
      if (welcomeTagline != null) 'welcome_tagline': welcomeTagline,
      if (isGreetingEnabled != null) 'is_greeting_enabled': isGreetingEnabled,
      if (greetingMessage != null) 'greeting_message': greetingMessage,
      if (widgetColor != null) 'widget_color': widgetColor,
      if (widgetPosition != null) 'widget_position': widgetPosition,
      if (isFormEnabled != null) 'is_form_enabled': isFormEnabled,
      if (isEmojiEnabled != null) 'is_emoji_enabled': isEmojiEnabled,
      if (isMediaEnabled != null) 'is_media_enabled': isMediaEnabled,
      if (isFeedbackEnabled != null) 'is_feedback_enabled': isFeedbackEnabled,
      if (feedbackMessage != null) 'feedback_message': feedbackMessage,
      if (feedbackDisplayType != null)
        'feedback_display_type': feedbackDisplayType,
      if (websiteToken != null) 'website_token': websiteToken,
      if (script != null) 'script': script,
      if (type != null) 'type': type,
      if (domain != null) 'domain': domain,
      if (token != null) 'token': token,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (chatForm != null) 'chat_form': chatForm!.toJson(),
    };
  }

  bool get hasActiveForm {
    final form = chatForm;
    if (form == null) {
      return false;
    }
    if (form.isActive == false) {
      return false;
    }
    return form.isEmailEnabled == true ||
        form.isPhoneEnabled == true ||
        form.isNameEnabled == true;
  }
}

class EasySupportChatFormConfiguration {
  const EasySupportChatFormConfiguration({
    this.id,
    this.channelId,
    this.formMessage,
    this.isActive,
    this.isEmailEnabled,
    this.isEmailRequired,
    this.emailFieldLabel,
    this.emailFieldPlaceholder,
    this.isPhoneEnabled,
    this.isPhoneRequired,
    this.phoneFieldLabel,
    this.phoneFieldPlaceholder,
    this.isNameEnabled,
    this.isNameRequired,
    this.nameFieldLabel,
    this.nameFieldPlaceholder,
    this.createdAt,
    this.updatedAt,
  });

  factory EasySupportChatFormConfiguration.fromJson(Map<String, dynamic> json) {
    return EasySupportChatFormConfiguration(
      id: json['id'] as String?,
      channelId: json['channel_id'] as String?,
      formMessage: json['form_message'] as String?,
      isActive: json['is_active'] as bool?,
      isEmailEnabled: json['is_email_enabled'] as bool?,
      isEmailRequired: json['is_email_required'] as bool?,
      emailFieldLabel: json['email_field_label'] as String?,
      emailFieldPlaceholder: json['email_field_placeholder'] as String?,
      isPhoneEnabled: json['is_phone_enabled'] as bool?,
      isPhoneRequired: json['is_phone_required'] as bool?,
      phoneFieldLabel: json['phone_field_label'] as String?,
      phoneFieldPlaceholder: json['phone_field_placeholder'] as String?,
      isNameEnabled: json['is_name_enabled'] as bool?,
      isNameRequired: json['is_name_required'] as bool?,
      nameFieldLabel: json['name_field_label'] as String?,
      nameFieldPlaceholder: json['name_field_placeholder'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  final String? id;
  final String? channelId;
  final String? formMessage;
  final bool? isActive;
  final bool? isEmailEnabled;
  final bool? isEmailRequired;
  final String? emailFieldLabel;
  final String? emailFieldPlaceholder;
  final bool? isPhoneEnabled;
  final bool? isPhoneRequired;
  final String? phoneFieldLabel;
  final String? phoneFieldPlaceholder;
  final bool? isNameEnabled;
  final bool? isNameRequired;
  final String? nameFieldLabel;
  final String? nameFieldPlaceholder;
  final String? createdAt;
  final String? updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (formMessage != null) 'form_message': formMessage,
      if (isActive != null) 'is_active': isActive,
      if (isEmailEnabled != null) 'is_email_enabled': isEmailEnabled,
      if (isEmailRequired != null) 'is_email_required': isEmailRequired,
      if (emailFieldLabel != null) 'email_field_label': emailFieldLabel,
      if (emailFieldPlaceholder != null)
        'email_field_placeholder': emailFieldPlaceholder,
      if (isPhoneEnabled != null) 'is_phone_enabled': isPhoneEnabled,
      if (isPhoneRequired != null) 'is_phone_required': isPhoneRequired,
      if (phoneFieldLabel != null) 'phone_field_label': phoneFieldLabel,
      if (phoneFieldPlaceholder != null)
        'phone_field_placeholder': phoneFieldPlaceholder,
      if (isNameEnabled != null) 'is_name_enabled': isNameEnabled,
      if (isNameRequired != null) 'is_name_required': isNameRequired,
      if (nameFieldLabel != null) 'name_field_label': nameFieldLabel,
      if (nameFieldPlaceholder != null)
        'name_field_placeholder': nameFieldPlaceholder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

extension EasySupportConfigRuntimeMerge on EasySupportConfig {
  EasySupportConfig mergeWithChannelConfiguration(
    EasySupportChannelConfiguration channelConfiguration,
  ) {
    return copyWith(
      widgetTitle: channelConfiguration.welcomeHeading ?? widgetTitle,
      isEmojiEnabled: channelConfiguration.isEmojiEnabled ?? isEmojiEnabled,
      isMediaEnabled: channelConfiguration.isMediaEnabled ?? isMediaEnabled,
    );
  }
}
