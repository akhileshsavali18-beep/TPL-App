import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unity_banner_widget.dart';

class ProfileDrawer extends StatelessWidget {
  final VoidCallback? onWalletTap;
  final VoidCallback? onReferTap;

  const ProfileDrawer({
    super.key,
    this.onWalletTap,
    this.onReferTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: const Color(0xFF0D111A),
      child: SafeArea(
        child: Column(
          children: [
            // User Header Profile Section
            StreamBuilder<DocumentSnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                  : null,
              builder: (context, snapshot) {
                String name = user?.displayName ?? 'TPL Player';
                String email = user?.email ?? 'No email';
                int coins = 0;

                if (snapshot.hasData && snapshot.data?.data() != null) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['name'] ?? name;
                  coins = int.tryParse(data['coins']?.toString() ?? '') ?? 0;
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: const Color(0xFF00FF87).withOpacity(0.15),
                        child: const Icon(Icons.person, color: Color(0xFF00FF87), size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '🪙 $coins Coins',
                                style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Navigation Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildDrawerItem(Icons.account_balance_wallet, 'My Wallet & Payouts', () {
                    Navigator.pop(context);
                    onWalletTap?.call();
                  }),
                  _buildDrawerItem(Icons.history, 'Transaction History', () {
                    Navigator.pop(context);
                    _showTransactionHistory(context);
                  }),
                  _buildDrawerItem(Icons.group_add, 'Refer Friends & Earn', () {
                    Navigator.pop(context);
                    onReferTap?.call();
                  }),
                  _buildDrawerItem(Icons.shield_outlined, 'Privacy Policy & Terms', () {
                    Navigator.pop(context);
                    _showInfoDialog(context, 'Privacy Policy & Terms',
                      'TPL Pro requires a verified account for rewards and withdrawals.\n\n'
                      'Do not use VPN/proxy, automation, fake submissions or multiple accounts to abuse rewards.\n\n'
                      'UPI details are used only for payout processing.\n\n'
                      'For support, contact A28 TECHNOLOGIES through the official support channel.');
                  }),
                  _buildDrawerItem(Icons.help_outline, 'Help & Support', () {
                    Navigator.pop(context);
                    _showInfoDialog(context, 'Help & Support',
                      'Need help with TPL Pro?\n\n'
                      'For task, reward, wallet or withdrawal issues, keep your registered email and relevant transaction details ready when contacting support.');
                  }),
                ],
              ),
            ),

            // 📺 Unity Banner Ad Inside Drawer
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: UnityBannerWidget(),
            ),

            const SizedBox(height: 6),

            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white70, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00FF87))),
          ),
        ],
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: const Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('withdrawals')
                .where('uid', isEqualTo: user.uid)
                .orderBy('createdAt', descending: true)
                .limit(30)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('History could not be loaded.', style: TextStyle(color: Colors.white70)));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No withdrawal transactions yet.', style: TextStyle(color: Colors.white70)));
              }
              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final amount = data['amount']?.toString() ?? '0';
                  final status = data['status']?.toString() ?? 'pending';
                  final mode = data['mode']?.toString() ?? 'manual';
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      status == 'completed' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.schedule,
                      color: status == 'completed' ? const Color(0xFF00FF87) : status == 'rejected' ? Colors.redAccent : Colors.amber,
                    ),
                    title: Text('₹' + amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(status.toUpperCase() + ' • ' + mode.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00FF87))),
          ),
        ],
      ),
    );
  }

  static Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      onTap: onTap,
    );
  }
}

