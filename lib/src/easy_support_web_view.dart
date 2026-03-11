import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'easy_support_error_callback.dart';
import 'models/easy_support_channel_configuration.dart';
import 'models/easy_support_config.dart';

class EasySupportWebView extends StatefulWidget {
  const EasySupportWebView({
    super.key,
    required this.config,
    this.channelConfiguration,
    this.onError,
  });

  final EasySupportConfig config;
  final EasySupportChannelConfiguration? channelConfiguration;
  final EasySupportErrorCallback? onError;

  @override
  State<EasySupportWebView> createState() => _EasySupportWebViewState();
}

class _EasySupportWebViewState extends State<EasySupportWebView> {
  late final WebViewController _controller;
  bool _isPageLoading = true;
  String? _bootstrappedForUrl;

  Uri? get _initialUri {
    final raw =
        (widget.config.webViewUrl ?? widget.config.normalizedBaseUrl).trim();
    if (raw.isEmpty) {
      return null;
    }
    return Uri.tryParse(raw);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF2F3F5))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _isPageLoading = true;
            });
          },
          onPageFinished: (url) {
            _onPageFinished(url);
          },
          onWebResourceError: (error) {
            widget.onError?.call(error);
          },
        ),
      );

    final uri = _initialUri;
    if (uri != null) {
      _controller.loadRequest(uri);
    } else {
      _isPageLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = _initialUri;
    if (uri == null) {
      return const Center(
        child: Text(
          'Invalid web view URL',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _controller)),
        if (_isPageLoading)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Color(0x66FFFFFF)),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Future<void> _onPageFinished(String url) async {
    if (mounted) {
      setState(() {
        _isPageLoading = false;
      });
    }

    if (_bootstrappedForUrl == url) {
      return;
    }
    _bootstrappedForUrl = url;

    final optionsJson = widget.config.toJavaScriptOptionsJson();
    final channelJson = jsonEncode(
        widget.channelConfiguration?.toJson() ?? <String, dynamic>{});
    final scriptUrl = _resolveScriptUrl();
    final scriptUrlJs = scriptUrl == null ? 'null' : jsonEncode(scriptUrl);

    final js = '''
(() => {
  try {
    window.__easySupportFlutter = window.__easySupportFlutter || {};
    window.__easySupportFlutter.options = $optionsJson;
    window.__easySupportFlutter.channel = $channelJson;
    const options = window.__easySupportFlutter.options || {};

    const boot = () => {
      if (!window.EasySupport || typeof window.EasySupport.init !== 'function') {
        return false;
      }
      window.EasySupport.init(options);
      if (options.autoOpen && typeof window.EasySupport.open === 'function') {
        window.EasySupport.open();
      }
      return true;
    };

    if (boot()) {
      return 'easy_support_booted';
    }

    const scriptUrl = $scriptUrlJs;
    if (!scriptUrl) {
      return 'easy_support_waiting_script';
    }

    const existing = document.querySelector('script[data-easy-support-flutter="1"]');
    if (existing) {
      return 'easy_support_script_exists';
    }

    const script = document.createElement('script');
    script.src = scriptUrl;
    script.async = true;
    script.setAttribute('data-easy-support-flutter', '1');
    script.onload = () => { boot(); };
    document.head.appendChild(script);
    return 'easy_support_script_injected';
  } catch (error) {
    return 'easy_support_bootstrap_error:' + String(error);
  }
})();
''';

    try {
      final result = await _controller.runJavaScriptReturningResult(js);
      debugPrint('EasySupport WebView bootstrap: $result');
    } catch (error) {
      debugPrint('EasySupport WebView bootstrap failed: $error');
    }
  }

  String? _resolveScriptUrl() {
    final raw = widget.channelConfiguration?.script?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    String candidate = raw;
    if (raw.contains('<script')) {
      final match = RegExp(
        r'''src\s*=\s*["']([^"']+)["']''',
        caseSensitive: false,
      ).firstMatch(raw);
      final parsed = match?.group(1)?.trim();
      if (parsed == null || parsed.isEmpty) {
        return null;
      }
      candidate = parsed;
    }

    final candidateUri = Uri.tryParse(candidate);
    if (candidateUri != null && candidateUri.hasScheme) {
      return candidate;
    }

    final baseUri = Uri.tryParse(widget.config.normalizedBaseUrl);
    if (baseUri == null) {
      return null;
    }
    return baseUri.resolve(candidate).toString();
  }
}
