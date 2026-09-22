import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  bool _isAutoMode = false;
  bool _loadingToggle = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('withdrawal_settings')
        .get();
    if (doc.exists) {
      setState(() {
        _isAutoMode = doc.data()?['cashfree_auto'] ?? false;
        _loadingToggle = false;
      });
    } else {
      setState(() => _loadingToggle = false);
    }
  }

  void _toggleMode(bool value) async {
    setState(() => _isAutoMode = value);
    await FirebaseFirestore.instance
        .collection('app_config')
        .doc('withdrawal_settings')
        .set({'cashfree_auto': value}, SetOptions(merge: true));
  }

  // 🚀 Open UPI App via Intent
  Future<void> _payViaUpi(String upiId, double amount, String requestId) async {
    final cleanUpi = upiId.trim();
    final formattedAmount = amount.toStringAsFixed(2);
    final note = 'TPL APP WITHDRAW $requestId';

    // UPI Standard URI Intent Scheme
    final upiUrl = 'upi://pay?pa=$cleanUpi&pn=TPL%20App&am=$formattedAmount&tn=${Uri.encodeComponent(note)}&cu=INR';

    try {
      if (await canLaunchUrlString(upiUrl)) {
        await launchUrlString(upiUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No UPI App found on this device!')),
          );
        }
      }
    } catch (e) {
      debugPrint("UPI Launch Error: $e");
    }
  }

  Future<void> _markCompleted(String requestId) async {
    await FirebaseFirestore.instance
        .collection('withdrawals')
        .doc(requestId)
        .update({
      'status': 'completed',
      'paidAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as Completed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Admin Withdrawal Panel', style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
      body: Column(
        children: [
          // 1. Toggle Header Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF151922),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cashfree Auto Payout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      _isAutoMode ? 'Mode: Automatic API' : 'Mode: Manual UPI Payment',
                      style: TextStyle(color: _isAutoMode ? const Color(0xFF00FF87) : Colors.amber, fontSize: 11),
                    ),
                  ],
                ),
                _loadingToggle
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: _isAutoMode,
                        activeColor: const Color(0xFF00FF87),
                        onChanged: _toggleMode,
                      ),
              ],
            ),
          ),

          // 2. Pending Requests List Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Pending Requests', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
          ),

          // 3. Stream of Pending Requests
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('withdrawals')
                  .where('status', isEqualTo: 'pending')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No pending withdrawals! 🎉', style: TextStyle(color: Colors.white38)),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final reqId = data['requestId'] ?? docs[index].id;
                    final upi = data['upiId'] ?? 'N/A';
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                    final coins = data['coins'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151922),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFF00FF87), fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text('$coins Coins', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.account_circle, size: 14, color: Colors.white54),
                              const SizedBox(width: 4),
                              SelectableText(upi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // PAY Button (Direct UPI App launch)
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00FF87),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.payment, size: 16),
                                  label: const Text('PAY', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () => _payViaUpi(upi, amount, reqId),
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Complete Button
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(color: Colors.white24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Mark Paid', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _markCompleted(reqId),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

