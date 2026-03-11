import 'dart:async';

import 'package:flutter/foundation.dart';

import 'easy_support_retry_scheduler.dart';
import 'models/easy_support_channel_configuration.dart';
import 'models/easy_support_config.dart';
import 'easy_support_repository.dart';

enum EasySupportInitStatus { initial, loading, ready, error }

@immutable
class EasySupportInitState {
  const EasySupportInitState._({
    required this.status,
    this.error,
    this.channelConfiguration,
  });

  const EasySupportInitState.initial()
      : this._(status: EasySupportInitStatus.initial);

  const EasySupportInitState.loading()
      : this._(status: EasySupportInitStatus.loading);

  const EasySupportInitState.ready()
      : this._(status: EasySupportInitStatus.ready);

  const EasySupportInitState.readyWith(
    EasySupportChannelConfiguration channelConfiguration,
  ) : this._(
          status: EasySupportInitStatus.ready,
          channelConfiguration: channelConfiguration,
        );

  const EasySupportInitState.error(Object error)
      : this._(status: EasySupportInitStatus.error, error: error);

  final EasySupportInitStatus status;
  final Object? error;
  final EasySupportChannelConfiguration? channelConfiguration;

  bool get isReady => status == EasySupportInitStatus.ready;
}

class EasySupportController extends ValueNotifier<EasySupportInitState> {
  EasySupportController({
    required EasySupportRepository repository,
    EasySupportRetryScheduler? retryScheduler,
  })  : _repository = repository,
        _retryScheduler = retryScheduler ?? EasySupportRetryScheduler(),
        super(const EasySupportInitState.initial());

  final EasySupportRepository _repository;
  final EasySupportRetryScheduler _retryScheduler;
  Future<EasySupportChannelConfiguration>? _inFlightInitialization;
  Completer<EasySupportChannelConfiguration>? _pendingNetworkRetry;
  EasySupportConfig? _lastConfig;
  bool _isRetrying = false;

  Future<EasySupportChannelConfiguration> initialize(EasySupportConfig config) {
    _lastConfig = config;
    final readyChannelConfiguration = value.channelConfiguration;
    if (value.isReady && readyChannelConfiguration != null) {
      return Future<EasySupportChannelConfiguration>.value(
        readyChannelConfiguration,
      );
    }

    final inFlightInitialization = _inFlightInitialization;
    if (inFlightInitialization != null) {
      return inFlightInitialization;
    }

    value = const EasySupportInitState.loading();
    final initialization =
        _repository.fetchChannelKey(config).then((channelConfiguration) {
      _retryScheduler.stop();
      value = EasySupportInitState.readyWith(channelConfiguration);
      return channelConfiguration;
    }).catchError((Object error, StackTrace stackTrace) {
      value = EasySupportInitState.error(error);
      _inFlightInitialization = null;

      if (_isRetriableNetworkError(error)) {
        return _waitForNetworkAndRetry();
      }

      _failPendingRetry(error);
      throw error;
    });

    _inFlightInitialization = initialization;
    return initialization;
  }

  void reset() {
    _retryScheduler.stop();
    _isRetrying = false;
    _lastConfig = null;
    _inFlightInitialization = null;
    _failPendingRetry(StateError('EasySupport initialization reset.'));
    value = const EasySupportInitState.initial();
  }

  Future<EasySupportChannelConfiguration> _waitForNetworkAndRetry() {
    final pendingNetworkRetry = _pendingNetworkRetry;
    if (pendingNetworkRetry != null) {
      return pendingNetworkRetry.future;
    }

    final completer = Completer<EasySupportChannelConfiguration>();
    _pendingNetworkRetry = completer;
    _retryScheduler.start(_retryLastKnownConfig);
    return completer.future;
  }

  Future<void> _retryLastKnownConfig() async {
    if (_isRetrying) {
      return;
    }

    final config = _lastConfig;
    if (config == null) {
      _failPendingRetry(StateError('EasySupport config is missing.'));
      _retryScheduler.stop();
      return;
    }

    _isRetrying = true;
    try {
      final channelConfiguration = await _repository.fetchChannelKey(config);
      _retryScheduler.stop();
      _inFlightInitialization = null;
      value = EasySupportInitState.readyWith(channelConfiguration);
      _completePendingRetry(channelConfiguration);
    } catch (error) {
      value = EasySupportInitState.error(error);
      if (!_isRetriableNetworkError(error)) {
        _retryScheduler.stop();
        _inFlightInitialization = null;
        _failPendingRetry(error);
      }
    } finally {
      _isRetrying = false;
    }
  }

  bool _isRetriableNetworkError(Object error) {
    return error is EasySupportApiException && error.isNetworkError;
  }

  void _completePendingRetry(
    EasySupportChannelConfiguration channelConfiguration,
  ) {
    final pendingNetworkRetry = _pendingNetworkRetry;
    _pendingNetworkRetry = null;
    if (pendingNetworkRetry != null && !pendingNetworkRetry.isCompleted) {
      pendingNetworkRetry.complete(channelConfiguration);
    }
  }

  void _failPendingRetry(Object error) {
    final pendingNetworkRetry = _pendingNetworkRetry;
    _pendingNetworkRetry = null;
    if (pendingNetworkRetry != null && !pendingNetworkRetry.isCompleted) {
      pendingNetworkRetry.completeError(error);
    }
  }
}
