import 'dart:convert';

class EasySupportConfig {
  const EasySupportConfig({
    required this.baseUrl,
    required this.channelToken,
    this.apiBaseUrl,
    this.channelKey,
    this.name,
    this.email,
    this.widgetTitle,
    this.webViewUrl,
    this.autoOpen = true,
    this.isEmojiEnabled = true,
    this.isMediaEnabled = true,
    this.useWebSocketChannel = false,
    this.webSocketChannelUrl,
    this.webSocketChannelSocketIoMode = false,
    this.socketPath,
    this.socketNamespace,
    this.socketTransports = const <String>['websocket', 'polling'],
    this.socketQuery = const <String, dynamic>{},
    this.socketAuth = const <String, dynamic>{},
    this.additionalHeaders = const <String, String>{},
  }) : assert(channelToken != '', 'channelToken cannot be empty.');

  const EasySupportConfig.essentials({
    required String baseUrl,
    required String channelToken,
    String? name,
    String? email,
  }) : this(
          baseUrl: baseUrl,
          channelToken: channelToken,
          name: name,
          email: email,
        );

  factory EasySupportConfig.fromJson(Map<String, dynamic> json) {
    final headers = _parseHeaders(json['additional_headers']);
    final baseUrl = json['base_url'] as String? ?? json['baseUrl'] as String?;
    final channelToken =
        json['channel_token'] as String? ?? json['channelToken'] as String?;
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      throw ArgumentError.value(json, 'json', 'base_url is required');
    }
    if (channelToken == null || channelToken.trim().isEmpty) {
      throw ArgumentError.value(json, 'json', 'channel_token is required');
    }

    return EasySupportConfig(
      baseUrl: baseUrl,
      channelToken: channelToken,
      apiBaseUrl:
          json['api_base_url'] as String? ?? json['apiBaseUrl'] as String?,
      channelKey: json['channelkey'] as String? ??
          json['channel_key'] as String? ??
          json['channelKey'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      widgetTitle:
          json['widget_title'] as String? ?? json['widgetTitle'] as String?,
      webViewUrl:
          json['web_view_url'] as String? ?? json['webViewUrl'] as String?,
      autoOpen: json['auto_open'] as bool? ?? json['autoOpen'] as bool? ?? true,
      isEmojiEnabled: json['is_emoji_enabled'] as bool? ??
          json['isEmojiEnabled'] as bool? ??
          true,
      isMediaEnabled: json['is_media_enabled'] as bool? ??
          json['isMediaEnabled'] as bool? ??
          true,
      useWebSocketChannel: json['use_web_socket_channel'] as bool? ??
          json['useWebSocketChannel'] as bool? ??
          false,
      webSocketChannelUrl: json['web_socket_channel_url'] as String? ??
          json['webSocketChannelUrl'] as String?,
      webSocketChannelSocketIoMode:
          json['web_socket_channel_socket_io_mode'] as bool? ??
              json['webSocketChannelSocketIoMode'] as bool? ??
              false,
      socketPath:
          json['socket_path'] as String? ?? json['socketPath'] as String?,
      socketNamespace: json['socket_namespace'] as String? ??
          json['socketNamespace'] as String?,
      socketTransports: _parseStringList(
        json['socket_transports'] ?? json['socketTransports'],
        fallback: const <String>['websocket', 'polling'],
      ),
      socketQuery:
          _parseDynamicMap(json['socket_query'] ?? json['socketQuery']),
      socketAuth: _parseDynamicMap(json['socket_auth'] ?? json['socketAuth']),
      additionalHeaders: headers,
    );
  }

  final String baseUrl;
  final String channelToken;
  final String? apiBaseUrl;
  final String? channelKey;
  final String? name;
  final String? email;
  final String? widgetTitle;
  final String? webViewUrl;
  final bool autoOpen;
  final bool isEmojiEnabled;
  final bool isMediaEnabled;
  final bool useWebSocketChannel;
  final String? webSocketChannelUrl;
  final bool webSocketChannelSocketIoMode;
  final String? socketPath;
  final String? socketNamespace;
  final List<String> socketTransports;
  final Map<String, dynamic> socketQuery;
  final Map<String, dynamic> socketAuth;
  final Map<String, String> additionalHeaders;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'base_url': baseUrl,
      'channel_token': channelToken,
      if (apiBaseUrl != null) 'api_base_url': apiBaseUrl,
      if (channelKey != null) 'channelkey': channelKey,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (widgetTitle != null) 'widget_title': widgetTitle,
      if (webViewUrl != null) 'web_view_url': webViewUrl,
      'auto_open': autoOpen,
      'is_emoji_enabled': isEmojiEnabled,
      'is_media_enabled': isMediaEnabled,
      'use_web_socket_channel': useWebSocketChannel,
      if (webSocketChannelUrl != null)
        'web_socket_channel_url': webSocketChannelUrl,
      'web_socket_channel_socket_io_mode': webSocketChannelSocketIoMode,
      if (socketPath != null) 'socket_path': socketPath,
      if (socketNamespace != null) 'socket_namespace': socketNamespace,
      if (socketTransports.isNotEmpty) 'socket_transports': socketTransports,
      if (socketQuery.isNotEmpty) 'socket_query': socketQuery,
      if (socketAuth.isNotEmpty) 'socket_auth': socketAuth,
      if (additionalHeaders.isNotEmpty) 'additional_headers': additionalHeaders,
    };
  }

  String get normalizedBaseUrl => '${_stripTrailingSlashes(baseUrl)}/';

  String get defaultGreetingTitle {
    final normalizedName = name?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      return 'Hi there ! How can we help you';
    }
    return 'Hi $normalizedName ! How can we help you';
  }

  String resolveGreetingTitle(String? preferredTitle) {
    final normalizedPreferredTitle = preferredTitle?.trim();
    if (normalizedPreferredTitle == null || normalizedPreferredTitle.isEmpty) {
      return defaultGreetingTitle;
    }

    final normalizedName = name?.trim();
    if (normalizedName == null || normalizedName.isEmpty) {
      return normalizedPreferredTitle;
    }

    final greetingPattern = RegExp(r'hi\s+there', caseSensitive: false);
    if (greetingPattern.hasMatch(normalizedPreferredTitle)) {
      return normalizedPreferredTitle.replaceFirst(
        greetingPattern,
        'Hi $normalizedName',
      );
    }

    return normalizedPreferredTitle;
  }

  String get normalizedApiBaseUrl {
    final value = apiBaseUrl;
    if (value == null || value.trim().isEmpty) {
      return '${_stripTrailingSlashes(baseUrl)}/api/v1';
    }
    return _stripTrailingSlashes(value);
  }

  Map<String, String> get resolvedHeaders {
    final headers = _sanitizeHeaders(additionalHeaders);
    headers['channelkey'] = channelToken;
    return headers;
  }

  static Map<String, String> _sanitizeHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);
    sanitized.remove('channelkey');
    sanitized.remove('channelKey');
    sanitized.remove('channel-key');
    sanitized.remove('channel_key');
    return sanitized;
  }

  Map<String, dynamic> toJavaScriptOptions() {
    return <String, dynamic>{
      'channelToken': channelToken,
      'baseUrl': normalizedBaseUrl,
      'apiBaseUrl': normalizedApiBaseUrl,
      'autoOpen': autoOpen,
      'isEmojiEnabled': isEmojiEnabled,
      'isMediaEnabled': isMediaEnabled,
      'useWebSocketChannel': useWebSocketChannel,
      if (webSocketChannelUrl != null && webSocketChannelUrl!.trim().isNotEmpty)
        'webSocketChannelUrl': webSocketChannelUrl!.trim(),
      'webSocketChannelSocketIoMode': webSocketChannelSocketIoMode,
      if (socketPath != null && socketPath!.trim().isNotEmpty)
        'socketPath': socketPath!.trim(),
      if (socketNamespace != null && socketNamespace!.trim().isNotEmpty)
        'socketNamespace': socketNamespace!.trim(),
      if (socketTransports.isNotEmpty) 'socketTransports': socketTransports,
      if (socketQuery.isNotEmpty) 'socketQuery': socketQuery,
      if (socketAuth.isNotEmpty) 'socketAuth': socketAuth,
      if (channelKey != null && channelKey!.trim().isNotEmpty)
        'channelKey': channelKey!.trim(),
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (email != null && email!.trim().isNotEmpty) 'email': email!.trim(),
      if (widgetTitle != null && widgetTitle!.trim().isNotEmpty)
        'widgetTitle': widgetTitle!.trim(),
      if (webViewUrl != null && webViewUrl!.trim().isNotEmpty)
        'webViewUrl': webViewUrl!.trim(),
      if (resolvedHeaders.isNotEmpty) 'additionalHeaders': resolvedHeaders,
    };
  }

  String toJavaScriptOptionsJson() => jsonEncode(toJavaScriptOptions());

  EasySupportConfig copyWith({
    String? baseUrl,
    String? channelToken,
    String? apiBaseUrl,
    String? channelKey,
    String? name,
    String? email,
    String? widgetTitle,
    String? webViewUrl,
    bool? autoOpen,
    bool? isEmojiEnabled,
    bool? isMediaEnabled,
    bool? useWebSocketChannel,
    String? webSocketChannelUrl,
    bool? webSocketChannelSocketIoMode,
    String? socketPath,
    String? socketNamespace,
    List<String>? socketTransports,
    Map<String, dynamic>? socketQuery,
    Map<String, dynamic>? socketAuth,
    Map<String, String>? additionalHeaders,
  }) {
    return EasySupportConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      channelToken: channelToken ?? this.channelToken,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      channelKey: channelKey ?? this.channelKey,
      name: name ?? this.name,
      email: email ?? this.email,
      widgetTitle: widgetTitle ?? this.widgetTitle,
      webViewUrl: webViewUrl ?? this.webViewUrl,
      autoOpen: autoOpen ?? this.autoOpen,
      isEmojiEnabled: isEmojiEnabled ?? this.isEmojiEnabled,
      isMediaEnabled: isMediaEnabled ?? this.isMediaEnabled,
      useWebSocketChannel: useWebSocketChannel ?? this.useWebSocketChannel,
      webSocketChannelUrl: webSocketChannelUrl ?? this.webSocketChannelUrl,
      webSocketChannelSocketIoMode:
          webSocketChannelSocketIoMode ?? this.webSocketChannelSocketIoMode,
      socketPath: socketPath ?? this.socketPath,
      socketNamespace: socketNamespace ?? this.socketNamespace,
      socketTransports: socketTransports ?? this.socketTransports,
      socketQuery: socketQuery ?? this.socketQuery,
      socketAuth: socketAuth ?? this.socketAuth,
      additionalHeaders: additionalHeaders ?? this.additionalHeaders,
    );
  }

  static String _stripTrailingSlashes(String value) {
    return value.trim().replaceFirst(RegExp(r'/+$'), '');
  }

  static Map<String, String> _parseHeaders(dynamic value) {
    if (value is Map<String, String>) {
      return value;
    }
    if (value is Map) {
      final headers = <String, String>{};
      value.forEach((key, dynamic headerValue) {
        if (headerValue != null) {
          headers['$key'] = '$headerValue';
        }
      });
      return headers;
    }
    return const <String, String>{};
  }

  static Map<String, dynamic> _parseDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  static List<String> _parseStringList(
    dynamic value, {
    required List<String> fallback,
  }) {
    if (value is List) {
      final parsed = value
          .map((dynamic item) => '$item'.trim())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return fallback;
  }
}
