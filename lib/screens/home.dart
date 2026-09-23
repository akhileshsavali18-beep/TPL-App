import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final int coins;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenWallet;
  final bool streakClaimed;
  final VoidCallback onClaimStreak;
  final Function(String, int) onTaskClick;

  const HomeScreen({
    super.key,
    required this.coins,
    required this.onOpenDrawer,
    required this.onOpenWallet,
    required this.streakClaimed,
    required this.onClaimStreak,
    required this.onTaskClick,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _bannerTimer;

  // Fallback default banners
  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'CPAlead Mega Offerwall',
      'sub': 'Complete high paying app installs & earn huge coins',
      'tag': 'HOT OFFER',
      'color1': const Color(0xFF00B09B),
      'color2': const Color(0xFF96C93D),
      'targetUrl': 'https://fasttrk.net/offers?id=cpalead_tpl',
    },
    {
      'title': 'Instant UPI Withdrawals',
      'sub': 'Safe & direct cash payouts to your bank account',
      'tag': 'FAST PAYOUT',
      'color1': const Color(0xFF6A11CB),
      'color2': const Color(0xFF2575FC),
      'targetUrl': null,
    },
    {
      'title': 'Lucky Spin & Win',
      'sub': 'Spin the wheel daily to grab bonus coins',
      'tag': 'DAILY FREE',
      'color1': const Color(0xFFFF416C),
      'color2': const Color(0xFFFF4B2B),
      'targetUrl': null,
    },
  ];

  String _cpaleadUrl = 'https://fasttrk.net/offers?id=cpalead_tpl';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _listenRemoteOfferwalls();

    // Auto-scroll banners every 4 seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Listen to Admin Panel Offerwalls Config
  void _listenRemoteOfferwalls() {
    FirebaseFirestore.instance.collection('settings').doc('offerwalls').snapshots().listen((snap) {
      if (snap.exists && mounted) {
        final data = snap.data();
        if (data != null && data['cpaleadUrl'] != null && data['cpaleadUrl'].toString().isNotEmpty) {
          setState(() => _cpaleadUrl = data['cpaleadUrl']);
        }
      }
    });
  }

  // CPAlead In-App Browser Launcher
  Future<void> _openInAppBrowser(String url) async {
    try {
      await launchUrlString(
        url,
        mode: LaunchMode.inAppBrowserView,
      );
    } catch (e) {
      debugPrint("Error opening URL: $e");
    }
  }

  // Notifications Modal BottomSheet (Live Firestore Stream)
  void _showNotifications() {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        if (user == null) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: Text('Please login to view notifications.', style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFF00FF87), size: 22),
                      SizedBox(width: 8),
                      Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Notifications Stream from Admin Alerts & Payouts
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)));
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none_rounded, color: Colors.white.withOpacity(0.3), size: 48),
                            const SizedBox(height: 10),
                            const Text('No notifications yet', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final notif = docs[index].data() as Map<String, dynamic>;
                        final title = notif['title'] ?? '📢 Notification';
                        final message = notif['message'] ?? '';
                        final isPayout = title.toString().contains('Payout') || title.toString().contains('Withdrawal');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B0E14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPayout ? const Color(0xFF00FF87).withOpacity(0.3) : Colors.white10,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isPayout ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                color: isPayout ? const Color(0xFF00FF87) : Colors.amber,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      message,
                                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: widget.onOpenDrawer,
        ),
        title: const Text('TPL', style: TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          // Notification Bell with Unread Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: _showNotifications,
              ),
              if (user != null)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('notifications')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF87),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          // Wallet Balance Pill
          GestureDetector(
            onTap: widget.onOpenWallet,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.coins}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Carousel Banners Stream (Direct Sync with Admin Panel)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('banners').snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> activeBanners = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final colors = [
                    [const Color(0xFF00B09B), const Color(0xFF96C93D)],
                    [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
                    [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
                    [const Color(0xFFF7971E), const Color(0xFFFFD200)],
                  ];

                  int colorIdx = 0;
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final pair = colors[colorIdx % colors.length];
                    colorIdx++;

                    activeBanners.add({
                      'title': data['title'] ?? 'TPL Special Offer',
                      'sub': data['sub'] ?? 'Complete tasks & earn coins',
                      'tag': 'HOT OFFER',
                      'color1': pair[0],
                      'color2': pair[1],
                      'targetUrl': data['targetUrl'],
                    });
                  }
                } else {
                  activeBanners = _defaultBanners;
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 155,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: activeBanners.length,
                        onPageChanged: (index) => setState(() => _currentPage = index % activeBanners.length),
                        itemBuilder: (context, index) {
                          final banner = activeBanners[index % activeBanners.length];
                          return GestureDetector(
                            onTap: () {
                              if (banner['targetUrl'] != null && banner['targetUrl'].toString().startsWith('http')) {
                                _openInAppBrowser(banner['targetUrl']);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [banner['color1'] as Color, banner['color2'] as Color],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: (banner['color1'] as Color).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      banner['tag'] as String,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    banner['title'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    banner['sub'] as String,
                                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        activeBanners.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i ? const Color(0xFF00FF87) : Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Daily Check-in Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Check-in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 2),
                        Text('Claim 20 bonus coins everyday', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.streakClaimed ? null : widget.onClaimStreak,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF87),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white12,
                      disabledForegroundColor: Colors.white38,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      widget.streakClaimed ? 'CLAIMED' : 'CLAIM +20',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. CPAlead Mega Offers Card (In-App Only)
            GestureDetector(
              onTap: () => _openInAppBrowser(_cpaleadUrl),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0C2419), Color(0xFF151922)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00FF87).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFF00FF87), size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🔥 CPAlead Mega Offers',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Install Apps, Surveys & Earn Big Coins directly in app',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF00FF87), size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
