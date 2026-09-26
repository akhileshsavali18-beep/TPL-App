import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionHistoryView extends StatefulWidget {
  const TransactionHistoryView({super.key});

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  StreamSubscription<QuerySnapshot>? _withdrawalsSub;
  StreamSubscription<QuerySnapshot>? _transactionsSub;
  List<_WalletTransaction> _items = [];

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _withdrawalsSub = FirebaseFirestore.instance
        .collection('withdrawals')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((_) => _reload());

    _transactionsSub = FirebaseFirestore.instance
        .collection('transactions')
        .where('uid', isEqualTo: user.uid)
        .snapshots()
        .listen((_) => _reload());

    _reload();
  }

  Future<void> _reload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance
            .collection('withdrawals')
            .where('uid', isEqualTo: user.uid)
            .get(),
        FirebaseFirestore.instance
            .collection('transactions')
            .where('uid', isEqualTo: user.uid)
            .get(),
      ]);

      final items = <_WalletTransaction>[];

      for (final doc in results[0].docs) {
        final data = doc.data();
        final rawType = (data['type'] ?? '').toString().toLowerCase();
        final isRefer = rawType.contains('refer');
        final rawAmount = data['amount'];
        final amount = rawAmount is num ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0;
        items.add(
          _WalletTransaction(
            id: doc.id,
            category: isRefer ? 'refer' : 'cash',
            title: isRefer ? 'Refer Withdrawal' : 'Cash Withdrawal',
            amount: amount,
            coins: null,
            status: _normalizeStatus(data['status']),
            date: _readDate(data['createdAt']),
          ),
        );
      }

      for (final doc in results[1].docs) {
        final data = doc.data();
        final rawCategory = (data['category'] ?? 'coin').toString().toLowerCase();
        final source = (data['source'] ?? '').toString().toLowerCase();
        final category = rawCategory == 'offer' || rawCategory == 'offerwall'
            ? 'offerwall'
            : source == 'social_task' || rawCategory == 'reward'
                ? 'social'
                : source == 'spin' || rawCategory == 'spin'
                    ? 'spin'
                    : source == 'scratch' || rawCategory == 'scratch'
                        ? 'scratch'
                        : rawCategory;
        final rawAmount = data['amount'];
        final amount = rawAmount is num ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0;
        items.add(
          _WalletTransaction(
            id: doc.id,
            category: category == 'coin' ? 'coin' : category,
            title: data['title']?.toString() ?? 'Coins to Cash',
            amount: amount,
            coins: (data['coins'] as num?)?.toInt(),
            status: _normalizeStatus(data['status']),
            date: _readDate(data['createdAt']),
          ),
        );
      }

      items.sort((a, b) => b.date.compareTo(a.date));
      if (mounted) setState(() => _items = items);
    } catch (e) {
      debugPrint('Transaction history error: $e');
    }
  }

  static String _normalizeStatus(dynamic value) {
    final status = (value ?? 'pending').toString().toLowerCase();
    if (status == 'completed' || status == 'success' || status == 'successful') return 'success';
    if (status == 'rejected' || status == 'failed' || status == 'cancelled') return 'failed';
    return 'pending';
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  void dispose() {
    _withdrawalsSub?.cancel();
    _transactionsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF00FF87),
            unselectedLabelColor: Colors.white54,
            indicatorColor: Color(0xFF00FF87),
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Offerwall'),
              Tab(text: 'Social'),
              Tab(text: 'Spin'),
              Tab(text: 'Scratch'),
              Tab(text: 'Coin'),
              Tab(text: 'Cash'),
              Tab(text: 'Refer'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(_items),
                _buildList(_items.where((e) => e.category == 'offerwall').toList()),
                _buildList(_items.where((e) => e.category == 'social').toList()),
                _buildList(_items.where((e) => e.category == 'spin').toList()),
                _buildList(_items.where((e) => e.category == 'scratch').toList()),
                _buildList(_items.where((e) => e.category == 'coin').toList()),
                _buildList(_items.where((e) => e.category == 'cash').toList()),
                _buildList(_items.where((e) => e.category == 'refer').toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<_WalletTransaction> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final item = items[index];
        final icon = item.category == 'coin'
            ? Icons.swap_horiz
            : item.category == 'refer'
                ? Icons.people_alt
                : item.category == 'offerwall'
                    ? Icons.local_offer_rounded
                    : item.category == 'social'
                        ? Icons.groups_rounded
                        : item.category == 'spin'
                            ? Icons.rotate_right_rounded
                            : item.category == 'scratch'
                                ? Icons.confirmation_number_rounded
                                : Icons.account_balance_wallet;
        final iconColor = item.category == 'coin'
            ? Colors.amber
            : item.category == 'refer'
                ? Colors.purpleAccent
                : item.category == 'offerwall'
                    ? Colors.orangeAccent
                    : item.category == 'social'
                        ? Colors.lightBlueAccent
                        : item.category == 'spin'
                            ? const Color(0xFF00FF87)
                            : item.category == 'scratch'
                                ? Colors.amberAccent
                                : const Color(0xFF00FF87);
        final statusColor = item.status == 'success'
            ? const Color(0xFF00FF87)
            : item.status == 'failed'
                ? Colors.redAccent
                : Colors.amber;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            backgroundColor: iconColor.withOpacity(0.12),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: Text(
            _formatDate(item.date) + (item.coins != null ? ' • ' + item.coins.toString() + ' coins' : ''),
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹' + item.amount.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(item.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900)),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Just now';
    final local = date.toLocal();
    return local.day.toString().padLeft(2, '0') + '/' +
        local.month.toString().padLeft(2, '0') + '/' +
        local.year.toString() + ' ' +
        local.hour.toString().padLeft(2, '0') + ':' +
        local.minute.toString().padLeft(2, '0');
  }
}

class _WalletTransaction {
  final String id;
  final String category;
  final String title;
  final double amount;
  final int? coins;
  final String status;
  final DateTime date;

  const _WalletTransaction({
    required this.id,
    required this.category,
    required this.title,
    required this.amount,
    required this.coins,
    required this.status,
    required this.date,
  });
}
