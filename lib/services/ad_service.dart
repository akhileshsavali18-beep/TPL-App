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

  Future<bool> _consumeDailyRewardedSlot() async {
    final config = RemoteConfigService.instance;
    if (config.rewardedDailyLimit <= 0) return true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    try {
      var allowed = false;
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() ?? <String, dynamic>{};
        final oldDate = data['rewardedAdsDate']?.toString() ?? '';
        final count = oldDate == key ? ((data['rewardedAdsCount'] as num?)?.toInt() ?? 0) : 0;
        if (count >= config.rewardedDailyLimit) return;
        allowed = true;
        tx.set(ref, {'rewardedAdsDate': key, 'rewardedAdsCount': count + 1}, SetOptions(merge: true));
      });
      return allowed;
    } catch (e) {
      debugPrint('Rewarded ad daily limit check failed: $e');
      return false;
    }
  }

  Future<void> showRewardedAd({
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
      return;
    }
    if (!canShowAd()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please wait ${remainingCooldownSeconds()} seconds before another ad.')));
      }
      onFailed?.call();
      return;
    }
    if (!_isInitialized) await init();
    if (!_isInitialized) { onFailed?.call(); return; }
    if (!await _consumeDailyRewardedSlot()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily rewarded-ad limit reached.')));
      }
      onFailed?.call();
      return;
    }

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
  }

  Future<bool> showInterstitialAd({required BuildContext context, VoidCallback? onFinished}) async {
    final config = RemoteConfigService.instance;
    if (!config.adsEnabled || !config.interstitialEnabled) { onFinished?.call(); return false; }
    if (!_isInitialized) await init();
    if (!_isInitialized) { onFinished?.call(); return false; }
    final loaded = await _loadPlacement(config.interstitialPlacementId);
    if (!loaded) { onFinished?.call(); return false; }
    UnityAds.showVideoAd(
      placementId: config.interstitialPlacementId,
      onComplete: (_) { _lastAdTime = DateTime.now(); onFinished?.call(); },
      onFailed: (_, __, ___) => onFinished?.call(),
      onSkipped: (_) => onFinished?.call(),
    );
    return true;
  }
}
