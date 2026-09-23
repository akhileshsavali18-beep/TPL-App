import 'package:cloud_firestore/cloud_firestore.dart';

class RemoteConfigService {
  RemoteConfigService._privateConstructor();
  static final RemoteConfigService instance = RemoteConfigService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // P1: Core Economy & Status
  int coinRate = 100;
  int referBonus = 5;
  int minTaskWithdrawal = 25;
  int minReferWithdrawal = 50;
  String announcementText = '';
  bool showAnnouncement = false;
  bool maintenanceMode = false;

  // P2: Game & Limits
  List<int> wheelSlices = [1, 50, 5, 0, 200, 12];
  int dailySpinLimit = 1;
  int dailyScratchLimit = 1;

  // P3: Security Shield
  bool blockVPN = false;
  bool blockRooted = false;
  bool oneDeviceRule = false;

  // Unity Ads Configuration (Test Mode ON for 100% Fill Rate)
  bool adsEnabled = true;
  String unityGameId = '5868205';
  int adCooldown = 60;
  String rewardedPlacementId = 'BP_Rewarded_Android';
  String interstitialPlacementId = 'Interstitial_Android';
  String bannerPlacementId = 'Banner_Android';
  bool unityTestMode = true; // ಟೆಸ್ಟಿಂಗ್ ಸಮಯದಲ್ಲಿ True ಇರಲೇಬೇಕು!

  Future<void> init() async {
    try {
      // 1. Core Economy
      _firestore.collection('settings').doc('economy').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          coinRate = int.tryParse(data['coinRate']?.toString() ?? '') ?? 100;
          referBonus = int.tryParse(data['referBonus']?.toString() ?? '') ?? 5;
          minTaskWithdrawal = int.tryParse(data['minTask']?.toString() ?? '') ?? 25;
          minReferWithdrawal = int.tryParse(data['minRefer']?.toString() ?? '') ?? 50;
          announcementText = data['announcement']?.toString() ?? '';
          showAnnouncement = data['showAnnouncement'] ?? false;
          maintenanceMode = data['maintenanceMode'] ?? false;
        }
      });

      // 2. Security Shield
      _firestore.collection('settings').doc('security').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          blockVPN = data['blockVPN'] ?? false;
          blockRooted = data['blockRooted'] ?? false;
          oneDeviceRule = data['oneDevice'] ?? false;
        }
      });

      // 3. Unity Ads Remote Switcher
      _firestore.collection('settings').doc('unity_ads').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          adsEnabled = data['adsActive'] ?? data['adsEnabled'] ?? true;
          unityGameId = data['gameId']?.toString() ?? '5868205';
          adCooldown = int.tryParse(data['cooldown']?.toString() ?? '') ?? 60;
          rewardedPlacementId = data['rewardedId']?.toString() ?? 'BP_Rewarded_Android';
          interstitialPlacementId = data['interstitialId']?.toString() ?? 'Interstitial_Android';
          bannerPlacementId = data['bannerId']?.toString() ?? 'Banner_Android';
          unityTestMode = data['testMode'] ?? true;
        }
      });
    } catch (e) {
      // Fallback
    }
  }

  double coinsToRupees(int coins) {
    if (coinRate <= 0) return 0.0;
    return coins / coinRate;
  }
}
