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
  int _withdrawalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchWithdrawalCount();
  }

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _fetchWithdrawalCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _withdrawalCount = doc.data()?['withdrawalCount'] ?? 0;
          final savedUpi = doc.data()?['upiId'];
          if (savedUpi != null && savedUpi.toString().isNotEmpty) {
            _upiController.text = savedUpi.toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching withdrawal count: $e");
    }
  }

  // 🛡️ Owner-Safe Rules: 1st Time: ₹25, Lifetime: ₹50
  int _getCashMinLimit() {
    if (_withdrawalCount == 0) return 25;
    return 50;
  }

  String _getCashLimitBadge() {
    if (_withdrawalCount == 0) return "1st Withdrawal: Min ₹25";
    return "Standard: Min ₹50";
  }

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
            content: Text('🎉 Converted coins to ₹${addedCash.toStringAsFixed(2)} Cash Balance!'),
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

  Future<void> _requestWithdrawal(bool isCashBalance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final double availableBalance = isCashBalance ? widget.taskCash : widget.referCash;
    final int minLimit = isCashBalance ? _getCashMinLimit() : 50;

    if (availableBalance < minLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal for ${isCashBalance ? "Cash Balance" : "Referral Cash"} is ₹$minLimit! Complete tasks to earn.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

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
                'Direct payout to your UPI VPA',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _upiController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter UPI ID (e.g. 9876543210@ybl)',
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
                      await FirebaseFirestore.instance.collection('withdrawals').add({
                        'uid': user.uid,
                        'userName': user.displayName ?? 'TPL Player',
                        'userEmail': user.email ?? '',
                        'upiId': upi,
                        'amount': availableBalance,
                        'type': isCashBalance ? 'Cash Balance' : 'Referral Balance',
                        'status': 'pending',
                        'mode': 'manual',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                        if (isCashBalance) 'taskCash': 0.0 else 'referCash': 0.0,
                        'upiId': upi,
                        'withdrawalCount': FieldValue.increment(1),
                      });

                      setState(() => _withdrawalCount += 1);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Withdrawal request placed! Processing shortly.'),
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
                  // Coins Bank
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
                        Text('Conversion: $rate Coins = ₹1', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
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
                            child: const Text('Convert Coins to Cash Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cash Balance Card
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
                            const Icon(Icons.account_balance_wallet, color: Color(0xFF00FF87), size: 24),
                            const SizedBox(width: 8),
                            const Text('Cash Balance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('₹${widget.taskCash.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00FF87), fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FF87).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getCashLimitBadge(),
                            style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF87),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _requestWithdrawal(true),
                            child: const Text('Withdraw Cash Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Referral Balance Card
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
                            const Text('Referral Balance', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('₹${widget.referCash.toStringAsFixed(2)}', style: const TextStyle(color: Colors.purpleAccent, fontSize: 20, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Min withdrawal: ₹50', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _requestWithdrawal(false),
                            child: const Text('Withdraw Referral Balance', style: TextStyle(fontWeight: FontWeight.bold)),
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
