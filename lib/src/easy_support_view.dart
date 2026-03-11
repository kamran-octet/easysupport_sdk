import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'easy_support_chat_view.dart';
import 'easy_support_conversation_controller.dart';
import 'easy_support_customer_local_storage.dart';
import 'easy_support_repository.dart';
import 'models/easy_support_channel_configuration.dart';
import 'models/easy_support_config.dart';
import 'models/easy_support_customer_result.dart';
import 'models/easy_support_customer_session.dart';
import 'models/easy_support_customer_submission.dart';
import 'widgets/easy_support_action_bar.dart';
import 'widgets/easy_support_color_utils.dart';
import 'widgets/easy_support_form_card.dart';
import 'widgets/easy_support_header.dart';
import 'widgets/easy_support_hero_section.dart';
import 'widgets/easy_support_input_field.dart';
import 'widgets/easy_support_message_card.dart';
import 'widgets/easy_support_stack_loader.dart';

typedef EasySupportErrorCallback = void Function(WebResourceError error);

class EasySupportView extends StatefulWidget {
  const EasySupportView({
    super.key,
    required this.config,
    this.channelConfiguration,
    this.isFullScreen = false,
    this.onError,
  });

  final EasySupportConfig config;
  final EasySupportChannelConfiguration? channelConfiguration;
  final bool isFullScreen;
  final EasySupportErrorCallback? onError;

  @override
  State<EasySupportView> createState() => _EasySupportViewState();
}

class _EasySupportViewState extends State<EasySupportView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late final EasySupportRepository _repository;
  late final EasySupportConversationController _conversationController;

  EasySupportCustomerSession _session = const EasySupportCustomerSession();
  bool _isSessionLoading = true;
  bool _isSubmitting = false;
  bool _isApplyingPrefill = false;
  bool _hasUserEditedEmail = false;
  bool _hasUserEditedName = false;
  bool _hasUserEditedPhone = false;
  String? _lastPrintedScreenState;

  @override
  void initState() {
    super.initState();
    _repository = EasySupportDioRepository();
    _conversationController = EasySupportConversationController(
      repository: _repository,
      localStorage: EasySupportSharedPrefsCustomerLocalStorage(),
    );
    _emailController.addListener(_onEmailChanged);
    _nameController.addListener(_onNameChanged);
    _phoneController.addListener(_onPhoneChanged);
    _loadCustomerSession();
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _nameController.removeListener(_onNameChanged);
    _phoneController.removeListener(_onPhoneChanged);
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channelConfiguration;
    final primaryColor = EasySupportColorUtils.parseHexColor(
      channel?.widgetColor,
      fallback: const Color(0xFFF50A0A),
    );
    final onPrimaryColor = EasySupportColorUtils.onColor(primaryColor);
    final actionButtonColor =
        EasySupportColorUtils.blend(primaryColor, Colors.white, 0.12);

    final title = channel?.name ?? 'Support';
    final heading = channel?.welcomeHeading ??
        widget.config.widgetTitle ??
        'Hi there ! How can we help you';
    final tagline = channel?.welcomeTagline ??
        channel?.details ??
        'We make it simple to connect with us.';
    final greetingMessage =
        channel?.isGreetingEnabled == true ? channel?.greetingMessage : null;
    final form = channel?.chatForm;
    final isFormEnabled = channel?.isFormEnabled ?? true;
    final showForm =
        isFormEnabled && channel?.hasActiveForm == true && form != null;
    final canStartConversation = !_isSubmitting &&
        !_isSessionLoading &&
        (!showForm || _areRequiredFieldsFilled(form: form));

    final shouldShowChatScreen = !_isSessionLoading &&
        !_isSubmitting &&
        _session.hasCustomerId &&
        _session.hasChatId;
    _printScreenState(shouldShowChatScreen: shouldShowChatScreen);
    if (shouldShowChatScreen) {
      return EasySupportChatView(
        title: title,
        primaryColor: primaryColor,
        onPrimaryColor: onPrimaryColor,
        isFullScreen: widget.isFullScreen,
        onClose: () => Navigator.of(context).maybePop(),
        onChatEnded: _onChatEnded,
        config: widget.config,
        session: _session,
        channelConfiguration: channel,
        repository: _repository,
      );
    }

    final content = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF7F8FC),
            Color(0xFFF2F4F8),
          ],
        ),
      ),
      child: Column(
        children: [
          EasySupportHeader(
            title: title,
            primaryColor: primaryColor,
            onPrimaryColor: onPrimaryColor,
            isFullScreen: widget.isFullScreen,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Column(
                children: [
                  EasySupportHeroSection(
                    heading: heading,
                    tagline: tagline,
                    primaryColor: primaryColor,
                  ),
                  if (greetingMessage != null &&
                      greetingMessage.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    EasySupportMessageCard(
                      message: greetingMessage,
                      primaryColor: primaryColor,
                    ),
                  ],
                  if (showForm) ...[
                    const SizedBox(height: 18),
                    _buildFormCard(
                      form: form,
                      primaryColor: primaryColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
          EasySupportActionBar(
            onPressed: canStartConversation
                ? () => _onStartConversationPressed(
                      showForm: showForm,
                      form: form,
                    )
                : null,
            label: _isSubmitting ? 'Please wait...' : 'Start Conversation',
            actionColor: actionButtonColor,
            onActionColor: EasySupportColorUtils.onColor(actionButtonColor),
            bottomPadding: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );

    final showOverlayLoader = _isSessionLoading || _isSubmitting;
    final stackLoaderMessage =
        _isSessionLoading ? 'Preparing support...' : 'Starting conversation...';
    final stackedContent = Stack(
      children: [
        Positioned.fill(child: content),
        EasySupportStackLoader(
          visible: showOverlayLoader,
          message: stackLoaderMessage,
          primaryColor: primaryColor,
        ),
      ],
    );

    if (widget.isFullScreen) {
      return stackedContent;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: stackedContent,
    );
  }

  Widget _buildFormCard({
    required EasySupportChatFormConfiguration form,
    required Color primaryColor,
  }) {
    final fields = <Widget>[
      if (form.isEmailEnabled == true)
        EasySupportInputField(
          controller: _emailController,
          label: form.emailFieldLabel ?? 'Email',
          placeholder: form.emailFieldPlaceholder ?? 'emailAddress',
          requiredField: form.isEmailRequired == true,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final text = value?.trim() ?? '';
            final label = form.emailFieldLabel ?? 'Email';
            if (form.isEmailRequired == true && text.isEmpty) {
              return '$label is required';
            }
            if (text.isNotEmpty && !_isValidEmail(text)) {
              return 'Enter a valid email';
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
      if (form.isNameEnabled == true)
        EasySupportInputField(
          controller: _nameController,
          label: form.nameFieldLabel ?? 'Name',
          placeholder: form.nameFieldPlaceholder ?? 'fullName',
          requiredField: form.isNameRequired == true,
          keyboardType: TextInputType.name,
          validator: (value) {
            final text = value?.trim() ?? '';
            if (form.isNameRequired == true && text.isEmpty) {
              return '${form.nameFieldLabel ?? 'Name'} is required';
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
      if (form.isPhoneEnabled == true)
        EasySupportInputField(
          controller: _phoneController,
          label: form.phoneFieldLabel ?? 'Phone Number',
          placeholder: form.phoneFieldPlaceholder ?? 'phoneNumber',
          requiredField: form.isPhoneRequired == true,
          keyboardType: TextInputType.phone,
          validator: (value) {
            final text = value?.trim() ?? '';
            final label = form.phoneFieldLabel ?? 'Phone Number';
            if (form.isPhoneRequired == true && text.isEmpty) {
              return '$label is required';
            }
            if (text.isNotEmpty && !_isLikelyPhone(text)) {
              return 'Enter a valid phone number';
            }
            return null;
          },
          primaryColor: primaryColor,
        ),
    ];

    return Form(
      key: _formKey,
      child: EasySupportFormCard(
        primaryColor: primaryColor,
        title: form.formMessage,
        children: fields,
      ),
    );
  }

  Future<void> _onStartConversationPressed({
    required bool showForm,
    required EasySupportChatFormConfiguration? form,
  }) async {
    if (showForm) {
      final valid = _formKey.currentState?.validate() ?? false;
      if (!valid) {
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final submission = EasySupportCustomerSubmission(
        customerId: _session.customerId,
        name: form?.isNameEnabled == true ? _nameController.text : null,
        email: form?.isEmailEnabled == true ? _emailController.text : null,
        phone: form?.isPhoneEnabled == true ? _phoneController.text : null,
      );

      final session = await _conversationController.startConversation(
        config: widget.config,
        submission: submission,
        channelId: widget.channelConfiguration?.id ?? _session.channelId,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _session = session;
      });
      debugPrint('EasySupport customer_id: ${session.customerId}');
    } catch (error) {
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Start conversation failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _areRequiredFieldsFilled({
    required EasySupportChatFormConfiguration? form,
  }) {
    if (form == null) {
      return true;
    }

    if (form.isEmailEnabled == true &&
        form.isEmailRequired == true &&
        _emailController.text.trim().isEmpty) {
      return false;
    }

    if (form.isNameEnabled == true &&
        form.isNameRequired == true &&
        _nameController.text.trim().isEmpty) {
      return false;
    }

    if (form.isPhoneEnabled == true &&
        form.isPhoneRequired == true &&
        _phoneController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  void _onEmailChanged() {
    if (!_isApplyingPrefill) {
      _hasUserEditedEmail = true;
    }
    _onFormChanged();
  }

  void _onNameChanged() {
    if (!_isApplyingPrefill) {
      _hasUserEditedName = true;
    }
    _onFormChanged();
  }

  void _onPhoneChanged() {
    if (!_isApplyingPrefill) {
      _hasUserEditedPhone = true;
    }
    _onFormChanged();
  }

  void _onFormChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _printScreenState({required bool shouldShowChatScreen}) {
    final screenName = shouldShowChatScreen ? 'chat' : 'start';
    final stateKey = '$screenName:${_session.customerId ?? 'null'}';
    if (_lastPrintedScreenState == stateKey) {
      return;
    }
    _lastPrintedScreenState = stateKey;
    debugPrint(
      'EasySupport screen: $screenName, customer_id: ${_session.customerId}',
    );
  }

  void _onChatEnded() {
    if (!mounted) {
      return;
    }
    setState(() {
      _session = EasySupportCustomerSession(
        customerId: _session.customerId,
        channelId: _session.channelId,
      );
    });
  }

  Future<void> _loadCustomerSession() async {
    try {
      final session = await _conversationController.loadSession();
      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
        _isSessionLoading = false;
      });
      debugPrint('EasySupport cached customer_id: ${session.customerId}');

      if (!session.hasCustomerId) {
        return;
      }

      try {
        final customerResponse =
            await _conversationController.fetchCustomerById(
          config: widget.config,
          customerId: session.customerId!,
        );
        if (!mounted) {
          return;
        }
        _prefillFieldsFromCustomer(customer: customerResponse.result);
        debugPrint(
          'EasySupport fetched customer by id: ${customerResponse.customerId}',
        );
      } catch (error) {
        debugPrint('EasySupport customer get failed: $error');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSessionLoading = false;
      });
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Session load failed: $error'),
        ),
      );
    }
  }

  void _prefillFieldsFromCustomer({
    required EasySupportCustomerResult? customer,
  }) {
    final form = widget.channelConfiguration?.chatForm;
    final formEnabled =
        widget.channelConfiguration?.hasActiveForm == true && form != null;
    if (!formEnabled || customer == null) {
      return;
    }

    final email = customer.email?.trim();
    final name = customer.name?.trim();
    final phone = customer.phone?.trim();

    _isApplyingPrefill = true;
    try {
      if (form.isEmailEnabled == true &&
          email != null &&
          email.isNotEmpty &&
          _emailController.text.trim().isEmpty &&
          !_hasUserEditedEmail) {
        _emailController.text = email;
      }
      if (form.isNameEnabled == true &&
          name != null &&
          name.isNotEmpty &&
          _nameController.text.trim().isEmpty &&
          !_hasUserEditedName) {
        _nameController.text = name;
      }
      if (form.isPhoneEnabled == true &&
          phone != null &&
          phone.isNotEmpty &&
          _phoneController.text.trim().isEmpty &&
          !_hasUserEditedPhone) {
        _phoneController.text = phone;
      }
    } finally {
      _isApplyingPrefill = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  static bool _isValidEmail(String email) {
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailPattern.hasMatch(email);
  }

  static bool _isLikelyPhone(String phone) {
    final numeric = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return numeric.length >= 7;
  }
}
