import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

class ReferScreen extends StatefulWidget {
  final double referCash;
  final List<Map<String, String>> invitedFriends;
  final VoidCallback onNavigateToWallet;

  const ReferScreen({
    super.key,
    required this.referCash,
    required this.invitedFriends,
    required this.onNavigateToWallet,
  });

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  String _referralCode = 'TPLFREE';
  bool _isLoadingCode = true;
  bool _isGeneratingLink = false;

  // 🔗 GPLINKS CONFIGURATION:
  // GPLinks ಡ್ಯಾಶ್‌ಬೋರ್ಡ್‌ನಲ್ಲಿ ಸಿಗುವ API Token ಅನ್ನು ಇಲ್ಲಿ ಹಾಕಿ (ಉಚಿತವಾಗಿ ಸಿಗುತ್ತದೆ)
  static const String _gpLinksApiToken = 'YOUR_GPLINKS_API_KEY';
  
  // ನಿಮ್ಮ APK ಡೌನ್‌ಲೋಡ್ ಲಿಂಕ್ (GitHub Releases / Drive / Telegram)
  static const String _appDownloadDestinationUrl = 'https://t.me/your_tpl_channel';

  @override
  void initState() {
    super.initState();
    _fetchUserReferralCode();
  }

  Future<void> _fetchUserReferralCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoadingCode = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final code = doc.data()!['referralCode'];
        if (code != null && code.toString().isNotEmpty) {
          setState(() {
            _referralCode = code.toString();
            _isLoadingCode = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching refer code: $e");
    }

    setState(() => _isLoadingCode = false);
  }

  // GPLinks API ಮೂಲಕ ಶಾರ್ಟ್ ಲಿಂಕ್ ಪಡೆಯುವುದು
  Future<String> _getShortenedGPLink() async {
    // API Token ಹಾಕಿಲ್ಲದಿದ್ದರೆ ಡೈರೆಕ್ಟ್ ಡೆಸ್ಟಿನೇಷನ್ ಲಿಂಕ್ ಶೇರ್ ಆಗುತ್ತದೆ
    if (_gpLinksApiToken == 'YOUR_GPLINKS_API_KEY' || _gpLinksApiToken.isEmpty) {
      return _appDownloadDestinationUrl;
    }

    try {
      final apiUrl = Uri.parse(
        'https://gplinks.in/api?api=$_gpLinksApiToken&url=${Uri.encodeComponent("$_appDownloadDestinationUrl?ref=$_referralCode")}',
      );
      final res = await http.get(apiUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && data['shortenedUrl'] != null) {
          return data['shortenedUrl'];
        }
      }
    } catch (e) {
      debugPrint("GPLinks API error: $e");
    }

    return _appDownloadDestinationUrl;
  }

  Future<void> _shareReferral() async {
    setState(() => _isGeneratingLink = true);
    final shortLink = await _getShortenedGPLink();
    setState(() => _isGeneratingLink = false);

    final shareMsg = '''
🔥 Play Games & Earn Real Cash daily on TPL Pro!

1️⃣ Download App: $shortLink
2️⃣ Use my Invite Code: $_referralCode
🎁 Get 50 Free Welcome Coins instantly!
💸 Minimum payout is just ₹5 via UPI!
''';

    Share.share(shareMsg);
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral Code copied to clipboard!'),
        backgroundColor: Color(0xFF00FF87),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Refer & Earn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Referral Balance Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C194D), Color(0xFF151922)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.group_add_rounded, color: Colors.purpleAccent, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Referral Cash', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          '₹${widget.referCash.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.purpleAccent, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.onNavigateToWallet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. How it works
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How Referral Works', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _buildStepRow('1', 'Share your GPLinks download link with friends.'),
                  const SizedBox(height: 8),
                  _buildStepRow('2', 'Friend registers using your Invite Code & gets 50 Coins.'),
                  const SizedBox(height: 8),
                  _buildStepRow('3', 'You get ₹5 Referral Cash directly to your wallet!'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Referral Code Box
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('YOUR UNIQUE INVITE CODE', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF080B10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _isLoadingCode
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00FF87)))
                            : Text(
                                _referralCode,
                                style: const TextStyle(color: Color(0xFF00FF87), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                              ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                          onPressed: _copyReferralCode,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isGeneratingLink ? null : _shareReferral,
                      icon: _isGeneratingLink
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        _isGeneratingLink ? 'GENERATING LINK...' : 'SHARE LINK ON WHATSAPP',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Row(
      children: [
        CircleAvatar(
          radius: 11,
          backgroundColor: const Color(0xFF00FF87).withOpacity(0.2),
          child: Text(number, style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }
}
