import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/remote_config_service.dart';

class WalletScreen extends StatefulWidget {
  final int coins;
  final double taskCash;
  final double referCash;
  final List<String> cashHistory;
  final VoidCallback onCoinsConverted;

  const WalletScreen({
    super.key,
    required this.coins,
    required this.taskCash,
    required this.referCash,
    required this.cashHistory,
    required this.onCoinsConverted,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _upiController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  // 1. Coins inda Task Cash ge Convert mado logic
  Future<void> _convertCoinsToCash() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final config = RemoteConfigService.instance;
    final int rate = config.coinRate > 0 ? config.coinRate : 100;

    if (widget.coins < rate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum $rate coins required to convert to ₹1!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final double addedCash = widget.coins / rate;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'coins': 0,
        'taskCash': FieldValue.increment(addedCash),
        'hasConvertedToday': true,
      });

      widget.onCoinsConverted();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Successfully converted coins to ₹${addedCash.toStringAsFixed(2)} Task Cash!'),
            backgroundColor: const Color(0xFF00FF87),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 2. UPI Payout Request Create Madi Admin Payouts ge ಕಳುಹಿಸುವುದು
  Future<void> _requestWithdrawal(bool isTaskCash) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final config = RemoteConfigService.instance;
    final double availableBalance = isTaskCash ? widget.taskCash : widget.referCash;
    final int minLimit = isTaskCash ? config.minTaskWithdrawal : config.minReferWithdrawal;

    if (availableBalance < minLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal for ${isTaskCash ? "Task Cash" : "Referral Cash"} is ₹$minLimit!'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    _upiController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Withdraw ₹${availableBalance.toStringAsFixed(2)} via UPI',
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Instant payout to your VPA address',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. username@okhdfcbank',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF080B10),
                  prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF00FF87)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00FF87),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final upi = _upiController.text.trim();
                    if (!upi.contains('@') || upi.length < 5) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid UPI ID!'), backgroundColor: Colors.redAccent),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    setState(() => _isProcessing = true);

                    try {
                      // Admin Console 'payouts' collection ge request save maaduvudu
                      await FirebaseFirestore.instance.collection('payouts').add({
                        'userId': user.uid,
                        'userName': user.displayName ?? 'TPL Player',
                        'userEmail': user.email ?? '',
                        'upiId': upi,
                        'amount': availableBalance,
                        'type': isTaskCash ? 'Task Cash' : 'Referral Cash',
                        'status': 'Pending',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // User balance deduct madi UPI save maduvudu
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        if (isTaskCash) 'taskCash': 0.0 else 'referCash': 0.0,
                        'savedUpiId': upi,
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Withdrawal request submitted! Processing in 24 hrs.'),
                            backgroundColor: Color(0xFF00FF87),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isProcessing = false);
                    }
                  },
                  child: const Text('Confirm Withdrawal', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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
    final config = RemoteConfigService.instance;
    final int rate = config.coinRate > 0 ? config.coinRate : 100;
    final double coinsInRupees = widget.coins / rate;

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Wallet', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Coins Bank Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111622),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                            const SizedBox(width: 8),
                            Text('${widget.coins} Coins', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('≈ ₹${coinsInRupees.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Rate: $rate Coins = ₹1', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: widget.coins >= rate ? _convertCoinsToCash : null,
                            child: const Text('Convert Coins to Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Task Cash Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111622),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.task_alt, color: Color(0xFF00FF87), size: 24),
                            const SizedBox(width: 8),
                            const Text('Task Balance', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('₹${widget.taskCash.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00FF87), fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Min withdrawal: ₹${config.minTaskWithdrawal}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF87),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _requestWithdrawal(true),
                            child: const Text('Withdraw Task Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Referral Cash Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111622),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people_alt, color: Colors.purpleAccent, size: 24),
                            const SizedBox(width: 8),
                            const Text('Referral Balance', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('₹${widget.referCash.toStringAsFixed(2)}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Min withdrawal: ₹${config.minReferWithdrawal}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _requestWithdrawal(false),
                            child: const Text('Withdraw Referral Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
