import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'remote_config_service.dart';

class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  DateTime? _lastAdTime;

  /// Unity Ads ಇನಿಶಿಯಲೈಸೇಶನ್ (Admin Config ಆಧಾರದಲ್ಲಿ)
  Future<void> init() async {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled) return;

    await UnityAds.init(
      gameId: config.unityGameId,
      testMode: config.unityTestMode,
      onComplete: () => debugPrint('Unity Ads Initialized Successfully'),
      onFailed: (error, message) =>
          debugPrint('Unity Ads Init Failed: $error - $message'),
    );
  }

  /// ಕೂಲ್‌ಡೌನ್ ಮುಗಿದಿದೆಯೇ ಎಂದು ಪರಿಶೀಲಿಸುವ ವಿಧಾನ
  bool canShowAd() {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled) return false;
    if (_lastAdTime == null) return true;

    final difference = DateTime.now().difference(_lastAdTime!).inSeconds;
    return difference >= config.adCooldown;
  }

  /// ಮುಂದಿನ ಆಡ್ ನೋಡಲು ಬಾಕಿ ಇರುವ ಸೆಕೆಂಡುಗಳು
  int remainingCooldownSeconds() {
    final config = RemoteConfigService.instance;
    if (_lastAdTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastAdTime!).inSeconds;
    final remaining = config.adCooldown - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Rewarded Ad ಪ್ರದರ್ಶನ & ರಿವಾರ್ಡ್ ಹ್ಯಾಂಡ್ಲಿಂಗ್
  void showRewardedAd({
    required BuildContext context,
    required VoidCallback onReward,
    VoidCallback? onFailed,
  }) {
    final config = RemoteConfigService.instance;

    // 1. ಅಡ್ಮಿನ್‌ನಲ್ಲಿ ಆಡ್ಸ್ ಆಫ್ ಇದ್ದರೆ ಡೈರೆಕ್ಟ್ ರಿವಾರ್ಡ್
    if (!config.adsEnabled) {
      onReward();
      return;
    }

    // 2. Cooldown ಚೆಕ್
    if (!canShowAd()) {
      final waitSec = remainingCooldownSeconds();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait $waitSec seconds before watching another ad!'),
          backgroundColor: Colors.amber[900],
        ),
      );
      if (onFailed != null) onFailed();
      return;
    }

    // 3. Unity Ad ತೋರಿಸುವುದು
    UnityAds.showVideoAd(
      placementId: config.rewardedPlacementId,
      onComplete: (placementId) {
        _lastAdTime = DateTime.now();
        onReward();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ad Failed: $message');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad loading failed. Try again in a moment.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        if (onFailed != null) onFailed();
      },
      onSkipped: (placementId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch full video to get coins!'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        if (onFailed != null) onFailed();
      },
    );
  }
}

