import 'package:flutter/material.dart';

class WalletScreen extends StatelessWidget {
  final int coins;
  final double taskCash;
  final double referCash;
  final String? savedUpiId;
  final bool hasConvertedToday;
  final bool hasTaskWithdrawnToday;
  final bool hasReferWithdrawnToday;
  final List<String> coinHistory;
  final List<String> cashHistory;
  final List<String> referHistory;

  final Function(String) onSaveUpi;
  final Function(int) onConvertCoins;
  final Function(double) onWithdrawTaskCash;
  final Function(double) onWithdrawReferCash;

  const WalletScreen({
    super.key,
    required this.coins,
    required this.taskCash,
    required this.referCash,
    required this.savedUpiId,
    required this.hasConvertedToday,
    required this.hasTaskWithdrawnToday,
    required this.hasReferWithdrawnToday,
    required this.coinHistory,
    required this.cashHistory,
    required this.referHistory,
    required this.onSaveUpi,
    required this.onConvertCoins,
    required this.onWithdrawTaskCash,
    required this.onWithdrawReferCash,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0E14),
        appBar: AppBar(
          title: const Text(
            'Passbook & Withdraw',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Linked UPI ID Status Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFF00FF87), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Linked UPI Account', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            savedUpiId ?? 'No UPI Linked',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showUpiDialog(context),
                      child: Text(
                        savedUpiId == null ? 'ADD UPI' : 'CHANGE',
                        style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.w900),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Coin Bank & Convert Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🪙 Coin Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('100 Coins = ₹1.00', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$coins Coins',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFFFD700)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: hasConvertedToday ? null : () => _showConvertDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          hasConvertedToday ? 'CONVERTED TODAY (LIMIT: 1/DAY)' : 'CONVERT COINS TO CASH',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Task Cash Balance & Withdraw Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💵 Task Cash Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${taskCash.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF00FF87)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: hasTaskWithdrawnToday ? null : () => _showWithdrawDialog(context, isTask: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          hasTaskWithdrawnToday ? 'WITHDRAWN TODAY (1/DAY)' : 'WITHDRAW TASK CASH',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Referral Cash Balance & Withdraw Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👥 Referral Cash Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      '₹${referCash.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF6C63FF)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: hasReferWithdrawnToday ? null : () => _showWithdrawDialog(context, isTask: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          hasReferWithdrawnToday ? 'WITHDRAWN TODAY (1/DAY)' : 'WITHDRAW REFERRAL CASH',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Passbook History Tabs
              const Text('Passbook History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFF00FF87),
                labelColor: Color(0xFF00FF87),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Coins History'),
                  Tab(text: 'Task Cash'),
                  Tab(text: 'Referral Cash'),
                ],
              ),
              SizedBox(
                height: 190,
                child: TabBarView(
                  children: [
                    _historyList(coinHistory),
                    _historyList(cashHistory),
                    _historyList(referHistory),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyList(List<String> items) {
    if (items.isEmpty) {
      return const Center(
        child: Text('No transaction history yet', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF00FF87)),
            const SizedBox(width: 10),
            Expanded(child: Text(items[index], style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    final textController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Convert Coins to Cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Coins: $coins', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter coins (Min 100)',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              int entered = int.tryParse(textController.text.trim()) ?? 0;
              if (entered < 100 || entered > coins) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter at least 100 coins within your balance!')),
                );
                return;
              }
              Navigator.pop(c);
              onConvertCoins(entered);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
            child: const Text('Convert Now', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showUpiDialog(BuildContext context) {
    final upiCtrl = TextEditingController(text: savedUpiId ?? '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save UPI ID'),
        content: TextField(
          controller: upiCtrl,
          decoration: const InputDecoration(
            hintText: 'e.g. 9876543210@paytm',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (upiCtrl.text.trim().isNotEmpty && upiCtrl.text.contains('@')) {
                Navigator.pop(c);
                onSaveUpi(upiCtrl.text.trim());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid UPI ID (containing @)!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            child: const Text('Save UPI', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, {required bool isTask}) {
    if (savedUpiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please link your UPI ID first!')),
      );
      _showUpiDialog(context);
      return;
    }

    double curBal = isTask ? taskCash : referCash;
    final amtCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Withdraw to $savedUpiId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: ₹${curBal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (Min ₹5)',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF87))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              double entered = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (entered >= 5 && entered <= curBal) {
                Navigator.pop(c);
                if (isTask) {
                  onWithdrawTaskCash(entered);
                } else {
                  onWithdrawReferCash(entered);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Withdrawal request for ₹${entered.toStringAsFixed(2)} submitted!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid amount (Min ₹5 up to current balance)!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

