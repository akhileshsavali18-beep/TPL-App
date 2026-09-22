import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WithdrawScreen extends StatefulWidget {
  final int userCoins;
  const WithdrawScreen({super.key, required this.userCoins});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _coinsController = TextEditingController();
  bool _isLoading = false;
  double _calculatedRupees = 0.0;

  @override
  void initState() {
    super.initState();
    _coinsController.addListener(() {
      final coins = int.tryParse(_coinsController.text) ?? 0;
      setState(() {
        _calculatedRupees = coins / 100.0; // 100 Coins = ₹1.00
      });
    });
  }

  @override
  void dispose() {
    _upiController.dispose();
    _coinsController.dispose();
    super.dispose();
  }

  Future<void> _submitWithdrawal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final upiId = _upiController.text.trim();
    final coins = int.tryParse(_coinsController.text.trim()) ?? 0;

    // 1. Validations
    if (!upiId.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid UPI ID (e.g. name@okhdfcbank)')),
      );
      return;
    }

    if (coins < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum withdrawal is 500 Coins (₹5.00)')),
      );
      return;
    }

    if (coins > widget.userCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance in your wallet!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Check Admin Configuration (Cashfree Auto vs Manual)
      final configSnap = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('withdrawal_settings')
          .get();

      final bool isCashfreeAuto = configSnap.data()?['cashfree_auto'] ?? false;
      final double amountInRupees = coins / 100.0;

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final withdrawRef = FirebaseFirestore.instance.collection('withdrawals').doc();

      // Batch Write: Deduct coins immediately and create withdrawal entry
      final batch = FirebaseFirestore.instance.batch();

      batch.update(userRef, {
        'coins': FieldValue.increment(-coins),
      });

      batch.set(withdrawRef, {
        'requestId': withdrawRef.id,
        'userId': user.uid,
        'userEmail': user.email ?? 'N/A',
        'upiId': upiId,
        'coins': coins,
        'amount': amountInRupees,
        'mode': isCashfreeAuto ? 'cashfree_auto' : 'manual',
        'status': isCashfreeAuto ? 'processing' : 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // User Transaction History
      final historyRef = userRef.collection('history').doc();
      batch.set(historyRef, {
        'title': 'Withdrawal Request ($upiId)',
        'coins': coins,
        'type': 'debit',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (mounted) {
        setState(() => _isLoading = false);
        _upiController.clear();
        _coinsController.clear();

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF151922),
            title: const Text('Request Submitted!', style: TextStyle(color: Color(0xFF00FF87))),
            content: Text(
              'Your request for ₹${amountInRupees.toStringAsFixed(2)} to $upiId has been placed successfully.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OK', style: TextStyle(color: Color(0xFF00FF87))),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: const Text('Withdraw Coins to UPI', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Available Balance', style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.userCoins} Coins  (₹${(widget.userCoins / 100.0).toStringAsFixed(2)})',
                    style: const TextStyle(color: Color(0xFF00FF87), fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // UPI ID Input
            const Text('Enter UPI ID', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _upiController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. mobileNumber@ybl or id@okhdfcbank',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF151922),
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00FF87)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: Border.none),
              ),
            ),
            const SizedBox(height: 20),

            // Custom Coins Input
            const Text('Enter Coins to Withdraw', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _coinsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Min 500 coins',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF151922),
                prefixIcon: const Icon(Icons.monetization_on_outlined, color: Color(0xFFFFD700)),
                suffixText: '≈ ₹${_calculatedRupees.toStringAsFixed(2)}',
                suffixStyle: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold, fontSize: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: Border.none),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Rate: 100 Coins = ₹1.00\n• Minimum withdrawal is 500 Coins (₹5.00)',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF87),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('SUBMIT WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

