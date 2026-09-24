import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/remote_config_service.dart';
import '../widgets/transaction_history.dart';
import '../widgets/unity_banner_widget.dart';

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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _coinController = TextEditingController();

  bool _isProcessing = false;
  bool _changingUpi = false;
  int _cashWithdrawalCount = 0;
  String? _savedUpi;

  @override
  void initState() {
    super.initState();
    _loadWalletMeta();
  }

  @override
  void dispose() {
    _upiController.dispose();
    _amountController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletMeta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};
      final savedUpi = data['upiId']?.toString();

      final withdrawalSnap = await FirebaseFirestore.instance
          .collection('withdrawals')
          .where('uid', isEqualTo: user.uid)
          .get();

      var cashCount = 0;
      for (final doc in withdrawalSnap.docs) {
        final type = (doc.data()['type'] ?? '').toString().toLowerCase();
        if (type.contains('cash')) cashCount++;
      }

      if (!mounted) return;
      setState(() {
        _cashWithdrawalCount = cashCount > 0
            ? cashCount
            : (data['cashWithdrawalCount'] ?? 0) as int;
        _savedUpi = (savedUpi != null && savedUpi.isNotEmpty) ? savedUpi : null;
        _upiController.text = _savedUpi ?? '';
      });
    } catch (e) {
      debugPrint('Wallet metadata error: $e');
    }
  }

  int get _cashMinimum => _cashWithdrawalCount == 0 ? 25 : 50;

  Future<void> _convertCoinsToCash() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final rate = RemoteConfigService.instance.coinRate > 0
        ? RemoteConfigService.instance.coinRate
        : 100;

    final raw = int.tryParse(_coinController.text.trim()) ?? 0;

    if (raw < 100) {
      _showMessage('Minimum 100 coins required to convert.', Colors.amber);
      return;
    }
    if (raw % rate != 0) {
      _showMessage('Coins must be in multiples of ' + rate.toString() + '.', Colors.amber);
      return;
    }
    if (raw > widget.coins) {
      _showMessage('You do not have enough coins.', Colors.redAccent);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cash = raw / rate;
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final currentCoins = (snap.data()?['coins'] as num?)?.toInt() ?? 0;
        if (currentCoins < raw) {
          throw Exception('Insufficient coins.');
        }

        transaction.update(userRef, {
          'coins': currentCoins - raw,
          'taskCash': FieldValue.increment(cash),
          'hasConvertedToday': true,
        });

        transaction.set(transactionRef, {
          'uid': user.uid,
          'category': 'coin',
          'title': 'Coins to Cash',
          'coins': raw,
          'amount': cash,
          'status': 'success',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      _coinController.clear();
      widget.onCoinsConverted();
      _showMessage('Converted ' + raw.toString() + ' coins to ₹' + cash.toStringAsFixed(2) + '.', const Color(0xFF00FF87));
    } catch (e) {
      _showMessage('Conversion failed: ' + e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _requestWithdrawal(bool isCash) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final available = isCash ? widget.taskCash : widget.referCash;
    final minimum = isCash ? _cashMinimum : 50.0;

    if (available < minimum) {
      _showMessage(
        (isCash ? 'Cash withdrawal' : 'Refer withdrawal') +
            ' requires minimum ₹' + minimum.toStringAsFixed(0) + '.',
        Colors.amber,
      );
      return;
    }

    _amountController.text = '';
    _changingUpi = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final hasSavedUpi = _savedUpi != null && _savedUpi!.isNotEmpty;
            final amount = double.tryParse(_amountController.text.trim()) ?? 0;
            final validAmount = amount >= minimum && amount <= available;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCash ? 'Cash Withdrawal' : 'Refer Withdrawal',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Available: ₹' + available.toStringAsFixed(2) +
                          '  •  Minimum: ₹' + minimum.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setSheetState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Withdrawal amount',
                        hintText: 'Enter amount',
                        prefixText: '₹ ',
                        labelStyle: const TextStyle(color: Colors.white60),
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixStyle: const TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (!hasSavedUpi || _changingUpi) ...[
                      TextField(
                        controller: _upiController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setSheetState(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: hasSavedUpi ? 'New UPI ID' : 'Add UPI ID',
                          hintText: 'example@upi',
                          labelStyle: const TextStyle(color: Colors.white60),
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFF00FF87)),
                          filled: true,
                          fillColor: const Color(0xFF080B10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (hasSavedUpi)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _changingUpi = false;
                                _upiController.text = _savedUpi!;
                              });
                            },
                            child: const Text('Keep saved UPI'),
                          ),
                        ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080B10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: Color(0xFF00FF87), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _savedUpi!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  _changingUpi = true;
                                  _upiController.text = _savedUpi!;
                                  _upiController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: _upiController.text.length),
                                  );
                                });
                              },
                              child: const Text('Change UPI'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCash ? const Color(0xFF00FF87) : Colors.purpleAccent,
                          foregroundColor: isCash ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: validAmount && (!_changingUpi ? hasSavedUpi : _upiController.text.trim().contains('@'))
                            ? () async {
                                final upi = _upiController.text.trim();
                                if (!hasSavedUpi || _changingUpi) {
                                  if (!upi.contains('@') || upi.length < 5) {
                                    _showMessage('Please enter a valid UPI ID.', Colors.redAccent);
                                    return;
                                  }
                                }

                                Navigator.pop(sheetContext);
                                await _submitWithdrawal(
                                  isCash: isCash,
                                  amount: amount,
                                  upi: upi,
                                );
                              }
                            : null,
                        child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitWithdrawal({
    required bool isCash,
    required double amount,
    required String upi,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final withdrawalRef = FirebaseFirestore.instance.collection('withdrawals').doc();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final data = snap.data() ?? {};
        final field = isCash ? 'taskCash' : 'referCash';
        final balance = (data[field] as num?)?.toDouble() ?? 0.0;

        if (balance < amount) {
          throw Exception('Balance changed. Please try again.');
        }

        final updates = <String, dynamic>{
          field: balance - amount,
          'upiId': upi,
        };
        if (isCash) {
          updates['cashWithdrawalCount'] = FieldValue.increment(1);
        }

        transaction.update(userRef, updates);
        transaction.set(withdrawalRef, {
          'uid': user.uid,
          'userName': user.displayName ?? 'TPL Player',
          'userEmail': user.email ?? '',
          'upiId': upi,
          'amount': amount,
          'type': isCash ? 'Cash Balance' : 'Referral Balance',
          'status': 'pending',
          'mode': 'manual',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (isCash) {
        setState(() => _cashWithdrawalCount += 1);
      }
      _savedUpi = upi;
      _upiController.text = upi;
      _showMessage('Withdrawal request placed. Status: Pending.', const Color(0xFF00FF87));
    } catch (e) {
      _showMessage('Withdrawal failed: ' + e.toString(), Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _balanceCard({
    required IconData icon,
    required Color color,
    required String title,
    required String amount,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text(amount, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: color == Colors.purpleAccent ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onPressed,
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rate = RemoteConfigService.instance.coinRate > 0
        ? RemoteConfigService.instance.coinRate
        : 100;
    final coinsInRupees = widget.coins / rate;

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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UnityBannerWidget(),
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
                            Text(widget.coins.toString() + ' Coins', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Text('≈ ₹' + coinsInRupees.toStringAsFixed(2), style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '100+ coins can be converted • ' + rate.toString() + ' coins = ₹1',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: widget.coins >= 100 ? () => _showCoinConversionSheet(rate) : null,
                            child: const Text('Convert Coins to Cash', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _balanceCard(
                    icon: Icons.account_balance_wallet,
                    color: const Color(0xFF00FF87),
                    title: 'Cash Balance',
                    amount: '₹' + widget.taskCash.toStringAsFixed(2),
                    subtitle: '1st withdrawal min ₹25 • After that min ₹50',
                    buttonText: 'Withdraw Cash',
                    onPressed: () => _requestWithdrawal(true),
                  ),
                  const SizedBox(height: 16),
                  _balanceCard(
                    icon: Icons.people_alt,
                    color: Colors.purpleAccent,
                    title: 'Referral Balance',
                    amount: '₹' + widget.referCash.toStringAsFixed(2),
                    subtitle: 'Fixed minimum withdrawal: ₹50',
                    buttonText: 'Withdraw Referral Cash',
                    onPressed: () => _requestWithdrawal(false),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Transaction History',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 420,
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111622),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const TransactionHistoryView(),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _showCoinConversionSheet(int rate) async {
    _coinController.text = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111622),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final value = int.tryParse(_coinController.text.trim()) ?? 0;
            final valid = value >= 100 && value <= widget.coins && value % rate == 0;
            final cash = value / rate;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Convert Coins to Cash', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    'Minimum 100 coins • ' + rate.toString() + ' coins = ₹1',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _coinController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setSheetState(() {}),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Coins to convert',
                      hintText: '100, 200, 300...',
                      labelStyle: const TextStyle(color: Colors.white60),
                      hintStyle: const TextStyle(color: Colors.white30),
                      prefixIcon: const Icon(Icons.monetization_on, color: Colors.amber),
                      filled: true,
                      fillColor: const Color(0xFF080B10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value > 0 ? 'You receive: ₹' + cash.toStringAsFixed(2) : 'Enter coins to see cash value',
                    style: TextStyle(
                      color: valid ? const Color(0xFF00FF87) : Colors.white54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: valid
                          ? () async {
                              Navigator.pop(ctx);
                              await _convertCoinsToCash();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Convert Now', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
