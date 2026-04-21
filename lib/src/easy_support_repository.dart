import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'models/easy_support_channel_configuration.dart';
import 'models/easy_support_chat_messages_response.dart';
import 'models/easy_support_config.dart';
import 'models/easy_support_customer_action.dart';
import 'models/easy_support_customer_response.dart';

abstract class EasySupportRepository {
  Future<EasySupportChannelConfiguration> fetchChannelKey(
    EasySupportConfig config,
  );

  Future<EasySupportCustomerResponse> fetchCustomerById({
    required EasySupportConfig config,
    required String customerId,
  }) {
    throw UnimplementedError(
      'fetchCustomerById is not implemented in this repository.',
    );
  }

  Future<EasySupportCustomerResponse> postCustomer({
    required EasySupportConfig config,
    required EasySupportCustomerAction action,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError(
      'postCustomer is not implemented in this repository.',
    );
  }

  Future<EasySupportChatMessagesResponse> fetchCustomerChatMessages({
    required EasySupportConfig config,
    required String chatId,
    int limit = 20,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) {
    throw UnimplementedError(
      'fetchCustomerChatMessages is not implemented in this repository.',
    );
  }

  Future<void> submitFeedback({
    required EasySupportConfig config,
    required Map<String, dynamic> body,
  }) {
    throw UnimplementedError(
      'submitFeedback is not implemented in this repository.',
    );
  }

  Future<String> uploadCustomerMedia({
    required EasySupportConfig config,
    required String workspaceId,
    required String filePath,
    required String fileName,
  }) {
    throw UnimplementedError(
      'uploadCustomerMedia is not implemented in this repository.',
    );
  }
}

class EasySupportDioRepository implements EasySupportRepository {
  EasySupportDioRepository({Dio? dio}) : _dio = dio ?? Dio() {
    _enableRequestLogging();
  }

  final Dio _dio;

  @override
  Future<EasySupportChannelConfiguration> fetchChannelKey(
    EasySupportConfig config,
  ) async {
    final uri = Uri.parse('${config.normalizedApiBaseUrl}/channel/key');
    final headers = _buildRequiredHeaders(config);

    try {
      debugPrint('EasySupport init API call: ${uri.toString()}');
      debugPrint('EasySupport init headers: $headers');
      _dio.options.headers.addAll(headers);
      final response = await _dio.get<dynamic>(
        uri.toString(),
        options: _requestOptions(
          config: config,
          method: 'GET',
        ),
      );

      final statusCode = response.statusCode ?? -1;
      if (statusCode < 200 || statusCode >= 300) {
        throw EasySupportApiException(
          message: 'EasySupport init failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final rawBody = response.data;
      if (rawBody is! Map) {
        throw EasySupportApiException(
          message: 'EasySupport init failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final body = Map<String, dynamic>.from(rawBody);
      final parsedResponse = EasySupportChannelKeyResponse.fromJson(body);
      final channelConfiguration = parsedResponse.data;
      if (!parsedResponse.success || channelConfiguration == null) {
        throw EasySupportApiException(
          message: 'EasySupport init failed for ${uri.path}',
          statusCode: statusCode,
        );
      }
      return channelConfiguration;
    } on DioException catch (error) {
      final isNetworkError = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      throw EasySupportApiException(
        message: _buildDioErrorMessage(
          error,
          fallback: 'EasySupport init request failed for ${uri.path}',
        ),
        statusCode: error.response?.statusCode ?? -1,
        isNetworkError: isNetworkError,
      );
    }
  }

  @override
  Future<EasySupportCustomerResponse> postCustomer({
    required EasySupportConfig config,
    required EasySupportCustomerAction action,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse(
      '${config.normalizedApiBaseUrl}/customer/${action.name}',
    );
    final headers = _buildRequiredHeaders(config);

    try {
      debugPrint('EasySupport customer headers: $headers');
      debugPrint('EasySupport customer body: $body');
      debugPrint('EasySupport customer call: ${config.toJson()}');

      _dio.options.headers.addAll(headers);
      final response = await _dio.post<dynamic>(
        uri.toString(),
        data: body,
        options: _requestOptions(
          config: config,
          method: 'POST',
        ),
      );

      final statusCode = response.statusCode ?? -1;
      if (statusCode < 200 || statusCode >= 300) {
        throw EasySupportApiException(
          message: 'EasySupport customer call failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final rawBody = response.data;
      if (rawBody is! Map) {
        throw EasySupportApiException(
          message: 'EasySupport customer call failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final parsedResponse = EasySupportCustomerResponse.fromJson(
        Map<String, dynamic>.from(rawBody),
      );
      if (!parsedResponse.success) {
        throw EasySupportApiException(
          message: 'EasySupport customer call failed for ${uri.path}',
          statusCode: statusCode,
        );
      }
      return parsedResponse;
    } on DioException catch (error) {
      final isNetworkError = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      throw EasySupportApiException(
        message: _buildDioErrorMessage(
          error,
          fallback: 'EasySupport customer request failed for ${uri.path}',
        ),
        statusCode: error.response?.statusCode ?? -1,
        isNetworkError: isNetworkError,
      );
    }
  }

  @override
  Future<EasySupportCustomerResponse> fetchCustomerById({
    required EasySupportConfig config,
    required String customerId,
  }) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw const EasySupportApiException(
        message: 'customerId is empty; cannot fetch customer details',
        statusCode: -1,
      );
    }

    final uri = Uri.parse(
      '${config.normalizedApiBaseUrl}/customer/$normalizedCustomerId',
    );
    final headers = _buildRequiredHeaders(config);

    try {
      debugPrint('EasySupport customer get headers: $headers');
      _dio.options.headers.addAll(headers);
      final response = await _dio.get<dynamic>(
        uri.toString(),
        options: _requestOptions(
          config: config,
          method: 'GET',
        ),
      );

      final statusCode = response.statusCode ?? -1;
      if (statusCode < 200 || statusCode >= 300) {
        throw EasySupportApiException(
          message: 'EasySupport customer get failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final rawBody = response.data;
      if (rawBody is! Map) {
        throw EasySupportApiException(
          message: 'EasySupport customer get failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final parsedResponse = EasySupportCustomerResponse.fromJson(
        Map<String, dynamic>.from(rawBody),
      );
      if (!parsedResponse.success) {
        throw EasySupportApiException(
          message: 'EasySupport customer get failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      return parsedResponse;
    } on DioException catch (error) {
      final isNetworkError = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      throw EasySupportApiException(
        message: _buildDioErrorMessage(
          error,
          fallback: 'EasySupport customer get request failed for ${uri.path}',
        ),
        statusCode: error.response?.statusCode ?? -1,
        isNetworkError: isNetworkError,
      );
    }
  }

  @override
  Future<EasySupportChatMessagesResponse> fetchCustomerChatMessages({
    required EasySupportConfig config,
    required String chatId,
    int limit = 20,
    String sortOrder = 'desc',
    String sortBy = 'created_at',
  }) async {
    final uri = Uri.parse(
      '${config.normalizedApiBaseUrl}/message/customer/chat/$chatId',
    ).replace(
      queryParameters: <String, String>{
        'limit': '$limit',
        'sort_order': sortOrder,
        'sort_by': sortBy,
      },
    );
    final headers = _buildRequiredHeaders(config);

    try {
      debugPrint('EasySupport chat headers: $headers');
      _dio.options.headers.addAll(headers);
      final response = await _dio.get<dynamic>(
        uri.toString(),
        options: _requestOptions(
          config: config,
          method: 'GET',
        ),
      );

      final statusCode = response.statusCode ?? -1;
      if (statusCode < 200 || statusCode >= 300) {
        throw EasySupportApiException(
          message: 'EasySupport chat fetch failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final rawBody = response.data;
      if (rawBody is! Map) {
        throw EasySupportApiException(
          message: 'EasySupport chat fetch failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final parsedResponse = EasySupportChatMessagesResponse.fromJson(
        Map<String, dynamic>.from(rawBody),
      );
      if (!parsedResponse.success) {
        throw EasySupportApiException(
          message: 'EasySupport chat fetch failed for ${uri.path}',
          statusCode: statusCode,
        );
      }
      debugPrint(
        'EasySupport chat history loaded: ${parsedResponse.data.length} messages',
      );
      return parsedResponse;
    } on DioException catch (error) {
      final isNetworkError = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      throw EasySupportApiException(
        message: _buildDioErrorMessage(
          error,
          fallback: 'EasySupport chat request failed for ${uri.path}',
        ),
        statusCode: error.response?.statusCode ?? -1,
        isNetworkError: isNetworkError,
      );
    }
  }

  @override
  Future<void> submitFeedback({
    required EasySupportConfig config,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${config.normalizedApiBaseUrl}/feedback');
    final headers = _buildRequiredHeaders(config);

    try {
      debugPrint('EasySupport feedback headers: $headers');
      _dio.options.headers.addAll(headers);
      final response = await _dio.post<dynamic>(
        uri.toString(),
        data: body,
        options: _requestOptions(
          config: config,
          method: 'POST',
        ),
      );

      final statusCode = response.statusCode ?? -1;
      if (statusCode < 200 || statusCode >= 300) {
        throw EasySupportApiException(
          message: 'EasySupport feedback failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final rawBody = response.data;
      if (rawBody is Map) {
        final parsed = Map<String, dynamic>.from(rawBody);
        if (parsed['success'] == false) {
          throw EasySupportApiException(
            message: 'EasySupport feedback failed for ${uri.path}',
            statusCode: statusCode,
          );
        }
      }
    } on DioException catch (error) {
      final isNetworkError = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      throw EasySupportApiException(
        message: _buildDioErrorMessage(
          error,
          fallback: 'EasySupport feedback request failed for ${uri.path}',
        ),
        statusCode: error.response?.statusCode ?? -1,
        isNetworkError: isNetworkError,
      );
    }
  }

  @override
  Future<String> uploadCustomerMedia({
    required EasySupportConfig config,
    required String workspaceId,
    required String filePath,
    required String fileName,
  }) async {
    final normalizedWorkspaceId = workspaceId.trim();
    if (normalizedWorkspaceId.isEmpty) {
      throw const EasySupportApiException(
        message: 'workspace_id is empty; cannot upload media',
        statusCode: -1,
      );
    }
    final normalizedFilePath = filePath.trim();
    if (normalizedFilePath.isEmpty) {
      throw const EasySupportApiException(
        message: 'file path is empty; cannot upload media',
        statusCode: -1,
      );
    }
    final normalizedFileName = fileName.trim();
    if (normalizedFileName.isEmpty) {
      throw const EasySupportApiException(
        message: 'file name is empty; cannot upload media',
        statusCode: -1,
      );
    }

    final uri =
        Uri.parse('${config.normalizedApiBaseUrl}/media/customer/upload')
            .replace(
      queryParameters: <String, String>{
        'workspace_id': normalizedWorkspaceId,
      },
    );
    final headers = _buildRequiredHeaders(config);
    final data = FormData.fromMap(
      <String, dynamic>{
        'file': <MultipartFile>[
          await MultipartFile.fromFile(
            normalizedFilePath,
            filename: normalizedFileName,
          ),
        ],
      },
    );

    try {
      debugPrint('EasySupport media upload call: ${uri.toString()}');
      debugPrint('EasySupport media upload headers: $headers');
      _dio.options.headers.addAll(headers);
      final response = await _dio.post<dynamic>(
        uri.toString(),
        data: data,
        options: Options(
          method: 'POST',
          headers: headers,
          contentType: Headers.multipartFormDataContentType,
        ),
      );

      debugPrint(
          'EasySupport media response call: ${response.statusCode} ${response.data}');
      final statusCode = response.statusCode ?? -1;
      if (statusCode < 200 || statusCode >= 300) {
        throw EasySupportApiException(
          message: 'EasySupport media upload failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final rawBody = response.data;
      if (rawBody is! Map) {
        throw EasySupportApiException(
          message: 'EasySupport media upload failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final body = Map<String, dynamic>.from(rawBody);
      final dataNode = body['data'];
      if (dataNode is! Map) {
        throw EasySupportApiException(
          message: 'EasySupport media upload failed for ${uri.path}',
          statusCode: statusCode,
        );
      }

      final url = dataNode['url']?.toString().trim();
      if (url == null || url.isEmpty) {
        throw EasySupportApiException(
          message: 'EasySupport media upload failed for ${uri.path}',
          statusCode: statusCode,
        );
      }
      return url;
    } on DioException catch (error) {
      final isNetworkError = error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
      throw EasySupportApiException(
        message: _buildDioErrorMessage(
          error,
          fallback: 'EasySupport media upload request failed for ${uri.path}',
        ),
        statusCode: error.response?.statusCode ?? -1,
        isNetworkError: isNetworkError,
      );
    }
  }

  String _buildDioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final responseMessage = _extractResponseMessage(responseData);
    final dioMessage = error.message;

    final parts = <String>[
      fallback,
      if (statusCode != null) 'status=$statusCode',
      if (responseMessage != null && responseMessage.isNotEmpty)
        'response=$responseMessage',
      if (dioMessage != null && dioMessage.isNotEmpty) 'dio=$dioMessage',
    ];

    return parts.join(' | ');
  }

  String? _extractResponseMessage(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final message =
          map['message'] ?? map['error'] ?? map['details'] ?? map['data'];
      return message?.toString();
    }
    return data.toString();
  }

  Options _requestOptions({
    required EasySupportConfig config,
    required String method,
  }) {
    return Options(
      method: method,
      headers: _buildRequiredHeaders(config),
    );
  }

  void _enableRequestLogging() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint(
              'EasySupport Dio request: ${options.method} ${options.uri}');
          debugPrint('EasySupport Dio headers: ${options.headers}');
          handler.next(options);
        },
      ),
    );
  }

  Map<String, String> _buildRequiredHeaders(EasySupportConfig config) {
    final tokenFromChannelToken = config.channelToken.trim();
    final tokenFromChannelKey = (config.channelKey ?? '').trim();
    final token = tokenFromChannelToken.isNotEmpty
        ? tokenFromChannelToken
        : tokenFromChannelKey;
    if (token.isEmpty) {
      throw const EasySupportApiException(
        message:
            'channelToken/channelKey is empty; cannot send channelkey header',
        statusCode: -1,
      );
    }

    final headers = Map<String, String>.from(config.additionalHeaders);
    headers.remove('channelkey');
    headers.remove('channelKey');
    headers.remove('channel_key');
    headers.remove('channel-key');
    headers['channelkey'] = token;
    return headers;
  }
}

class EasySupportApiException implements Exception {
  const EasySupportApiException({
    required this.message,
    required this.statusCode,
    this.isNetworkError = false,
  });

  final String message;
  final int statusCode;
  final bool isNetworkError;

  @override
  String toString() => '$message: HTTP $statusCode';
}
