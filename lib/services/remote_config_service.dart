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

  // Unity Ads Configuration
  bool adsEnabled = true;
  String unityGameId = '5868205';
  int adCooldown = 60;
  String rewardedPlacementId = 'BP_Rewarded_Android';
  String interstitialPlacementId = 'Interstitial_Android';
  bool unityTestMode = false;

  /// ಆ್ಯಪ್ ಆರಂಭದಲ್ಲಿ ಒಮ್ಮೆ ಕರೆದು ಅಡ್ಮಿನ್ ಸೆಟ್ಟಿಂಗ್ಸ್ ರಿಯಲ್-ಟೈಮ್ ಸಿಂಕ್ ಮಾಡುವುದು
  Future<void> init() async {
    try {
      // 1. Core Economy Listener (Admin: settings/economy)
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

      // 2. Game Controls Listener (Admin: settings/game_limits ಅಥವಾ settings/economy)
      _firestore.collection('settings').doc('game_limits').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          if (data['wheelSlices'] != null) {
            if (data['wheelSlices'] is String) {
              wheelSlices = (data['wheelSlices'] as String)
                  .split(',')
                  .map((e) => int.tryParse(e.trim()) ?? 0)
                  .toList();
            } else if (data['wheelSlices'] is List) {
              wheelSlices = List<int>.from(data['wheelSlices']);
            }
          }
          dailySpinLimit = int.tryParse(data['spinLimit']?.toString() ?? '') ?? 1;
          dailyScratchLimit = int.tryParse(data['scratchLimit']?.toString() ?? '') ?? 1;
        }
      });

      // 3. Security Shield Listener (Admin: settings/security)
      _firestore.collection('settings').doc('security').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          blockVPN = data['blockVPN'] ?? false;
          blockRooted = data['blockRooted'] ?? false;
          oneDeviceRule = data['oneDevice'] ?? false;
        }
      });

      // 4. Unity Ads Remote Switcher Listener (Admin: settings/unity_ads)
      _firestore.collection('settings').doc('unity_ads').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null) {
          final data = snap.data()!;
          // ಅಡ್ಮಿನ್ 'adsActive' ಅಥವಾ 'adsEnabled' ಎರಡನ್ನೂ ಸಪೋರ್ಟ್ ಮಾಡುತ್ತದೆ
          adsEnabled = data['adsActive'] ?? data['adsEnabled'] ?? true;
          unityGameId = data['gameId']?.toString() ?? '5868205';
          adCooldown = int.tryParse(data['cooldown']?.toString() ?? '') ?? 60;
          rewardedPlacementId = data['rewardedId']?.toString() ?? 'BP_Rewarded_Android';
          interstitialPlacementId = data['interstitialId']?.toString() ?? 'Interstitial_Android';
          unityTestMode = data['testMode'] ?? false;
        }
      });

      // Fallback: Legacy app_config ಗೂ ಲಿಸನ್ ಮಾಡುವುದು
      _firestore.collection('app_config').doc('core').snapshots().listen((snap) {
        if (snap.exists && snap.data() != null && !showAnnouncement) {
          final data = snap.data()!;
          announcementText = data['announcement'] ?? announcementText;
          showAnnouncement = data['showAnnouncement'] ?? showAnnouncement;
        }
      });
    } catch (e) {
      // ನೆಟ್‌ವರ್ಕ್ ಇಲ್ಲದಿದ್ದರೂ ಡೀಫಾಲ್ಟ್ ವ್ಯಾಲ್ಯೂಗಳೊಂದಿಗೆ ಆ್ಯಪ್ ರನ್ ಆಗುತ್ತದೆ
    }
  }

  /// Coins ಇಂದ ರೂಪಾಯಿಗೆ ಕನ್ವರ್ಟ್ ಮಾಡುವ ಹೆಲ್ಪರ್ ಫಂಕ್ಷನ್
  double coinsToRupees(int coins) {
    if (coinRate <= 0) return 0.0;
    return coins / coinRate;
  }
}
