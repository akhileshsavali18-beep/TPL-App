import 'package:cloud_firestore/cloud_firestore.dart';

class RemoteConfigService {
  RemoteConfigService._privateConstructor();
  static final RemoteConfigService instance = RemoteConfigService._privateConstructor();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // P1: Core Economy & Status
  int coinRate = 100;
  int referBonus = 5;
  int minTaskWithdrawal = 10;
  int minReferWithdrawal = 50;
  String announcementText = '';
  bool showAnnouncement = false;
  bool maintenanceMode = false;

  // P2: Game & Limits
  List<int> wheelSlices = [10, 50, 25, 100, 15, 200];
  int dailySpinLimit = 3;
  int dailyScratchLimit = 2;

  // P3: Security Shield
  bool blockVPN = false;
  bool blockRooted = false;
  bool oneDeviceRule = false;

  // Unity Ads Configuration
  bool adsEnabled = true;
  String unityGameId = '5868205';
  int adCooldown = 60;
  String rewardedPlacementId = 'Rewarded_Android';
  String interstitialPlacementId = 'Interstitial_Android';
  bool unityTestMode = false;

  /// ಆ್ಯಪ್ ಆರಂಭದಲ್ಲಿ ಒಮ್ಮೆ ಕರೆದು ರಿಯಲ್-ಟೈಮ್ ಲಿಸನರ್ ಸೆಟ್ ಮಾಡುವುದು
  Future<void> init() async {
    try {
      // 1. Core Config Listener
      _firestore.collection('app_config').doc('core').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          coinRate = data['coinRate'] ?? 100;
          referBonus = data['referBonus'] ?? 5;
          minTaskWithdrawal = data['minTask'] ?? 10;
          minReferWithdrawal = data['minRefer'] ?? 50;
          announcementText = data['announcement'] ?? '';
          showAnnouncement = data['showAnnouncement'] ?? false;
          maintenanceMode = data['maintenanceMode'] ?? false;
        }
      });

      // 2. Game Config Listener
      _firestore.collection('app_config').doc('game').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          if (data['wheelSlices'] != null) {
            wheelSlices = List<int>.from(data['wheelSlices']);
          }
          dailySpinLimit = data['spinLimit'] ?? 3;
          dailyScratchLimit = data['scratchLimit'] ?? 2;
        }
      });

      // 3. Security Config Listener
      _firestore.collection('app_config').doc('security').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          blockVPN = data['blockVPN'] ?? false;
          blockRooted = data['blockRooted'] ?? false;
          oneDeviceRule = data['oneDevice'] ?? false;
        }
      });

      // 4. Unity Ads Config Listener
      _firestore.collection('app_config').doc('ads').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          adsEnabled = data['adsEnabled'] ?? true;
          unityGameId = data['gameId'] ?? '5868205';
          adCooldown = data['cooldown'] ?? 60;
          rewardedPlacementId = data['rewardedId'] ?? 'Rewarded_Android';
          interstitialPlacementId = data['interstitialId'] ?? 'Interstitial_Android';
          unityTestMode = data['testMode'] ?? false;
        }
      });
    } catch (e) {
      // Fallback: ನೆಟ್‌ವರ್ಕ್ ಇಲ್ಲದಿದ್ದರೂ ಆ್ಯಪ್ ಕ್ರ್ಯಾಶ್ ಆಗದೆ ಡಿಫಾಲ್ಟ್ ವ್ಯಾಲ್ಯೂ ಬಳಸುವುದು
    }
  }

  /// Coins ಇಂದ ರೂಪಾಯಿಗೆ ಕನ್ವರ್ಟ್ ಮಾಡುವ ಹೆಲ್ಪರ್ ಫಂಕ್ಷನ್
  double coinsToRupees(int coins) {
    if (coinRate <= 0) return 0.0;
    return coins / coinRate;
  }
}

