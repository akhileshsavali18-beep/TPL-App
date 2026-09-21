import 'package:flutter/material.dart';

class TasksTabScreen extends StatelessWidget {
  final Function(String, int) onCompleteTask;

  const TasksTabScreen({
    super.key,
    required this.onCompleteTask,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E14),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0B0E14),
          elevation: 0,
          title: const Text(
            'Task Central',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00FF87),
            indicatorWeight: 3,
            labelColor: Color(0xFF00FF87),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Ongoing Tasks Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ongoingItem(
                  context,
                  title: 'Install Meesho & Place Order',
                  partner: 'EarnKaro Hub',
                  reward: '+1200 Coins (₹12.00)',
                  coins: 1200,
                  icon: Icons.shopping_bag,
                  accentColor: const Color(0xFFFF6584),
                ),
                _ongoingItem(
                  context,
                  title: 'Play Lords Mobile (Level 5)',
                  partner: 'Notik Offerwall',
                  reward: '+450 Coins (₹4.50)',
                  coins: 450,
                  icon: Icons.sports_esports,
                  accentColor: const Color(0xFF6C63FF),
                ),
                _ongoingItem(
                  context,
                  title: 'Kotak 811 Zero Balance Account',
                  partner: 'EarnKaro Finance',
                  reward: '+3500 Coins (₹35.00)',
                  coins: 3500,
                  icon: Icons.account_balance,
                  accentColor: const Color(0xFF00FF87),
                ),
                _ongoingItem(
                  context,
                  title: 'Register on Tata Neu App',
                  partner: 'EarnKaro Hub',
                  reward: '+800 Coins (₹8.00)',
                  coins: 800,
                  icon: Icons.flash_on,
                  accentColor: const Color(0xFFFFD700),
                ),
              ],
            ),

            // 2. Completed Tasks Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _completedItem(
                  title: 'Join Official Telegram Channel',
                  reward: '+100 Coins (₹1.00)',
                  status: 'Verified & Paid',
                ),
                _completedItem(
                  title: 'First Login Welcome Bonus',
                  reward: '+50 Coins (₹0.50)',
                  status: 'Auto Credited',
                ),
              ],
            ),

            // 3. Expired Tasks Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _expiredItem(
                  title: 'Special Weekend Cricket Survey',
                  reason: 'Campaign Limit Reached',
                ),
                _expiredItem(
                  title: 'Flipkart Big Billion App Task',
                  reason: 'Offer Period Ended',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ongoingItem(
    BuildContext context, {
    required String title,
    required String partner,
    required String reward,
    required int coins,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: accentColor.withOpacity(0.15),
            radius: 22,
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  partner,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  reward,
                  style: const TextStyle(
                    color: Color(0xFF00FF87),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              onCompleteTask(title, coins);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task Submitted: $reward credited!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF87),
              foregroundColor: Colors.black,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _completedItem({
    required String title,
    required String reward,
    required String status,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00FF87), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(reward, style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF87).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _expiredItem({required String title, required String reason}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.grey, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                const SizedBox(height: 2),
                Text(reason, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

