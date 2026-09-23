import 'dart:io';
import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

class SecurityService {
  SecurityService._privateConstructor();
  static final SecurityService instance = SecurityService._privateConstructor();

  /// ಮೊಬೈಲ್‌ನಲ್ಲಿ ಸಕ್ರಿಯ VPN ಸಂಪರ್ಕವಿದೆಯೇ ಎಂದು ಪತ್ತೆಹಚ್ಚುವುದು
  Future<bool> isVpnActive() async {
    // ವೆಬ್ ಪ್ಲಾಟ್‌ಫಾರ್ಮ್ ಆಗಿದ್ದರೆ ಸ್ಕಿಪ್ ಮಾಡುವುದು
    if (kIsWeb) return false;

    try {
      final config = RemoteConfigService.instance;
      // ಅಡ್ಮಿನ್‌ನಲ್ಲಿ blockVPN ಆಫ್ ಇದ್ದರೆ ಅಥವಾ ಕಾನ್ಫಿಗ್ ಲೋಡ್ ಆಗದಿದ್ದರೆ ಚೆಕ್ ಮಾಡುವುದಿಲ್ಲ
      if (!config.blockVPN) return false;

      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();

        // 1. ಸಾಮಾನ್ಯ Wi-Fi (wlan, p2p, rmnet) ಗಳನ್ನು ಇಗ್ನೋರ್ ಮಾಡುವುದು
        // 'p2p' ಎಂಬುದು Wi-Fi Direct, ಇದನ್ನು ಯಾವುದೇ ಕಾರಣಕ್ಕೂ VPN ಎಂದು ಪರಿಗಣಿಸಬಾರದು!
        if (name.contains('wlan') ||
            name.contains('p2p') ||
            name.contains('rmnet') ||
            name.contains('dummy')) {
          continue;
        }

        // 2. ನೈಜ VPN ಇಂಟರ್‌ಫೇಸ್‌ಗಳು ಮಾತ್ರ ಇದ್ದರೆ ಬ್ಲಾಕ್ ಮಾಡುವುದು
        if (name.startsWith('tun') ||
            name.startsWith('tap') ||
            name.startsWith('ppp') ||
            name.contains('vpn') ||
            name.contains('wireguard') ||
            name.contains('openvpn')) {
          return true;
        }
      }
    } catch (e) {
      debugPrint('Security VPN check error: $e');
    }
    return false;
  }
}
