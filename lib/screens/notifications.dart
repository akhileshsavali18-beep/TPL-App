import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B10),
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        actions: [
          if (user != null)
            TextButton(
              onPressed: () async {
                final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').where('read', isEqualTo: false).get();
                final batch = FirebaseFirestore.instance.batch();
                for (final doc in snap.docs) { batch.update(doc.reference, {'read': true}); }
                await batch.commit();
              },
              child: const Text('Read all'),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please sign in again.', style: TextStyle(color: Colors.white54)))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').orderBy('createdAt', descending: true).limit(100).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Unable to load notifications.', style: TextStyle(color: Colors.white54)));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00FF87)));
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No notifications yet.', style: TextStyle(color: Colors.white54)));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final unread = data['read'] != true;
                    final ts = data['createdAt'];
                    final date = ts is Timestamp ? ts.toDate() : null;
                    final dateText = date == null ? '' : date.day.toString().padLeft(2, '0') + '/' + date.month.toString().padLeft(2, '0') + '/' + date.year.toString() + ' ' + date.hour.toString().padLeft(2, '0') + ':' + date.minute.toString().padLeft(2, '0');
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => doc.reference.update({'read': true}),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: unread ? const Color(0xFF111D1A) : const Color(0xFF111622), borderRadius: BorderRadius.circular(16), border: Border.all(color: unread ? const Color(0xFF00FF87).withOpacity(0.22) : Colors.white10)),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(unread ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: unread ? const Color(0xFF00FF87) : Colors.white38),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(data['title']?.toString() ?? 'TPL Notice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(data['message']?.toString() ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35)),
                              if (date != null) ...[const SizedBox(height: 7), Text(dateText, style: const TextStyle(color: Colors.white38, fontSize: 10))],
                            ])),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class NotificationBellButton extends StatelessWidget {
  final VoidCallback onTap;
  const NotificationBellButton({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return IconButton(onPressed: onTap, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications').where('read', isEqualTo: false).limit(1).snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Stack(clipBehavior: Clip.none, children: [
          IconButton(onPressed: onTap, icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24)),
          if (unread) Positioned(right: 9, top: 8, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
        ]);
      },
    );
  }
}
