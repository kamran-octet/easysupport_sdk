import 'dart:async';

class EasySupportRetryScheduler {
  EasySupportRetryScheduler({Duration? interval})
      : _interval = interval ?? const Duration(seconds: 5);

  final Duration _interval;
  Timer? _timer;
  bool _isRunningTask = false;

  void start(Future<void> Function() task) {
    if (_timer != null) {
      return;
    }

    _timer = Timer.periodic(_interval, (_) async {
      if (_isRunningTask) {
        return;
      }
      _isRunningTask = true;
      try {
        await task();
      } finally {
        _isRunningTask = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunningTask = false;
  }
}
