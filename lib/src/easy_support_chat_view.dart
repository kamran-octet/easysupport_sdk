import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'easy_support_chat_controller.dart';
import 'easy_support_repository.dart';
import 'easy_support_chat_socket_connection.dart';
import 'easy_support_customer_local_storage.dart';
import 'easy_support_socket_service.dart';
import 'easy_support_socket_service_resolver.dart';
import 'models/easy_support_channel_configuration.dart';
import 'models/easy_support_chat_emit_payload.dart';
import 'models/easy_support_feedback_submission.dart';
import 'models/easy_support_chat_message.dart';
import 'models/easy_support_config.dart';
import 'models/easy_support_customer_session.dart';
import 'widgets/easy_support_color_utils.dart';
import 'widgets/easy_support_feedback_form_sheet.dart';

class EasySupportChatView extends StatefulWidget {
  const EasySupportChatView({
    super.key,
    required this.title,
    required this.primaryColor,
    required this.onPrimaryColor,
    required this.isFullScreen,
    required this.onClose,
    required this.onChatEnded,
    required this.config,
    required this.session,
    this.channelConfiguration,
    this.repository,
  });

  final String title;
  final Color primaryColor;
  final Color onPrimaryColor;
  final bool isFullScreen;
  final VoidCallback onClose;
  final VoidCallback onChatEnded;
  final EasySupportConfig config;
  final EasySupportCustomerSession session;
  final EasySupportChannelConfiguration? channelConfiguration;
  final EasySupportRepository? repository;

  @override
  State<EasySupportChatView> createState() => _EasySupportChatViewState();
}

class _EasySupportChatViewState extends State<EasySupportChatView> {
  static const List<String> _emojiOptions = <String>[
    '😀',
    '😁',
    '😂',
    '😊',
    '😍',
    '😎',
    '🤝',
    '🙏',
    '👍',
    '👏',
    '🎉',
    '❤️',
    '🔥',
    '💯',
    '✅',
    '🚀',
  ];

  late final EasySupportChatController _controller;
  late final EasySupportRepository _repository;
  late final EasySupportSocketService _socketService;
  EasySupportChatSocketConnection? _chatSocketConnection;
  Future<void>? _socketConnectTask;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSending = false;
  bool _isUploadingMedia = false;
  bool _isLeaving = false;
  bool _isChatClosedByAgent = false;
  bool _isAutoFeedbackFlowRunning = false;
  bool _isAttachmentPermissionRequestInProgress = false;
  bool _isAttachmentPermissionDialogVisible = false;
  bool _hasHandledAgentClosedNotification = false;
  String? _lastHandledClosedNotificationId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? EasySupportDioRepository();
    _controller = EasySupportChatController(
      repository: _repository,
    );
    _socketService = EasySupportSocketServiceResolver();
    _controller.addListener(_onChatStateChanged);
    _messageController.addListener(_onMessageChanged);
    _loadMessages();
    unawaited(_connectChatSocketIfPossible());
  }

  @override
  void dispose() {
    final connection = _chatSocketConnection;
    if (connection != null) {
      unawaited(connection.dispose());
    }
    _controller.removeListener(_onChatStateChanged);
    _scrollController.dispose();
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerStart = EasySupportColorUtils.blend(widget.primaryColor, Colors.black, 0.08);
    final headerMid = EasySupportColorUtils.blend(widget.primaryColor, Colors.white, 0.06);
    final headerEnd = EasySupportColorUtils.blend(widget.primaryColor, Colors.black, 0.14);
    const surfaceColor = Color(0xFFF6F7FA);
    final inputBorderColor = EasySupportColorUtils.blend(widget.primaryColor, Colors.black, 0.04);
    final isComposerLocked = _isChatClosedByAgent || _isLeaving;
    final isEmojiEnabled = _isEmojiEnabled;
    final isMediaEnabled = _isMediaEnabled;
    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: widget.primaryColor,
      statusBarIconBrightness: widget.onPrimaryColor == Colors.white ? Brightness.light : Brightness.dark,
      statusBarBrightness: widget.onPrimaryColor == Colors.white ? Brightness.dark : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: surfaceColor,
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[headerStart, headerMid, headerEnd],
                  stops: const <double>[0.0, 0.55, 1.0],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.onPrimaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildHeaderIcon(
                    icon: Icons.logout_rounded,
                    iconColor: widget.onPrimaryColor,
                    onTap: _isLeaving ? () {} : _onLeaveChatPressed,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderIcon(
                    icon: Icons.close_rounded,
                    iconColor: widget.onPrimaryColor,
                    onTap: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: surfaceColor,
                ),
                child: ValueListenableBuilder<EasySupportChatState>(
                  valueListenable: _controller,
                  builder: (context, state, _) {
                    if (state.isLoading && state.messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.status == EasySupportChatStatus.error && state.messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Failed to load messages',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                      itemCount: state.messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        return _buildMessageBubble(message);
                      },
                    );
                  },
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                  bottom: Radius.circular(18),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Column(
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isComposerLocked ? 0.55 : 1,
                    child: IgnorePointer(
                      ignoring: isComposerLocked,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isComposerLocked ? const Color(0xFFE5E7EB) : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: inputBorderColor, width: 2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                enabled: !isComposerLocked,
                                style: TextStyle(
                                  color: isComposerLocked ? const Color(0xFF6B7280) : const Color(0xFF111827),
                                ),
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _sendMessage(),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Type your message',
                                  hintStyle: TextStyle(
                                    color: isComposerLocked ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                            if (isMediaEnabled) ...[
                              IconButton(
                                onPressed: isComposerLocked || _isUploadingMedia ? null : _onAttachmentPressed,
                                icon: _isUploadingMedia
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.grey.shade600,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.attach_file_rounded,
                                        color: isComposerLocked ? Colors.grey.shade400 : Colors.grey.shade600,
                                      ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (isEmojiEnabled) ...[
                              IconButton(
                                onPressed: isComposerLocked ? null : _openEmojiPicker,
                                icon: Icon(
                                  Icons.sentiment_satisfied,
                                  color: isComposerLocked ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              onPressed: isComposerLocked || _isSending || _messageController.text.trim().isEmpty ? null : _sendMessage,
                              icon: _isSending
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.grey.shade600,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.send_rounded,
                                      color: _messageController.text.trim().isEmpty ? Colors.grey.shade400 : Colors.grey.shade700,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isChatClosedByAgent) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Chat is closed by agent. Please submit feedback.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  const Text(
                    'Powered by Easy Support',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: iconColor.withOpacity(0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(EasySupportChatMessage message) {
    final content = (message.content ?? '').trim();
    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    if (message.isNotification) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final isCustomerMessage = message.customerId != null && message.customerId!.trim().isNotEmpty && message.customerId == widget.session.customerId;

    final alignment = isCustomerMessage ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isCustomerMessage ? widget.primaryColor : const Color(0xFFF3F4F6);
    final textColor = isCustomerMessage ? Colors.white : const Color(0xFF374151);
    final border = isCustomerMessage ? null : Border.all(color: const Color(0xFFE5E7EB));
    final isMediaMessage = (message.type ?? '').trim().toLowerCase() == 'media';

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 230),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: border,
          boxShadow: isCustomerMessage
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isMediaMessage
            ? _buildMediaMessageContent(
                content,
                fallbackTextColor: textColor,
                onTap: () => _openMediaPreview(content),
              )
            : Text(
                content,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Widget _buildMediaMessageContent(
    String content, {
    required Color fallbackTextColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Image.network(
            content,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return Center(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fallbackTextColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openMediaPreview(String imageUrl) async {
    if (!mounted || imageUrl.trim().isEmpty) {
      return;
    }
    debugPrint('EasySupport media preview open: $imageUrl');

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return const Center(
                            child: Text(
                              'Unable to preview image',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _loadMessages() {
    final chatId = widget.session.chatId;
    if (chatId == null || chatId.trim().isEmpty) {
      return;
    }
    debugPrint('EasySupport chat history call for chat_id: $chatId');
    _controller.loadMessages(
      config: widget.config,
      chatId: chatId,
      limit: 20,
      sortOrder: 'desc',
      sortBy: 'created_at',
    );
  }

  Future<void> _sendMessage() async {
    final body = _messageController.text.trim();
    if (body.isEmpty || _isSending || _isChatClosedByAgent) {
      return;
    }

    final chatId = widget.session.chatId;
    final customerId = widget.session.customerId;
    if (chatId == null || chatId.trim().isEmpty || customerId == null || customerId.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final payload = EasySupportChatEmitPayload(
        author: '',
        body: body,
        chatId: chatId,
        customerId: customerId,
        unseenCount: 1,
      );

      await _connectChatSocketIfPossible();
      final activeConnection = _chatSocketConnection;
      if (activeConnection == null) {
        throw StateError('Chat socket is not connected');
      }
      await activeConnection.sendChatMessage(payload);
      _messageController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Message send failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _onAttachmentPressed() async {
    if (_isUploadingMedia || _isAttachmentPermissionRequestInProgress || !_isMediaEnabled || _isChatClosedByAgent) {
      debugPrint(
        'EasySupport attach skipped | '
        'isUploading=$_isUploadingMedia isMediaEnabled=$_isMediaEnabled '
        'isPermissionRequestInProgress='
        '$_isAttachmentPermissionRequestInProgress '
        'isChatClosed=$_isChatClosedByAgent',
      );
      return;
    }

    debugPrint('EasySupport attach tapped');
    _isAttachmentPermissionRequestInProgress = true;
    try {
      final hasAttachmentPermission = await _ensureAttachmentPermission();
      if (!hasAttachmentPermission) {
        debugPrint('EasySupport attach denied: media permission not granted');
        await _showAttachmentPermissionDialog();
        return;
      }
    } finally {
      _isAttachmentPermissionRequestInProgress = false;
    }

    final selectedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (selectedImage == null) {
      debugPrint('EasySupport attach cancelled by user');
      return;
    }
    debugPrint(
      'EasySupport attach selected file: ${selectedImage.name} '
      'path=${selectedImage.path}',
    );

    final chatId = widget.session.chatId;
    final customerId = widget.session.customerId;
    final workspaceId = widget.channelConfiguration?.workspaceId?.trim();
    if (chatId == null || chatId.trim().isEmpty || customerId == null || customerId.trim().isEmpty) {
      debugPrint(
        'EasySupport attach failed: missing chat/customer '
        'chatId=$chatId customerId=$customerId',
      );
      return;
    }
    if (workspaceId == null || workspaceId.isEmpty) {
      debugPrint('EasySupport attach failed: workspace_id is missing');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Media upload failed: workspace_id is missing'),
        ),
      );
      return;
    }

    setState(() {
      _isUploadingMedia = true;
    });

    try {
      debugPrint(
        'EasySupport media upload start | workspaceId=$workspaceId '
        'chatId=$chatId customerId=$customerId',
      );
      final mediaUrl = await _repository.uploadCustomerMedia(
        config: widget.config,
        workspaceId: workspaceId,
        filePath: selectedImage.path,
        fileName: selectedImage.name,
      );
      debugPrint('EasySupport media upload success | url=$mediaUrl');

      await _connectChatSocketIfPossible();
      final activeConnection = _chatSocketConnection;
      if (activeConnection == null) {
        debugPrint('EasySupport media emit failed: socket is not connected');
        throw StateError('Chat socket is not connected');
      }

      final payload = EasySupportChatEmitPayload(
        author: '',
        body: mediaUrl,
        chatId: chatId,
        customerId: customerId,
        type: 'media',
        unseenCount: 1,
      );
      await activeConnection.sendChatMessage(payload);
      debugPrint('EasySupport media emit success | chat event=chat type=media');
    } on EasySupportApiException catch (error) {
      debugPrint(
        'EasySupport media attach api failed: '
        'status=${error.statusCode} message=${error.message}',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(_buildMediaUploadErrorMessage(error)),
        ),
      );
    } catch (error) {
      debugPrint('EasySupport media attach flow failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Media upload failed. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }
    }
  }

  Future<bool> _ensureAttachmentPermission() async {
    if (kIsWeb) {
      debugPrint('EasySupport attach permission bypass on web');
      return true;
    }

    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final photosStatus = await Permission.photos.request();
          debugPrint(
            'EasySupport Android photos permission status: $photosStatus',
          );
          if (photosStatus.isGranted || photosStatus.isLimited) {
            return true;
          }
          final storageStatus = await Permission.storage.request();
          debugPrint(
            'EasySupport Android storage permission status: $storageStatus',
          );
          return storageStatus.isGranted;
        case TargetPlatform.iOS:
          final photosStatus = await Permission.photos.request();
          debugPrint('EasySupport iOS photos permission status: $photosStatus');
          return photosStatus.isGranted || photosStatus.isLimited;
        default:
          debugPrint(
            'EasySupport attach permission bypass on platform: '
            '$defaultTargetPlatform',
          );
          return true;
      }
    } catch (error) {
      debugPrint('EasySupport attach permission request failed: $error');
      return false;
    }
  }

  Future<void> _showAttachmentPermissionDialog() async {
    if (!mounted || _isAttachmentPermissionDialogVisible) {
      return;
    }

    _isAttachmentPermissionDialogVisible = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          final title = _attachmentPermissionDialogTitle;
          final message = _attachmentPermissionDialogMessage;
          final accentSurface = EasySupportColorUtils.blend(
            widget.primaryColor,
            Colors.white,
            0.86,
          );

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: accentSurface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.photo_library_rounded,
                          color: widget.primaryColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 15,
                                height: 1.38,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF374151),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Not now'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            try {
                              final didOpenSettings = await openAppSettings();
                              debugPrint(
                                'EasySupport open app settings result: '
                                '$didOpenSettings',
                              );
                            } catch (error) {
                              debugPrint(
                                'EasySupport open app settings failed: '
                                '$error',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.primaryColor,
                            foregroundColor: widget.onPrimaryColor,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: const Text('Open Settings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isAttachmentPermissionDialogVisible = false;
    }
  }

  String get _attachmentPermissionDialogTitle {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Photo access is off';
      case TargetPlatform.iOS:
        return 'Photos permission needed';
      default:
        return 'Photo access needed';
    }
  }

  String get _attachmentPermissionDialogMessage {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'To attach images in this chat, open settings and allow photo '
            'or storage access for this app.';
      case TargetPlatform.iOS:
        return 'To attach images in this chat, open Settings and allow photo '
            'access for this app.';
      default:
        return 'To attach images in this chat, open settings and allow photo '
            'access for this app.';
    }
  }

  String _buildMediaUploadErrorMessage(EasySupportApiException error) {
    final responseMessage = _extractResponseMessage(error.message);

    if (error.statusCode == 400) {
      if (responseMessage != null && responseMessage.isNotEmpty) {
        return responseMessage;
      }
      return 'Upload failed (400). Please check image and try again.';
    }

    if (error.isNetworkError) {
      return 'Network error while uploading image. Please try again.';
    }

    if (responseMessage != null && responseMessage.isNotEmpty) {
      return responseMessage;
    }
    return 'Media upload failed. Please try again.';
  }

  String? _extractResponseMessage(String message) {
    final match = RegExp(r'response=([^|]+)').firstMatch(message);
    final value = match?.group(1)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> _onLeaveChatPressed() async {
    if (_isLeaving) {
      return;
    }

    final chatId = widget.session.chatId;
    if (chatId == null || chatId.trim().isEmpty) {
      widget.onChatEnded();
      return;
    }

    setState(() {
      _isLeaving = true;
    });

    try {
      final feedbackSubmission = await _collectFeedbackIfEnabled();
      if (!mounted) {
        return;
      }
      if (_isFeedbackEnabled && feedbackSubmission == null) {
        setState(() {
          _isLeaving = false;
        });
        return;
      }
      if (feedbackSubmission != null) {
        debugPrint(
          'EasySupport feedback submission: ${feedbackSubmission.toJson()}',
        );
        await _submitFeedback(
          feedbackSubmission: feedbackSubmission,
          chatId: chatId,
        );
      }

      await _connectChatSocketIfPossible();
      final activeConnection = _chatSocketConnection;
      if (activeConnection != null) {
        await _emitUserClosedNotification(
          activeConnection: activeConnection,
          chatId: chatId,
        );
        await activeConnection.leaveChat(chatId);
      }

      await EasySupportSharedPrefsCustomerLocalStorage().writeSession(
        EasySupportCustomerSession(
          customerId: widget.session.customerId,
          channelId: widget.session.channelId,
        ),
      );
      debugPrint('EasySupport leave_chat success, chat_id cleared: $chatId');

      await activeConnection?.dispose();
      _chatSocketConnection = null;

      if (!mounted) {
        return;
      }
      widget.onChatEnded();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Leave chat failed: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }
  }

  bool get _isFeedbackEnabled => widget.channelConfiguration?.isFeedbackEnabled == true;

  bool get _isEmojiEnabled => widget.channelConfiguration?.isEmojiEnabled ?? widget.config.isEmojiEnabled;

  bool get _isMediaEnabled => widget.channelConfiguration?.isMediaEnabled ?? widget.config.isMediaEnabled;

  Future<EasySupportFeedbackSubmission?> _collectFeedbackIfEnabled({
    bool isDismissible = true,
    bool enableDrag = true,
  }) async {
    if (!_isFeedbackEnabled) {
      return null;
    }

    final feedbackDisplayType = (widget.channelConfiguration?.feedbackDisplayType ?? '').toLowerCase();
    final showStars = feedbackDisplayType.isEmpty || feedbackDisplayType == 'star';

    return showModalBottomSheet<EasySupportFeedbackSubmission>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return EasySupportFeedbackFormSheet(
          primaryColor: widget.primaryColor,
          feedbackMessage: widget.channelConfiguration?.feedbackMessage,
          showStars: showStars,
        );
      },
    );
  }

  void _onMessageChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _onChatStateChanged() {
    _ensureGreetingMessageIfEnabled();
    _scrollToBottom();
    _checkAgentClosedNotificationAndHandle();
  }

  void _ensureGreetingMessageIfEnabled() {
    if (widget.channelConfiguration?.isGreetingEnabled != true) {
      return;
    }

    final greetingMessage = widget.channelConfiguration?.greetingMessage;
    if (greetingMessage == null || greetingMessage.trim().isEmpty) {
      return;
    }

    final chatId = widget.session.chatId;
    if (chatId == null || chatId.trim().isEmpty) {
      return;
    }

    _controller.ensureGreetingMessage(
      greetingMessage: greetingMessage,
      chatId: chatId,
    );
  }

  Future<void> _openEmojiPicker() async {
    if (!_isEmojiEnabled) {
      return;
    }

    final emoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: _emojiOptions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final value = _emojiOptions[index];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(value),
                  borderRadius: BorderRadius.circular(8),
                  child: Center(
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (!mounted || emoji == null || emoji.isEmpty) {
      return;
    }
    _insertEmoji(emoji);
  }

  void _insertEmoji(String emoji) {
    final value = _messageController.value;
    final selection = value.selection;
    final text = value.text;

    final safeStart = selection.start >= 0 ? selection.start : text.length;
    final safeEnd = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(safeStart, safeEnd, emoji);
    final newOffset = safeStart + emoji.length;
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  Future<void> _connectChatSocketIfPossible() async {
    final activeConnection = _chatSocketConnection;
    if (activeConnection != null) {
      return;
    }

    final inFlight = _socketConnectTask;
    if (inFlight != null) {
      await inFlight;
      return;
    }

    final task = _connectChatSocketInternal();
    _socketConnectTask = task;
    try {
      await task;
    } finally {
      if (identical(_socketConnectTask, task)) {
        _socketConnectTask = null;
      }
    }
  }

  Future<void> _connectChatSocketInternal() async {
    final chatId = widget.session.chatId;
    final customerId = widget.session.customerId;
    if (chatId == null || chatId.trim().isEmpty || customerId == null || customerId.trim().isEmpty) {
      return;
    }

    try {
      _chatSocketConnection = await _socketService.connectToChat(
        config: widget.config,
        customerId: customerId,
        chatId: chatId,
        onMessage: (message) {
          if (!mounted) {
            return;
          }
          _controller.addIncomingMessage(message);
          _handleIncomingMessage(message);
        },
        onError: (error) {
          debugPrint('EasySupport chat socket error: $error');
        },
      );
      debugPrint('EasySupport chat socket connected for chat_id: $chatId');
    } catch (error) {
      debugPrint('EasySupport chat socket connect failed: $error');
    }
  }

  void _handleIncomingMessage(EasySupportChatMessage message) {
    if (_isAgentClosedNotification(message)) {
      _triggerAgentClosedFlow(message);
    }
  }

  void _checkAgentClosedNotificationAndHandle() {
    final state = _controller.value;
    if (state.messages.isEmpty) {
      return;
    }
    for (final message in state.messages.reversed) {
      if (_isAgentClosedNotification(message)) {
        _triggerAgentClosedFlow(message);
        return;
      }
    }
  }

  bool _isAgentClosedNotification(EasySupportChatMessage message) {
    if (!message.isNotification) {
      return false;
    }
    final content = (message.content ?? '').trim().toLowerCase();
    return content.contains('agent closed the chat');
  }

  void _triggerAgentClosedFlow(EasySupportChatMessage message) {
    if (_hasHandledAgentClosedNotification) {
      return;
    }
    final id = message.id?.trim();
    if (id != null && id.isNotEmpty && _lastHandledClosedNotificationId == id) {
      return;
    }
    _hasHandledAgentClosedNotification = true;
    _lastHandledClosedNotificationId = id ?? _lastHandledClosedNotificationId;

    if (_isChatClosedByAgent) {
      return;
    }
    setState(() {
      _isChatClosedByAgent = true;
    });

    if (!_isFeedbackEnabled || _isAutoFeedbackFlowRunning) {
      return;
    }
    _isAutoFeedbackFlowRunning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) {
          return;
        }
        final chatId = widget.session.chatId;
        if (chatId == null || chatId.trim().isEmpty) {
          return;
        }
        final feedbackSubmission = await _collectFeedbackIfEnabled(
          isDismissible: false,
          enableDrag: false,
        );
        if (!mounted || feedbackSubmission == null) {
          return;
        }
        await _submitFeedback(
          feedbackSubmission: feedbackSubmission,
          chatId: chatId,
        );
        await _leaveChatAndClearLocal(chatId: chatId);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text('Feedback submit failed: $error')),
        );
      } finally {
        _isAutoFeedbackFlowRunning = false;
      }
    });
  }

  Future<void> _submitFeedback({
    required EasySupportFeedbackSubmission feedbackSubmission,
    required String chatId,
  }) async {
    final customerId = widget.session.customerId;
    if (customerId == null || customerId.trim().isEmpty) {
      throw StateError('customer_id is missing for feedback submission');
    }

    final payload = <String, dynamic>{
      'chat_id': chatId.trim(),
      'customer_id': customerId.trim(),
      'content': feedbackSubmission.comment.trim(),
      'rating': feedbackSubmission.rating,
    };

    await _repository.submitFeedback(
      config: widget.config,
      body: payload,
    );
    debugPrint('EasySupport feedback submitted: $payload');
  }

  Future<void> _leaveChatAndClearLocal({
    required String chatId,
  }) async {
    await _connectChatSocketIfPossible();
    final activeConnection = _chatSocketConnection;
    if (activeConnection != null) {
      await _emitUserClosedNotification(
        activeConnection: activeConnection,
        chatId: chatId,
      );
      await activeConnection.leaveChat(chatId);
    }

    await EasySupportSharedPrefsCustomerLocalStorage().writeSession(
      EasySupportCustomerSession(
        customerId: widget.session.customerId,
        channelId: widget.session.channelId,
      ),
    );

    await activeConnection?.dispose();
    _chatSocketConnection = null;

    if (!mounted) {
      return;
    }
    widget.onChatEnded();
  }

  Future<void> _emitUserClosedNotification({
    required EasySupportChatSocketConnection activeConnection,
    required String chatId,
  }) async {
    final customerId = widget.session.customerId?.trim();
    if (customerId == null || customerId.isEmpty) {
      return;
    }

    final payload = EasySupportChatEmitPayload(
      chatId: chatId,
      customerId: customerId,
      author: '',
      body: 'User closed the chat',
      type: 'notification',
      unseenCount: 1,
    );

    await activeConnection.sendChatMessage(payload);
  }

  void _scrollToBottom() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final target = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      final distance = (target - current).abs();
      if (distance <= 2) {
        return;
      }

      if (distance > 300) {
        _scrollController.jumpTo(target);
        return;
      }

      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}
