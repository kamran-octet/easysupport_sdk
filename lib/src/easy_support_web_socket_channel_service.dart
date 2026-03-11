import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'easy_support_chat_socket_connection.dart';
import 'easy_support_socket_service.dart';
import 'models/easy_support_chat_emit_payload.dart';
import 'models/easy_support_chat_message.dart';
import 'models/easy_support_config.dart';

class EasySupportWebSocketChannelService implements EasySupportSocketService {
  EasySupportWebSocketChannelService({
    Duration timeout = const Duration(seconds: 10),
  }) : _timeout = timeout;

  final Duration _timeout;

  @override
  Future<String> joinChat({
    required EasySupportConfig config,
    required String customerId,
    String? chatId,
  }) async {
    final channel = _connect(config);
    final completer = Completer<String>();
    final socketIoMode = config.webSocketChannelSocketIoMode;
    late final StreamSubscription<dynamic> subscription;

    void fail(Object error) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }

    subscription = channel.stream.listen(
      (dynamic raw) {
        final envelope = _parseEnvelope(raw, socketIoMode: socketIoMode);
        if (envelope == null) {
          return;
        }
        if (envelope.event == _pingEvent) {
          channel.sink.add('3');
          return;
        }
        if (!_isJoinEvent(envelope.event)) {
          return;
        }
        final resolvedChatId = _extractChatId(envelope.data);
        if (resolvedChatId == null || resolvedChatId.isEmpty) {
          return;
        }
        if (!completer.isCompleted) {
          completer.complete(resolvedChatId);
        }
      },
      onError: fail,
      onDone: () {
        if (!completer.isCompleted) {
          fail(StateError('WebSocket closed before join_chat response.'));
        }
      },
      cancelOnError: false,
    );

    final timer = Timer(_timeout, () {
      fail(TimeoutException('join_chat timed out', _timeout));
    });

    try {
      _sendSocketIoOpenIfNeeded(channel, socketIoMode: socketIoMode);
      _emitEvent(
        channel,
        event: 'join_chat',
        payload: _buildJoinChatPayload(
          customerId: customerId,
          channelToken: config.channelToken,
          chatId: chatId,
        ),
        socketIoMode: socketIoMode,
      );
      return await completer.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
      await channel.sink.close();
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

    final channel = _connect(config);
    final socketIoMode = config.webSocketChannelSocketIoMode;
    final joinedCompleter = Completer<void>();
    late final StreamSubscription<dynamic> subscription;

    void fail(Object error) {
      onError?.call(error);
      if (!joinedCompleter.isCompleted) {
        joinedCompleter.completeError(error);
      }
    }

    void completeJoinIfMatched(dynamic payload) {
      if (joinedCompleter.isCompleted) {
        return;
      }
      final resolvedChatId = _extractChatId(payload);
      if (resolvedChatId != null &&
          resolvedChatId.isNotEmpty &&
          resolvedChatId != normalizedChatId) {
        return;
      }
      joinedCompleter.complete();
    }

    subscription = channel.stream.listen(
      (dynamic raw) {
        final envelope = _parseEnvelope(raw, socketIoMode: socketIoMode);
        if (envelope == null) {
          return;
        }
        if (envelope.event == _pingEvent) {
          channel.sink.add('3');
          return;
        }

        final event = envelope.event;
        if (_isJoinEvent(event)) {
          completeJoinIfMatched(envelope.data);
          return;
        }

        if (event == 'chat' || event == 'system') {
          final message = _extractIncomingMessage(
            envelope.data,
            fallbackChatId: normalizedChatId,
            forcedType: event == 'system' ? 'notification' : null,
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
      },
      onError: fail,
      onDone: () {
        if (!joinedCompleter.isCompleted) {
          fail(StateError('WebSocket closed before join_chat response.'));
        }
      },
      cancelOnError: false,
    );

    final timer = Timer(_timeout, () {
      fail(TimeoutException('join_chat timed out', _timeout));
    });

    try {
      _sendSocketIoOpenIfNeeded(channel, socketIoMode: socketIoMode);
      _emitEvent(
        channel,
        event: 'join_chat',
        payload: _buildJoinChatPayload(
          customerId: customerId,
          channelToken: config.channelToken,
          chatId: normalizedChatId,
        ),
        socketIoMode: socketIoMode,
      );
      await joinedCompleter.future;
      return _EasySupportWebSocketChannelConnection(
        channel: channel,
        subscription: subscription,
        socketIoMode: socketIoMode,
        logger: _log,
      );
    } catch (_) {
      await subscription.cancel();
      await channel.sink.close();
      rethrow;
    } finally {
      timer.cancel();
    }
  }

  @override
  Future<void> sendChatMessage({
    required EasySupportConfig config,
    required EasySupportChatEmitPayload payload,
  }) async {
    final channel = _connect(config);
    final socketIoMode = config.webSocketChannelSocketIoMode;
    try {
      _sendSocketIoOpenIfNeeded(channel, socketIoMode: socketIoMode);
      _emitEvent(
        channel,
        event: 'chat',
        payload: payload.toJson(),
        socketIoMode: socketIoMode,
      );
    } finally {
      await channel.sink.close();
    }
  }

  WebSocketChannel _connect(EasySupportConfig config) {
    final uri = _resolveWebSocketUri(config);
    _log('WebSocketChannel connect: $uri');
    return WebSocketChannel.connect(uri);
  }

  Uri _resolveWebSocketUri(EasySupportConfig config) {
    final explicitUrl = config.webSocketChannelUrl?.trim();
    if (explicitUrl != null && explicitUrl.isNotEmpty) {
      final parsed = Uri.tryParse(explicitUrl);
      if (parsed != null) {
        return parsed;
      }
    }

    final parsedBase = Uri.parse(config.normalizedBaseUrl);
    final resolvedScheme = parsedBase.scheme == 'https'
        ? 'wss'
        : parsedBase.scheme == 'http'
            ? 'ws'
            : parsedBase.scheme;
    final queryParameters =
        Map<String, String>.from(parsedBase.queryParameters);
    var resolvedPath = parsedBase.path;
    if (config.webSocketChannelSocketIoMode) {
      queryParameters.putIfAbsent('EIO', () => '4');
      queryParameters.putIfAbsent('transport', () => 'websocket');
      if (resolvedPath.isEmpty || resolvedPath == '/') {
        resolvedPath = '/socket.io/';
      }
    }
    return parsedBase.replace(
      scheme: resolvedScheme,
      path: resolvedPath,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  static const String _pingEvent = '__ping__';

  static _WsEnvelope? _parseEnvelope(
    dynamic raw, {
    required bool socketIoMode,
  }) {
    if (raw == null) {
      return null;
    }

    final text = raw.toString().trim();
    if (text.isEmpty) {
      return null;
    }

    if (socketIoMode) {
      if (text == '2') {
        return const _WsEnvelope(event: _pingEvent, data: null);
      }
      if (text == '3' || text.startsWith('0') || text == '40') {
        return null;
      }
      if (text.startsWith('42')) {
        final payloadText = text.substring(2);
        final decoded = _tryDecode(payloadText);
        if (decoded is List && decoded.isNotEmpty) {
          final event = decoded.first?.toString();
          final data = decoded.length > 1 ? decoded[1] : null;
          if (event != null && event.isNotEmpty) {
            return _WsEnvelope(event: event, data: data);
          }
        }
        return null;
      }
    }

    final decoded = _tryDecode(text);
    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      final event = map['event']?.toString();
      if (event != null && event.isNotEmpty) {
        return _WsEnvelope(event: event, data: map['data']);
      }
      return _WsEnvelope(event: 'chat', data: map);
    }
    if (decoded is List && decoded.isNotEmpty) {
      final event = decoded.first?.toString();
      final data = decoded.length > 1 ? decoded[1] : null;
      if (event != null && event.isNotEmpty) {
        return _WsEnvelope(event: event, data: data);
      }
    }
    return null;
  }

  static dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static void _sendSocketIoOpenIfNeeded(
    WebSocketChannel channel, {
    required bool socketIoMode,
  }) {
    if (!socketIoMode) {
      return;
    }
    channel.sink.add('40');
  }

  static void _emitEvent(
    WebSocketChannel channel, {
    required String event,
    required Map<String, dynamic> payload,
    required bool socketIoMode,
  }) {
    if (socketIoMode) {
      channel.sink.add('42${jsonEncode(<dynamic>[event, payload])}');
      return;
    }
    channel.sink.add(
      jsonEncode(
        <String, dynamic>{
          'event': event,
          'data': payload,
        },
      ),
    );
  }

  static bool _isJoinEvent(String event) {
    return event == 'join_chat' ||
        event == 'chat_id' ||
        event == 'join_chat_response' ||
        event == 'join_chat_success' ||
        event == 'chat_joined';
  }

  static Map<String, dynamic> _buildJoinChatPayload({
    required String customerId,
    required String channelToken,
    String? chatId,
  }) {
    final payload = <String, dynamic>{
      'customer_id': customerId.trim(),
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

  static String? _extractChatId(dynamic payload) {
    final map = _asMap(payload);
    if (map == null) {
      return null;
    }
    final direct = _readString(map, const <String>['chat_id', 'chatId', 'id']);
    if (direct != null) {
      return direct;
    }
    final data = _asMap(map['data']);
    if (data != null) {
      return _readString(data, const <String>['chat_id', 'chatId', 'id']);
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

  void _log(String message) {
    debugPrint('EasySupportWSChannel: $message');
  }
}

class _EasySupportWebSocketChannelConnection
    implements EasySupportChatSocketConnection {
  _EasySupportWebSocketChannelConnection({
    required WebSocketChannel channel,
    required StreamSubscription<dynamic> subscription,
    required bool socketIoMode,
    required void Function(String message) logger,
  })  : _channel = channel,
        _subscription = subscription,
        _socketIoMode = socketIoMode,
        _logger = logger;

  final WebSocketChannel _channel;
  final StreamSubscription<dynamic> _subscription;
  final bool _socketIoMode;
  final void Function(String message) _logger;

  @override
  Future<void> sendChatMessage(
    EasySupportChatEmitPayload payload, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _logger(
        'chat emit on active web_socket_channel, chat_id=${payload.chatId}');
    EasySupportWebSocketChannelService._emitEvent(
      _channel,
      event: 'chat',
      payload: payload.toJson(),
      socketIoMode: _socketIoMode,
    );
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
    _logger('leave_chat emit on active web_socket_channel, chat_id=$chatId');
    EasySupportWebSocketChannelService._emitEvent(
      _channel,
      event: 'leave_chat',
      payload: <String, dynamic>{'chat_id': normalizedChatId},
      socketIoMode: _socketIoMode,
    );
  }

  @override
  Future<void> dispose() async {
    _logger('web_socket_channel closing');
    await _subscription.cancel();
    await _channel.sink.close();
  }
}

class _WsEnvelope {
  const _WsEnvelope({
    required this.event,
    required this.data,
  });

  final String event;
  final dynamic data;
}
