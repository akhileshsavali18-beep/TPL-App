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
  String _referralCode = '';
  bool _isLoading = true;
  bool _isGeneratingLink = false;
  List<Map<String, dynamic>> _liveReferredFriends = [];

  // 🔗 GPLinks API Configuration
  static const String _gpLinksApiToken = '6fbb840dff7b4f2e4239b3200e0d62fce9b5fbab';
  static const String _destinationAppUrl = 'https://t.me/your_tpl_channel';

  @override
  void initState() {
    super.initState();
    _fetchReferralData();
  }

  Future<void> _fetchReferralData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        final code = userDoc.data()?['referralCode'] ?? '';
        setState(() => _referralCode = code);

        if (code.isNotEmpty) {
          // Real data fetch from Firestore
          final friendsSnap = await FirebaseFirestore.instance
              .collection('users')
              .where('referredBy', isEqualTo: code)
              .get();

          if (mounted) {
            setState(() {
              _liveReferredFriends = friendsSnap.docs.map((doc) {
                final email = doc.data()['email'] ?? 'Anonymous';
                final maskedEmail = email.contains('@')
                    ? '${email.substring(0, 3)}***@${email.split('@')[1]}'
                    : email;
                return {
                  'name': doc.data()['displayName'] ?? 'TPL Player',
                  'email': maskedEmail,
                };
              }).toList();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching refer data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // GPLinks Shortener API
  Future<String> _getShortenedGPLink() async {
    try {
      final apiUrl = Uri.parse(
        'https://gplinks.in/api?api=$_gpLinksApiToken&url=${Uri.encodeComponent("$_destinationAppUrl?ref=$_referralCode")}',
      );
      final res = await http.get(apiUrl).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && data['shortenedUrl'] != null) {
          return data['shortenedUrl'];
        }
      }
    } catch (e) {
      debugPrint("GPLinks API call notice: $e");
    }
    return _destinationAppUrl;
  }

  Future<void> _shareReferral() async {
    setState(() => _isGeneratingLink = true);
    final link = await _getShortenedGPLink();
    setState(() => _isGeneratingLink = false);

    final msg = '''
🔥 Play Games & Earn Real Cash daily on TPL Pro!

1️⃣ Download App: $link
2️⃣ Use Invite Code: $_referralCode
🎁 Get ₹5 Cash Bonus instantly on signup!
💸 Instant UPI withdrawals directly to your bank!
''';

    Share.share(msg);
  }

  void _copyCode() {
    if (_referralCode.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Referral Cash Card
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
                              const Text('Referral Cash Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                          ),
                          child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Referral Code Box
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Text('YOUR INVITE CODE', style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold)),
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
                              Text(
                                _referralCode.isNotEmpty ? _referralCode : '...',
                                style: const TextStyle(color: Color(0xFF00FF87), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                                onPressed: _copyCode,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
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
                              _isGeneratingLink ? 'CREATING GPLINK...' : 'SHARE LINK ON WHATSAPP',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Real Invited Friends (No Dummy Data)
                  Text(
                    'Referred Friends (${_liveReferredFriends.length})',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_liveReferredFriends.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151922),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Center(
                        child: Text(
                          'No friends invited yet. Share your link to earn ₹5 per referral!',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _liveReferredFriends.length,
                      itemBuilder: (ctx, i) {
                        final friend = _liveReferredFriends[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151922),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 16,
                                backgroundColor: Color(0xFF00FF87),
                                child: Icon(Icons.person, color: Colors.black, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(friend['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    Text(friend['email'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Text('+₹5.00', style: TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.w900, fontSize: 13)),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
