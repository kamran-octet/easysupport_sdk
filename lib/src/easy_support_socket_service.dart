import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'easy_support_chat_socket_connection.dart';
import 'models/easy_support_config.dart';
import 'models/easy_support_chat_emit_payload.dart';
import 'models/easy_support_chat_message.dart';

abstract class EasySupportSocketService {
  Future<String> joinChat({
    required EasySupportConfig config,
    required String customerId,
    String? chatId,
  });

  Future<EasySupportChatSocketConnection> connectToChat({
    required EasySupportConfig config,
    required String customerId,
    required String chatId,
    required void Function(EasySupportChatMessage message) onMessage,
    void Function(Object error)? onError,
  }) async {
    throw UnimplementedError('connectToChat is not implemented.');
  }

  Future<void> sendChatMessage({
    required EasySupportConfig config,
    required EasySupportChatEmitPayload payload,
  }) async {
    throw UnimplementedError('sendChatMessage is not implemented.');
  }
}

class EasySupportSocketIoService implements EasySupportSocketService {
  EasySupportSocketIoService({
    Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout;

  final Duration _timeout;

  @override
  Future<String> joinChat({
    required EasySupportConfig config,
    required String customerId,
    String? chatId,
  }) async {
    _log('join_chat start, customer_id=$customerId');
    final socket = _buildSocket(config);
    final completer = Completer<String>();

    void completeWithPayload(dynamic payload) {
      _log('join_chat ack/event payload: $payload');
      if (completer.isCompleted) {
        return;
      }
      final chatId = _extractChatId(payload);
      if (chatId != null) {
        _log('join_chat resolved chat_id=$chatId');
        completer.complete(chatId);
      }
    }

    void failWith(Object error) {
      _log('join_chat failed: $error');
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    void onJoinEvent(dynamic payload) {
      _log('join_chat event payload: $payload');
      completeWithPayload(payload);
    }

    void onAnyEvent(String event, dynamic payload) {
      _log('socket event[$event]: $payload');
      if (event == 'chat_id' || event == 'chatId') {
        completeWithPayload(payload);
      }
    }

    void onAnyOutgoing(String event, dynamic payload) {
      _log('socket outgoing[$event]: $payload');
    }

    socket.onConnect((_) {
      _log('socket connected, emitting join_chat');
      socket.emitWithAck(
        'join_chat',
        _buildJoinChatPayload(
          customerId: customerId,
          channelToken: config.channelToken,
          chatId: chatId,
        ),
        ack: completeWithPayload,
      );
    });
    socket.onDisconnect((dynamic reason) {
      _log('socket disconnected: $reason');
    });
    socket.onReconnect((dynamic data) {
      _log('socket reconnect: $data');
    });
    socket.onReconnectAttempt((dynamic data) {
      _log('socket reconnect_attempt: $data');
    });
    socket.onReconnectError((dynamic error) {
      _log('socket reconnect_error: $error');
    });
    socket.onReconnectFailed((dynamic data) {
      _log('socket reconnect_failed: $data');
    });
    socket.onPing((dynamic data) {
      _log('socket ping: $data');
    });
    socket.onPong((dynamic data) {
      _log('socket pong: $data');
    });
    socket.onAny(onAnyEvent);
    socket.onAnyOutgoing(onAnyOutgoing);

    socket.on('join_chat_response', onJoinEvent);
    socket.on('join_chat_success', onJoinEvent);
    socket.on('chat_joined', onJoinEvent);
    socket.on('join_chat', onJoinEvent);
    socket.on('chat_id', onJoinEvent);
    // socket.on('chatId', onJoinEvent);
    socket.onConnectError((dynamic error) {
      failWith(StateError('Socket connect error: $error'));
    });
    socket.onError((dynamic error) {
      failWith(StateError('Socket error: $error'));
    });

    final timer = Timer(_timeout, () {
      failWith(
        TimeoutException(
          'join_chat timed out',
          _timeout,
        ),
      );
    });

    socket.connect();

    try {
      final chatId = await completer.future;
      return chatId;
    } finally {
      timer.cancel();
      socket.offAny(onAnyEvent);
      socket.offAnyOutgoing(onAnyOutgoing);
      socket.off('join_chat_response', onJoinEvent);
      socket.off('join_chat_success', onJoinEvent);
      socket.off('chat_joined', onJoinEvent);
      socket.off('join_chat', onJoinEvent);
      socket.off('chat_id', onJoinEvent);
      socket.off('chatId', onJoinEvent);
      _log('socket closing for join_chat');
      socket.dispose();
      socket.disconnect();
    }
  }

  @override
  Future<EasySupportChatSocketConnection> connectToChat({
    required EasySupportConfig config,
    required String customerId,
    required String chatId,
    required void Function(EasySupportChatMessage message) onMessage,
    void Function(Object error)? onError,
  }) async {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) {
      throw StateError('chat_id is required for socket chat connection');
    }

    _log('chat socket connect start, chat_id=$normalizedChatId');
    final socket = _buildSocket(config);
    final joinedCompleter = Completer<void>();
    Timer? joinTimeoutTimer;

    void completeJoin(dynamic payload) {
      if (joinedCompleter.isCompleted) {
        return;
      }
      final resolvedChatId = _extractChatId(payload);
      if (resolvedChatId != null &&
          resolvedChatId.trim().isNotEmpty &&
          resolvedChatId.trim() != normalizedChatId) {
        _log(
          'chat socket join ignored for other chat_id=$resolvedChatId',
        );
        return;
      }
      _log('chat socket join confirmed for chat_id=$normalizedChatId');
      joinedCompleter.complete();
    }

    void onChatEvent(dynamic payload) {
      final message = _extractIncomingMessage(
        payload,
        fallbackChatId: normalizedChatId,
      );
      if (message == null) {
        return;
      }

      final messageChatId = message.chatId?.trim();
      if (messageChatId != null &&
          messageChatId.isNotEmpty &&
          messageChatId != normalizedChatId) {
        return;
      }
      onMessage(message);
    }

    void onSystemEvent(dynamic payload) {
      final message = _extractIncomingMessage(
        payload,
        fallbackChatId: normalizedChatId,
        forcedType: 'notification',
      );
      if (message == null) {
        return;
      }

      final messageChatId = message.chatId?.trim();
      if (messageChatId != null &&
          messageChatId.isNotEmpty &&
          messageChatId != normalizedChatId) {
        return;
      }
      onMessage(message);
    }

    void onAnyEvent(String event, dynamic payload) {
      _log('socket event[$event]: $payload');
      if (event == 'chat_id' ||
          event == 'chatId' ||
          event == 'join_chat' ||
          event == 'join_chat_success' ||
          event == 'join_chat_response' ||
          event == 'chat_joined') {
        completeJoin(payload);
      }
    }

    void onAnyOutgoing(String event, dynamic payload) {
      _log('socket outgoing[$event]: $payload');
    }

    void onConnect(dynamic _) {
      _log('chat socket connected, emitting join_chat');
      socket.emit(
        'join_chat',
        _buildJoinChatPayload(
          customerId: customerId,
          channelToken: config.channelToken,
          chatId: normalizedChatId,
        ),
      );
    }

    void onJoinEvent(dynamic payload) {
      _log('chat socket join event payload: $payload');
      completeJoin(payload);
    }

    void onConnectError(dynamic error) {
      final resolvedError = StateError('Socket connect error: $error');
      _log('chat socket connect error: $error');
      onError?.call(resolvedError);
    }

    void onSocketError(dynamic error) {
      final resolvedError = StateError('Socket error: $error');
      _log('chat socket error: $error');
      onError?.call(resolvedError);
    }

    socket.onAny(onAnyEvent);
    socket.onAnyOutgoing(onAnyOutgoing);
    socket.onConnect(onConnect);
    socket.on('chat_id', onJoinEvent);
    socket.on('chatId', onJoinEvent);
    socket.on('join_chat', onJoinEvent);
    socket.on('join_chat_response', onJoinEvent);
    socket.on('join_chat_success', onJoinEvent);
    socket.on('chat_joined', onJoinEvent);
    socket.on('chat', onChatEvent);
    socket.on('system', onSystemEvent);
    socket.onDisconnect((dynamic reason) {
      _log('chat socket disconnected: $reason');
    });
    socket.onConnectError(onConnectError);
    socket.onError(onSocketError);
    socket.connect();

    joinTimeoutTimer = Timer(_timeout, () {
      if (!joinedCompleter.isCompleted) {
        joinedCompleter.completeError(
          TimeoutException('join_chat timed out', _timeout),
        );
      }
    });

    try {
      await joinedCompleter.future;

      return _EasySupportSocketIoChatConnection(
        socket: socket,
        onAnyEvent: onAnyEvent,
        onAnyOutgoing: onAnyOutgoing,
        onConnect: onConnect,
        onConnectError: onConnectError,
        onSocketError: onSocketError,
        onJoinEvent: onJoinEvent,
        onChatEvent: onChatEvent,
        onSystemEvent: onSystemEvent,
        logger: _log,
      );
    } catch (error) {
      onError?.call(error);
      socket.offAny(onAnyEvent);
      socket.offAnyOutgoing(onAnyOutgoing);
      socket.off('chat_id', onJoinEvent);
      socket.off('chatId', onJoinEvent);
      socket.off('join_chat', onJoinEvent);
      socket.off('join_chat_response', onJoinEvent);
      socket.off('join_chat_success', onJoinEvent);
      socket.off('chat_joined', onJoinEvent);
      socket.off('chat', onChatEvent);
      socket.off('system', onSystemEvent);
      socket.dispose();
      socket.disconnect();
      rethrow;
    } finally {
      joinTimeoutTimer.cancel();
    }
  }

  @override
  Future<void> sendChatMessage({
    required EasySupportConfig config,
    required EasySupportChatEmitPayload payload,
  }) async {
    _log('chat emit start, chat_id=${payload.chatId}');
    final socket = _buildSocket(config);
    final completer = Completer<void>();

    void complete() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    void failWith(Object error) {
      _log('chat emit failed: $error');
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    void onAnyEvent(String event, dynamic data) {
      _log('socket event[$event]: $data');
    }

    void onAnyOutgoing(String event, dynamic data) {
      _log('socket outgoing[$event]: $data');
    }

    socket.onAny(onAnyEvent);
    socket.onAnyOutgoing(onAnyOutgoing);
    socket.onConnect((_) {
      _log('socket connected, emitting chat');
      socket.emit('chat', payload.toJson());
      complete();
    });
    socket.onConnectError((dynamic error) {
      failWith(StateError('Socket connect error: $error'));
    });
    socket.onError((dynamic error) {
      failWith(StateError('Socket error: $error'));
    });

    final timer = Timer(_timeout, () {
      failWith(
        TimeoutException(
          'chat emit timed out',
          _timeout,
        ),
      );
    });

    socket.connect();

    try {
      await completer.future;
    } finally {
      timer.cancel();
      socket.offAny(onAnyEvent);
      socket.offAnyOutgoing(onAnyOutgoing);
      _log('socket closing for chat emit');
      socket.dispose();
      socket.disconnect();
    }
  }

  io.Socket _buildSocket(EasySupportConfig config) {
    final socketBaseUrl = config.normalizedBaseUrl.replaceFirst(
      RegExp(r'/$'),
      '',
    );
    final socketNamespace = _normalizeSocketNamespace(config.socketNamespace);
    final socketUrl = socketNamespace == null
        ? socketBaseUrl
        : '$socketBaseUrl$socketNamespace';
    final socketPath = _normalizeSocketPath(config.socketPath);
    final transports = config.socketTransports.isNotEmpty
        ? config.socketTransports
        : const <String>['websocket', 'polling'];

    _log(
      'socket build url=$socketUrl path=${socketPath ?? '/socket.io/'} '
      'transports=$transports queryKeys=${config.socketQuery.keys.toList()} '
      'authKeys=${config.socketAuth.keys.toList()}',
    );

    final optionBuilder = io.OptionBuilder()
        .setTransports(transports)
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(999999)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000)
        .setExtraHeaders(config.resolvedHeaders);
    if (socketPath != null) {
      optionBuilder.setPath(socketPath);
    }
    if (config.socketQuery.isNotEmpty) {
      optionBuilder.setQuery(config.socketQuery);
    }
    if (config.socketAuth.isNotEmpty) {
      optionBuilder.setAuth(config.socketAuth);
    }
    return io.io(
      socketUrl,
      optionBuilder.build(),
    );
  }

  static String? _normalizeSocketNamespace(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == '/') {
      return null;
    }
    if (normalized.startsWith('/')) {
      return normalized;
    }
    return '/$normalized';
  }

  static String? _normalizeSocketPath(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized.startsWith('/')) {
      return normalized;
    }
    return '/$normalized';
  }

  static String? _extractChatId(dynamic payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final direct = _readString(
        map,
        const <String>['chat_id', 'chatId', 'id'],
      );
      if (direct != null) {
        return direct;
      }

      final data = map['data'];
      if (data is Map) {
        final fromData = _readString(
          Map<String, dynamic>.from(data),
          const <String>['chat_id', 'chatId', 'id'],
        );
        if (fromData != null) {
          return fromData;
        }
      }

      final chat = map['chat'];
      if (chat is Map) {
        final fromChat = _readString(
          Map<String, dynamic>.from(chat),
          const <String>['chat_id', 'chatId', 'id'],
        );
        if (fromChat != null) {
          return fromChat;
        }
      }
    }

    return null;
  }

  static EasySupportChatMessage? _extractIncomingMessage(
    dynamic payload, {
    required String fallbackChatId,
    String? forcedType,
  }) {
    if (payload is List) {
      for (final item in payload) {
        final parsed = _extractIncomingMessage(
          item,
          fallbackChatId: fallbackChatId,
          forcedType: forcedType,
        );
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    }

    final map = _asMap(payload);
    if (map == null) {
      return null;
    }

    final nestedData = _asMap(map['data']);
    if (nestedData != null) {
      final fromNested = _extractIncomingMessage(
        nestedData,
        fallbackChatId: fallbackChatId,
        forcedType: forcedType,
      );
      if (fromNested != null) {
        return fromNested;
      }
    }

    final content =
        _readString(map, const <String>['content', 'body', 'message']) ?? '';
    final type =
        forcedType ?? _readString(map, const <String>['type']) ?? 'message';
    final normalizedContent = content.trim();
    final isNotification = type == 'notification';
    if (normalizedContent.isEmpty && !isNotification) {
      return null;
    }

    return EasySupportChatMessage(
      id: _readString(map, const <String>['id']),
      chatId: _readString(map, const <String>['chat_id', 'chatId']) ??
          fallbackChatId,
      customerId: _readString(map, const <String>['customer_id', 'customerId']),
      agentId: _readString(map, const <String>['agent_id', 'agentId']),
      content: normalizedContent,
      type: type,
      isSeen: _readBool(map, const <String>['is_seen', 'isSeen']),
      createdAt: _readString(map, const <String>['created_at', 'createdAt']) ??
          DateTime.now().toIso8601String(),
    );
  }

  static bool? _readBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) {
        return value;
      }
    }
    return null;
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

  static String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static Map<String, dynamic> _buildJoinChatPayload({
    required String customerId,
    required String channelToken,
    String? chatId,
  }) {
    final payload = <String, dynamic>{
      'customer_id': customerId,
    };

    final normalizedChatId = chatId?.trim();
    if (normalizedChatId != null && normalizedChatId.isNotEmpty) {
      payload['chat_id'] = normalizedChatId;
    }

    final normalizedChannelToken = channelToken.trim();
    if (normalizedChannelToken.isNotEmpty) {
      payload['channel_token'] = normalizedChannelToken;
    }

    return payload;
  }

  void _log(String message) {
    debugPrint('EasySupportSocket: $message');
  }
}

class _EasySupportSocketIoChatConnection
    implements EasySupportChatSocketConnection {
  _EasySupportSocketIoChatConnection({
    required io.Socket socket,
    required void Function(String event, dynamic payload) onAnyEvent,
    required void Function(String event, dynamic payload) onAnyOutgoing,
    required void Function(dynamic data) onConnect,
    required void Function(dynamic error) onConnectError,
    required void Function(dynamic error) onSocketError,
    required void Function(dynamic payload) onJoinEvent,
    required void Function(dynamic payload) onChatEvent,
    required void Function(dynamic payload) onSystemEvent,
    required void Function(String message) logger,
  })  : _socket = socket,
        _onAnyEvent = onAnyEvent,
        _onAnyOutgoing = onAnyOutgoing,
        _onConnect = onConnect,
        _onConnectError = onConnectError,
        _onSocketError = onSocketError,
        _onJoinEvent = onJoinEvent,
        _onChatEvent = onChatEvent,
        _onSystemEvent = onSystemEvent,
        _logger = logger;

  final io.Socket _socket;
  final void Function(String event, dynamic payload) _onAnyEvent;
  final void Function(String event, dynamic payload) _onAnyOutgoing;
  final void Function(dynamic data) _onConnect;
  final void Function(dynamic error) _onConnectError;
  final void Function(dynamic error) _onSocketError;
  final void Function(dynamic payload) _onJoinEvent;
  final void Function(dynamic payload) _onChatEvent;
  final void Function(dynamic payload) _onSystemEvent;
  final void Function(String message) _logger;

  @override
  Future<void> sendChatMessage(
    EasySupportChatEmitPayload payload, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _logger('chat emit on active socket, chat_id=${payload.chatId}');
    if (_socket.connected) {
      _socket.emit('chat', payload.toJson());
      return;
    }

    final completer = Completer<void>();
    late void Function(dynamic) onConnect;
    late void Function(dynamic) onConnectError;
    late Timer timer;

    void complete() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    void failWith(Object error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    onConnect = (_) {
      _logger('chat socket reconnected for emit');
      _socket.emit('chat', payload.toJson());
      complete();
    };
    onConnectError = (dynamic error) {
      failWith(StateError('Socket connect error while sending chat: $error'));
    };

    timer = Timer(timeout, () {
      failWith(TimeoutException('chat emit connect timed out', timeout));
    });

    _socket.onConnect(onConnect);
    _socket.onConnectError(onConnectError);
    _socket.connect();

    try {
      await completer.future;
    } finally {
      timer.cancel();
      _socket.off('connect', onConnect);
      _socket.off('connect_error', onConnectError);
    }
  }

  @override
  Future<void> leaveChat(
    String chatId, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final normalizedChatId = chatId.trim();
    if (normalizedChatId.isEmpty) {
      return;
    }
    _logger('leave_chat emit on active socket, chat_id=$normalizedChatId');

    if (_socket.connected) {
      _socket.emit(
        'leave_chat',
        <String, dynamic>{'chat_id': normalizedChatId},
      );
      return;
    }

    final completer = Completer<void>();
    late void Function(dynamic) onConnect;
    late void Function(dynamic) onConnectError;
    late Timer timer;

    void complete() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    void failWith(Object error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    onConnect = (_) {
      _logger('chat socket reconnected for leave_chat');
      _socket.emit(
        'leave_chat',
        <String, dynamic>{'chat_id': normalizedChatId},
      );
      complete();
    };
    onConnectError = (dynamic error) {
      failWith(StateError('Socket connect error while leaving chat: $error'));
    };

    timer = Timer(timeout, () {
      failWith(TimeoutException('leave_chat connect timed out', timeout));
    });

    _socket.onConnect(onConnect);
    _socket.onConnectError(onConnectError);
    _socket.connect();

    try {
      await completer.future;
    } finally {
      timer.cancel();
      _socket.off('connect', onConnect);
      _socket.off('connect_error', onConnectError);
    }
  }

  @override
  Future<void> dispose() async {
    _logger('chat socket closing');
    _socket.offAny(_onAnyEvent);
    _socket.offAnyOutgoing(_onAnyOutgoing);
    _socket.off('connect', _onConnect);
    _socket.off('connect_error', _onConnectError);
    _socket.off('error', _onSocketError);
    _socket.off('chat_id', _onJoinEvent);
    _socket.off('chatId', _onJoinEvent);
    _socket.off('join_chat', _onJoinEvent);
    _socket.off('join_chat_response', _onJoinEvent);
    _socket.off('join_chat_success', _onJoinEvent);
    _socket.off('chat_joined', _onJoinEvent);
    _socket.off('chat', _onChatEvent);
    _socket.off('system', _onSystemEvent);
    _socket.dispose();
    _socket.disconnect();
  }
}
