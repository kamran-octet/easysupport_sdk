import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'easy_support_view.dart';
import 'models/easy_support_channel_configuration.dart';
import 'models/easy_support_config.dart';
import 'widgets/easy_support_color_utils.dart';

class EasySupportScreen extends StatelessWidget {
  const EasySupportScreen({
    super.key,
    required this.config,
    this.channelConfiguration,
    this.useSafeArea = true,
    this.onError,
  });

  final EasySupportConfig config;
  final EasySupportChannelConfiguration? channelConfiguration;
  final bool useSafeArea;
  final EasySupportErrorCallback? onError;

  @override
  Widget build(BuildContext context) {
    final primaryColor = EasySupportColorUtils.parseHexColor(
      channelConfiguration?.widgetColor,
      fallback: const Color(0xFFF50A0A),
    );
    final onPrimaryColor = EasySupportColorUtils.onColor(primaryColor);
    final systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: primaryColor,
      statusBarIconBrightness:
          onPrimaryColor == Colors.white ? Brightness.light : Brightness.dark,
      statusBarBrightness:
          onPrimaryColor == Colors.white ? Brightness.dark : Brightness.light,
    );

    final content = EasySupportView(
      config: config,
      channelConfiguration: channelConfiguration,
      isFullScreen: true,
      onError: onError,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: Scaffold(
        backgroundColor: primaryColor,
        body: useSafeArea ? SafeArea(child: content) : content,
      ),
    );
  }
}
