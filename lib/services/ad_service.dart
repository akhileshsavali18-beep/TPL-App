import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'remote_config_service.dart';

class AdService {
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  DateTime? _lastAdTime;
  bool _isInitialized = false;

  Future<void> init() async {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled) return;
    try {
      await UnityAds.init(
        gameId: config.unityGameId,
        testMode: config.unityTestMode,
        onComplete: () {
          _isInitialized = true;
          debugPrint('Unity Ads initialized: ${config.unityGameId}');
        },
        onFailed: (error, message) {
          _isInitialized = false;
          debugPrint('Unity Ads init failed: $error - $message');
        },
      );
    } catch (e) {
      debugPrint('Unity Ads init exception: $e');
    }
  }

  bool canShowAd() {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled) return false;
    if (_lastAdTime == null) return true;
    return DateTime.now().difference(_lastAdTime!).inSeconds >= config.adCooldown;
  }

  int remainingCooldownSeconds() {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled || _lastAdTime == null) return 0;
    final remaining = config.adCooldown - DateTime.now().difference(_lastAdTime!).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<bool> _loadPlacement(String placementId) async {
    if (placementId.trim().isEmpty) return false;
    final completer = Completer<bool>();
    try {
      await UnityAds.load(
        placementId: placementId,
        onComplete: (_) {
          if (!completer.isCompleted) completer.complete(true);
        },
        onFailed: (_, __, ___) {
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('Unity ad load exception: $e');
      return false;
    }
  }


  Future<bool> showRewardedAd({
    required BuildContext context,
    required VoidCallback onReward,
    VoidCallback? onFailed,
  }) async {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled || !config.rewardedAdsEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rewarded Ads are currently unavailable.')));
      }
      onFailed?.call();
      return false;
    }
    if (!canShowAd()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please wait ${remainingCooldownSeconds()} seconds before another ad.')));
      }
      onFailed?.call();
      return false;
    }
    if (!_isInitialized) await init();
    if (!_isInitialized) { onFailed?.call(); return false; }
    final loaded = await _loadPlacement(config.rewardedPlacementId);
    if (!loaded) { onFailed?.call(); return false; }

    UnityAds.showVideoAd(
      placementId: config.rewardedPlacementId,
      onComplete: (placementId) {
        _lastAdTime = DateTime.now();
        onReward();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Unity rewarded ad failed: $message');
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ad failed to load. Please try again.')));
        onFailed?.call();
      },
      onSkipped: (placementId) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Watch the full ad to unlock the game benefit.')));
        onFailed?.call();
      },
    );
    return true;
  }

  Future<bool> showInterstitialAd({required BuildContext context, VoidCallback? onFinished}) async {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled || !config.interstitialEnabled) {
      onFinished?.call();
      return false;
    }
    if (!canShowAd()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please wait ${remainingCooldownSeconds()} seconds before another ad.')),
        );
      }
      onFinished?.call();
      return false;
    }
    if (!_isInitialized) await init();
    if (!_isInitialized) {
      onFinished?.call();
      return false;
    }
    final loaded = await _loadPlacement(config.interstitialPlacementId);
    if (!loaded) {
      onFinished?.call();
      return false;
    }

    final completer = Completer<bool>();
    void finish(bool success) {
      if (!completer.isCompleted) {
        _lastAdTime = DateTime.now();
        onFinished?.call();
        completer.complete(success);
      }
    }

    try {
      await UnityAds.showVideoAd(
        placementId: config.interstitialPlacementId,
        onComplete: (_) => finish(true),
        onFailed: (_, __, ___) => finish(false),
        onSkipped: (_) => finish(false),
      );
      return await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () => false,
      );
    } catch (e) {
      debugPrint('Unity interstitial show exception: $e');
      finish(false);
      return false;
    }
  }
}
