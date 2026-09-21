import 'package:flutter/material.dart';

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
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  final List<Map<String, dynamic>> banners = [
    {
      'title': '🔥 Notik Super Offerwall',
      'desc': 'Play Popular Games & Earn up to ₹500',
      'color': const Color(0xFF6C63FF),
      'tag': 'TOP OFFER'
    },
    {
      'title': '⚡ EarnKaro App Deals',
      'desc': 'Install Meesho & Kotak 811 to get ₹45 Cash',
      'color': const Color(0xFFFF6584),
      'tag': 'HIGH PAY'
    },
    {
      'title': '📱 Official Telegram Channel',
      'desc': 'Join for Daily Giveaway Codes & 100 Coins',
      'color': const Color(0xFF0088CC),
      'tag': 'FREE BONUS'
    },
    {
      'title': '📸 Follow on Instagram',
      'desc': 'Watch Payment Proofs & Earn 50 Coins',
      'color': const Color(0xFFE1306C),
      'tag': 'SOCIAL'
    },
    {
      'title': '👥 Invite & Earn Big',
      'desc': 'Get ₹5 Instant Cash on Every Friend Join',
      'color': const Color(0xFF00FF87),
      'tag': 'REFERRAL'
    },
    {
      'title': '🎯 Spin & Win Real Cash',
      'desc': '3 Free Daily Spins are Waiting for You!',
      'color': const Color(0xFFFFD700),
      'tag': 'GAMES'
    },
  ];

  @override
  Widget build(BuildContext context) {
    double rupees = widget.coins / 100.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFF1E2235),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: widget.onOpenDrawer,
        ),
        title: const Text(
          'TPL',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 22,
            color: Color(0xFF00FF87),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: widget.onOpenWallet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 5),
                  Text('${widget.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Container(
                    height: 14,
                    width: 1,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Text(
                    '₹${rupees.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FF87), fontSize: 13),
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
            // 6-Slide Hero Carousel
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _currentBannerIndex = i),
                itemBuilder: (context, index) {
                  final b = banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [b['color'].withOpacity(0.85), const Color(0xFF151922)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b['tag'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        Text(b['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(b['desc'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentBannerIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == i ? const Color(0xFF00FF87) : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Compact Chillar-style Daily Streak
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Check-in (Day 1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Claim 20 Coins daily bonus', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.streakClaimed ? null : widget.onClaimStreak,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF87),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      widget.streakClaimed ? 'CLAIMED' : 'CLAIM +20',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Dual Earning Walls (Notik + EarnKaro)
            const Text('Super Earning Walls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _cardWall(
                    title: '🎮 Notik Wall',
                    subtitle: 'Games & Surveys',
                    payout: 'Earn ₹10 - ₹200',
                    color: const Color(0xFF6C63FF),
                    onTap: () => widget.onTaskClick('Notik Wall', 500),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _cardWall(
                    title: '⚡ EarnKaro Hub',
                    subtitle: 'Meesho & Finance',
                    payout: 'Earn ₹25 - ₹100',
                    color: const Color(0xFFFF6584),
                    onTap: () => widget.onTaskClick('EarnKaro Hub', 1000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Official Social Channels
            const Text('Official Channels & Social Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _taskTile(
              title: 'Join Official Telegram',
              desc: 'Get live redeem codes & proof',
              reward: '+100 Coins (₹1.00)',
              icon: Icons.send,
              color: const Color(0xFF0088CC),
              onTap: () => widget.onTaskClick('Join Telegram', 100),
            ),
            _taskTile(
              title: 'Subscribe A28 YouTube',
              desc: 'Watch tutorials & app updates',
              reward: '+100 Coins (₹1.00)',
              icon: Icons.play_arrow,
              color: const Color(0xFFFF0000),
              onTap: () => widget.onTaskClick('Subscribe YouTube', 100),
            ),
            _taskTile(
              title: 'Follow on Instagram',
              desc: 'Follow for daily contest alerts',
              reward: '+50 Coins (₹0.50)',
              icon: Icons.camera_alt,
              color: const Color(0xFFE1306C),
              onTap: () => widget.onTaskClick('Follow Instagram', 50),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardWall({
    required String title,
    required String subtitle,
    required String payout,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151922),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(payout, style: const TextStyle(fontSize: 11, color: Color(0xFF00FF87), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _taskTile({
    required String title,
    required String desc,
    required String reward,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(reward, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
            const SizedBox(height: 2),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

