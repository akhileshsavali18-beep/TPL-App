import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/unity_banner_widget.dart';
import 'notifications.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenTasks;
  const HomeScreen({super.key, this.onOpenDrawer, this.onOpenTasks});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: const BoxDecoration(color: Color(0xFF0D111A), border: Border(bottom: BorderSide(color: Color(0xFF1E2230)))),
                child: Row(children: [
                  IconButton(onPressed: onOpenDrawer, icon: const Icon(Icons.menu_rounded, color: Colors.white)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: user == null ? null : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data() as Map<String, dynamic>?;
                        final coins = (data?['coins'] as num?)?.toInt() ?? 0;
                        return const Text(
                          'TPL PRO',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
                        );
                      },
                    ),
                  ),
                  StreamBuilder<DocumentSnapshot>(
                    stream: user == null ? null : FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data() as Map<String, dynamic>?;
                      final coins = (data?['coins'] as num?)?.toInt() ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF87).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.20)),
                        ),
                        child: Text(
                          '🪙 $coins',
                          style: const TextStyle(color: Color(0xFF00FF87), fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  NotificationBellButton(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: AnnouncementBanner()),
            const SliverToBoxAdapter(child: UnityBannerWidget()),
            const SliverToBoxAdapter(child: HomeBannerCarousel()),
            // Quick earning/play categories directly below the banner, matching the compact Chillar-style home flow.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: Row(
                  children: [
                    Expanded(child: _quickCard(Icons.rotate_right_rounded, 'Spin', 'Spin & earn', onOpenTasks)),
                    const SizedBox(width: 8),
                    Expanded(child: _quickCard(Icons.confirmation_number_rounded, 'Scratch', 'Scratch & earn', onOpenTasks)),
                    const SizedBox(width: 8),
                    Expanded(child: _quickCard(Icons.groups_rounded, 'Social', 'Earn coins', onOpenTasks)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _quickCard(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: Column(children: [
      Icon(icon, color: const Color(0xFF00FF87), size: 24),
      const SizedBox(height: 6),
      Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
      const SizedBox(height: 2),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 8)),
    ])));
  }
}
