import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/profile_drawer.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/mini_games_section.dart';
import '../widgets/unity_banner_widget.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;

  const HomeScreen({super.key, this.onOpenDrawer});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _creditCoins(int coins, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'coins': FieldValue.increment(coins),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +$coins Coins added for $reason!'),
            backgroundColor: const Color(0xFF00FF87),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B10),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget.onOpenDrawer?.call(),
        ),
        title: const Text(
          'TPL ARENA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1),
        ),
        actions: [
          // Coins Pill
          StreamBuilder<DocumentSnapshot>(
            stream: user != null
                ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                : null,
            builder: (context, snapshot) {
              int coins = 0;
              if (snapshot.hasData && snapshot.data?.data() != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                coins = int.tryParse(data['coins']?.toString() ?? '') ?? 0;
              }

              return Container(
                margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111622),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFF00FF87), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$coins',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Admin Remote Announcement Bar
            const AnnouncementBanner(),

            // 2. 📺 Top Unity Banner Ad
            const UnityBannerWidget(),

            // 3. Firestore Live Carousel Banners
            const HomeBannerCarousel(),

            const SizedBox(height: 14),

            // 4. Gamezop Mini Games Section (Firestore Realtime)
            MiniGamesSection(
              onRewardEarned: (coins, reason) => _creditCoins(coins, reason),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
