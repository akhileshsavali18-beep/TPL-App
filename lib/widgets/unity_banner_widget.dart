import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../services/remote_config_service.dart';

class UnityBannerWidget extends StatefulWidget {
  const UnityBannerWidget({super.key});

  @override
  State<UnityBannerWidget> createState() => _UnityBannerWidgetState();
}

class _UnityBannerWidgetState extends State<UnityBannerWidget> {
  Timer? _retryTimer;
  int _retryCount = 0;
  int _bannerVersion = 0;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleRetry() {
    if (_retryCount >= 3 || !mounted) return;
    _retryCount++;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted) return;
      setState(() => _bannerVersion++);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = RemoteConfigService.instance;

    // ಅಡ್ಮಿನ್‌ನಲ್ಲಿ Ads OFF ಇದ್ದರೆ ಆ್ಯಡ್ ಬ್ಯಾನರ್ ಹೈಡ್ ಆಗುತ್ತದೆ
    if (!config.adsEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 52,
      margin: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      color: Colors.transparent,
      child: UnityBannerAd(
        key: ValueKey('${config.bannerPlacementId}-$_bannerVersion'),
        placementId: config.bannerPlacementId,
        onLoad: (placementId) => debugPrint('Unity Banner Loaded: $placementId'),
        onShown: (placementId) => debugPrint('Unity Banner Shown: $placementId'),
        onClick: (placementId) => debugPrint('Unity Banner Clicked: $placementId'),
        onFailed: (placementId, error, message) {
          debugPrint('Unity Banner Error: $placementId - $error: $message');
          _scheduleRetry();
        },
      ),
    );
  }
}

