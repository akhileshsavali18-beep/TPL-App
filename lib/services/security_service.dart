import 'dart:io';
import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

class SecurityService {
  SecurityService._privateConstructor();
  static final SecurityService instance = SecurityService._privateConstructor();

  /// ಮೊಬೈಲ್‌ನಲ್ಲಿ ಸಕ್ರಿಯ VPN ಸಂಪರ್ಕವಿದೆಯೇ ಎಂದು ಪತ್ತೆಹಚ್ಚುವುದು
  Future<bool> isVpnActive() async {
    final config = RemoteConfigService.instance;
    // ಅಡ್ಮಿನ್‌ನಲ್ಲಿ blockVPN ಆಫ್ ಇದ್ದರೆ ಚೆಕ್ ಮಾಡುವುದಿಲ್ಲ
    if (!config.blockVPN) return false;

    // ವೆಬ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಆಗಿದ್ದರೆ ಸ್ಕಿಪ್ ಮಾಡುವುದು
    if (kIsWeb) return false;

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        // VPN ಸಾಮಾನ್ಯವಾಗಿ ಬಳಸುವ ನೆಟ್‌ವರ್ಕ್ ಇಂಟರ್‌ಫೇಸ್ ಹೆಸರುಗಳು
        if (name.contains('tun') ||
            name.contains('ppp') ||
            name.contains('tap') ||
            name.contains('p2p') ||
            name.contains('vpn')) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Security VPN check error: $e');
    }
    return false;
  }
}

