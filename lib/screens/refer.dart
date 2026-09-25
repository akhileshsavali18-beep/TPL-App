import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/unity_banner_widget.dart';

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
  double _lockedReferralCash = 0;
  final int _requiredReferralTasks = 2;
  String _referredByCode = '';
  int _myReferralTaskProgress = 0;
  bool _myReferralUnlocked = false;

  String get _permanentReferralLink =>
      'https://akhileshsavali18-beep.github.io/TPL-App/ref.html?ref=${Uri.encodeComponent(_referralCode)}';

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
      final userData = userDoc.data() ?? {};
      final code = (userData['referralCode'] ?? '').toString();
      final locked = (userData['referCashLocked'] as num?)?.toDouble() ?? 0;
      final myProgress = (userData['referralTaskCount'] as num?)?.toInt() ??
          (userData['cpaleadQualifiedTasks'] as num?)?.toInt() ?? 0;
      final myUnlocked = userData['referralBonusUnlocked'] == true || myProgress >= _requiredReferralTasks;
      final referredBy = (userData['referredBy'] ?? '').toString();
      if (mounted) setState(() {
        _referralCode = code;
        _lockedReferralCash = locked;
        _myReferralTaskProgress = myProgress;
        _myReferralUnlocked = myUnlocked;
        _referredByCode = referredBy;
      });

      final allLogs = await FirebaseFirestore.instance.collection('referral_logs').get();
      final logs = allLogs.docs.where((doc) =>
          (doc.data()['referrerUid'] ?? '').toString() == user.uid).toList();

      final friends = <Map<String, dynamic>>[];
      for (final log in logs.docs) {
        final logData = log.data();
        final referredUid = (logData['referredUid'] ?? '').toString();
        Map<String, dynamic> referredData = {};
        if (referredUid.isNotEmpty) {
          final refSnap = await FirebaseFirestore.instance.collection('users').doc(referredUid).get();
          referredData = refSnap.data() ?? {};
        }
        final progress = (referredData['cpaleadQualifiedTasks'] as num?)?.toInt() ??
            (referredData['referralTaskCount'] as num?)?.toInt() ?? 0;
        final required = (logData['requiredTaskCount'] as num?)?.toInt() ?? _requiredReferralTasks;
        final unlocked = logData['status'] == 'unlocked' || progress >= required;
        final bonus = (logData['bonusGiven'] as num?)?.toDouble() ?? 5.0;
        final email = (referredData['email'] ?? logData['referredEmail'] ?? 'Anonymous').toString();
        final at = email.indexOf('@');
        final maskedEmail = at > 0 ? '${email.substring(0, at).substring(0, at >= 3 ? 3 : at)}***@${email.substring(at + 1)}' : email;
        friends.add({
          'name': referredData['displayName'] ?? 'TPL Player',
          'email': maskedEmail,
          'progress': progress,
          'required': required,
          'bonus': bonus,
          'unlocked': unlocked,
        });
      }
      if (mounted) setState(() => _liveReferredFriends = friends);
    } catch (e) {
      debugPrint('Error fetching referral data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _shareReferral() async {
    if (_referralCode.isEmpty) return;
    setState(() => _isGeneratingLink = true);
    final link = _permanentReferralLink;
    final msg = '''
🔥 Join TPL PRO and earn rewards!

📲 Download TPL PRO:
$link

🎁 Invite Code: $_referralCode
💰 Complete tasks and earn coins.
''';
    await Share.share(msg);
    if (mounted) setState(() => _isGeneratingLink = false);
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
                  const UnityBannerWidget(),
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
                              _isGeneratingLink ? 'CREATING REFERRAL LINK...' : 'SHARE LINK ON WHATSAPP',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_referredByCode.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10231C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00FF87).withOpacity(.25)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Referral Bonus Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('Invited with code $_referredByCode', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 5),
                        Text(
                          _myReferralUnlocked
                              ? '✅ Referral bonus unlocked'
                              : '$_myReferralTaskProgress/$_requiredReferralTasks verified CPAlead tasks • ₹5 locked',
                          style: TextStyle(
                            color: _myReferralUnlocked ? const Color(0xFF00FF87) : Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ]),
                    ),
                  ],
                  if (_lockedReferralCash > 0) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF211733),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(.25)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Referral Bonus Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text('₹${_lockedReferralCash.toStringAsFixed(2)} locked • Unlocks after ${_requiredReferralTasks} verified CPAlead tasks', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ]),
                    ),
                  ],

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
                          'No friends invited yet. Share your TPL PRO referral link to earn ₹5 per referral!',
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(friend['unlocked'] == true ? 'UNLOCKED' : 'LOCKED',
                                      style: TextStyle(color: friend['unlocked'] == true ? const Color(0xFF00FF87) : Colors.amber, fontWeight: FontWeight.w900, fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(friend['progress'].toString() + '/' + friend['required'].toString() + ' tasks',
                                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
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
