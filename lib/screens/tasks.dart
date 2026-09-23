import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TasksTabScreen extends StatefulWidget {
  final Function(String, int) onCompleteTask;

  const TasksTabScreen({
    super.key,
    required this.onCompleteTask,
  });

  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> {
  // Tracking completed status locally
  final Map<String, bool> _completed = {};

  Future<void> _handleTask(String title, int coins, String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Credit coins after user visits
    if (!(_completed[title] ?? false)) {
      widget.onCompleteTask(title, coins);
      setState(() => _completed[title] = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +$coins Coins claimed for $title!'),
            backgroundColor: const Color(0xFF00FF87),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tasks & Offers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. EarnKaro Hub Card (Shifted from Home)
            const Text('💼 Partner Deals Hub', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleTask('EarnKaro Deals', 10, 'https://earnkaro.com'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EarnKaro Shopping Deals', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Shop & share Flipkart, Myntra deals to earn cashback', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Social & Channel Tasks (Original Brand Logos)
            const Text('🎯 Community & Social Tasks', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Telegram Task
            _buildSocialTile(
              title: 'Join Telegram Channel',
              subtitle: 'Get daily secret redeem codes & updates',
              coins: 25,
              brandColor: const Color(0xFF229ED9), // Telegram Blue
              icon: Icons.send_rounded,
              url: 'https://t.me/your_tpl_channel',
            ),

            const SizedBox(height: 10),

            // Instagram Task
            _buildSocialTile(
              title: 'Follow on Instagram',
              subtitle: 'Payment proofs, giveaways & winners',
              coins: 25,
              brandColor: const Color(0xFFE1306C), // Instagram Pink/Purple
              icon: Icons.camera_alt_rounded,
              url: 'https://instagram.com/your_tpl_page',
            ),

            const SizedBox(height: 10),

            // YouTube Task
            _buildSocialTile(
              title: 'Subscribe on YouTube',
              subtitle: 'Watch tutorials & earning tips',
              coins: 25,
              brandColor: const Color(0xFFFF0000), // YouTube Red
              icon: Icons.play_arrow_rounded,
              url: 'https://youtube.com/@your_tpl_channel',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTile({
    required String title,
    required String subtitle,
    required int coins,
    required Color brandColor,
    required IconData icon,
    required String url,
  }) {
    final isDone = _completed[title] ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: brandColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isDone ? null : () => _handleTask(title, coins, url),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF87),
              foregroundColor: Colors.black,
              disabledBackgroundColor: Colors.white12,
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isDone ? 'CLAIMED' : '+$coins',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
