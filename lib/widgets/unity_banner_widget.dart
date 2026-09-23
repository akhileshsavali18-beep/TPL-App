import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import '../services/remote_config_service.dart';

class UnityBannerWidget extends StatelessWidget {
  const UnityBannerWidget({super.key});

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
        placementId: config.bannerPlacementId,
        onLoad: (placementId) => debugPrint('Unity Banner Loaded: $placementId'),
        onClick: (placementId) => debugPrint('Unity Banner Clicked: $placementId'),
        onFailed: (placementId, error, message) =>
            debugPrint('Unity Banner Error: $placementId - $error: $message'),
      ),
    );
  }
}

