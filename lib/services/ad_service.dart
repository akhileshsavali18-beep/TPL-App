import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'remote_config_service.dart';

class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  DateTime? _lastAdTime;
  bool _isInitialized = false;

  /// Unity Ads ಇನಿಶಿಯಲೈಸೇಶನ್ (Admin Config ಆಧಾರದಲ್ಲಿ)
  Future<void> init() async {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled) {
      debugPrint('Unity Ads is disabled in Admin Panel.');
      return;
    }

    try {
      await UnityAds.init(
        gameId: config.unityGameId,
        testMode: config.unityTestMode,
        onComplete: () {
          _isInitialized = true;
          debugPrint('Unity Ads Initialized Successfully with ID: ${config.unityGameId}');
        },
        onFailed: (error, message) {
          _isInitialized = false;
          debugPrint('Unity Ads Init Failed: $error - $message');
        },
      );
    } catch (e) {
      debugPrint('Unity Ads init exception: $e');
    }
  }

  /// ಕೂಲ್‌ಡೌನ್ ಮುಗಿದಿದೆಯೇ ಎಂದು ಪರಿಶೀಲಿಸುವ ವಿಧಾನ
  bool canShowAd() {
    final config = RemoteConfigService.instance;
    // ಅಡ್ಮಿನ್‌ನಲ್ಲಿ ಆಡ್ಸ್ ಆಫ್ ಇದ್ದರೆ ಕೂಲ್‌ಡೌನ್ ಇರುವುದಿಲ್ಲ
    if (!config.adsEnabled) return true;
    if (_lastAdTime == null) return true;

    final difference = DateTime.now().difference(_lastAdTime!).inSeconds;
    return difference >= config.adCooldown;
  }

  /// ಮುಂದಿನ ಆಡ್ ನೋಡಲು ಬಾಕಿ ಇರುವ ಸೆಕೆಂಡುಗಳು
  int remainingCooldownSeconds() {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled || _lastAdTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastAdTime!).inSeconds;
    final remaining = config.adCooldown - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Rewarded Ad ಪ್ರದರ್ಶನ & ರಿವಾರ್ಡ್ ಹ್ಯಾಂಡ್ಲಿಂಗ್
  Future<void> showRewardedAd({
    required BuildContext context,
    required VoidCallback onReward,
    VoidCallback? onFailed,
  }) async {
    final config = RemoteConfigService.instance;

    // 1. ಅಡ್ಮಿನ್‌ನಲ್ಲಿ Ads OFF ಇದ್ದರೆ: ವಿಡಿಯೋ ಇಲ್ಲದೆ ನೇರವಾಗಿ ರಿವಾರ್ಡ್ ನೀಡುವುದು
    if (!config.adsEnabled) {
      debugPrint('Ads are turned OFF by Admin. Granting reward directly.');
      onReward();
      return;
    }

    // 2. Cooldown ಚೆಕ್
    if (!canShowAd()) {
      final waitSec = remainingCooldownSeconds();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please wait $waitSec seconds before watching another ad!'),
            backgroundColor: Colors.amber[900],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (onFailed != null) onFailed();
      return;
    }

    // 3. Unity Ads ಇನಿಶಿಯಲೈಸ್ ಆಗಿರದಿದ್ದರೆ ಮತ್ತೊಮ್ಮೆ ಪ್ರಯತ್ನಿಸುವುದು
    if (!_isInitialized) {
      await init();
    }

    // 4. Unity Rewarded Ad ತೋರಿಸುವುದು
    UnityAds.showVideoAd(
      placementId: config.rewardedPlacementId,
      onComplete: (placementId) {
        _lastAdTime = DateTime.now();
        onReward();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity Ad Show Failed: $message');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad loading failed. Please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (onFailed != null) onFailed();
      },
      onSkipped: (placementId) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Watch full video to claim rewards!'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (onFailed != null) onFailed();
      },
    );
  }
}
