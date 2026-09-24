import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/announcement_banner.dart';
import '../widgets/home_banner_carousel.dart';
import '../widgets/unity_banner_widget.dart';
import 'cpalead_offerwall.dart';
import 'notifications.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenGames;
  const HomeScreen({super.key, this.onOpenDrawer, this.onOpenTasks, this.onOpenGames});

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
                        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('TPL PRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                          Text('🪙 ' + coins.toString() + ' Coins', style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.w800)),
                        ]);
                      },
                    ),
                  ),
                  NotificationBellButton(onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: AnnouncementBanner()),
            const SliverToBoxAdapter(child: UnityBannerWidget()),
            const SliverToBoxAdapter(child: HomeBannerCarousel()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Row(children: [
                  const Expanded(child: Text('🔥 Earn More Coins', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
                  TextButton(onPressed: onOpenTasks, child: const Text('Tasks')),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10251D), Color(0xFF111622)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.25))),
                child: Row(children: [
                  Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFF00FF87).withOpacity(0.12), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.local_offer_rounded, color: Color(0xFF00FF87), size: 28)),
                  const SizedBox(width: 14),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CPAlead Offerwall', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                    SizedBox(height: 4),
                    Text('App installs • Surveys • Signups • More offers', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ])),
                  ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CpaleadOfferwallScreen())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('OPEN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(children: [const Expanded(child: Text('🎯 Social Tasks', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))), TextButton(onPressed: onOpenTasks, child: const Text('View All'))]),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                final docs = !snapshot.hasData ? <QueryDocumentSnapshot>[] : snapshot.data!.docs.where((d) => (d.data() as Map<String, dynamic>)['isActive'] != false).take(4).toList();
                if (docs.isEmpty) return const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(16), child: Text('No social tasks available right now.', style: TextStyle(color: Colors.white38, fontSize: 12))));
                return SliverList(delegate: SliverChildBuilderDelegate((context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final title = data['title']?.toString() ?? 'Task';
                  final coins = (data['coins'] as num?)?.toInt() ?? 0;
                  return Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)), child: Row(children: [const Icon(Icons.task_alt_rounded, color: Color(0xFF00FF87)), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))), Text('+' + coins.toString(), style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.w900))]));
                }, childCount: docs.length));
              },
            ),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Row(children: [const Expanded(child: Text('🎮 Play & Win', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))), TextButton(onPressed: onOpenGames, child: const Text('Games'))])),
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 28), child: Row(children: [
              Expanded(child: _quickCard(Icons.casino_rounded, 'Spin', 'Ad → Extra Spin', onOpenGames)),
              const SizedBox(width: 9),
              Expanded(child: _quickCard(Icons.style_rounded, 'Scratch', 'Ad → Extra Scratch', onOpenGames)),
              const SizedBox(width: 9),
              Expanded(child: _quickCard(Icons.sports_esports_rounded, 'Gamezop', 'Play games', onOpenGames)),
            ]))),
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
