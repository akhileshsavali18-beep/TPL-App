import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TasksTabScreen extends StatefulWidget {
  final Function(String taskName, int reward) onCompleteTask;

  const TasksTabScreen({
    super.key,
    required this.onCompleteTask,
  });

  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> {
  // Offerwalls configuration state
  bool _notikEnabled = false;
  String _notikUrl = '';
  bool _earnkaroEnabled = false;
  String _earnkaroUrl = '';

  @override
  void initState() {
    super.initState();
    _fetchOfferwallConfig();
  }

  // Firebase app_config/offerwalls inda settings load maaduvudhu
  void _fetchOfferwallConfig() {
    FirebaseFirestore.instance
        .collection('app_config')
        .doc('offerwalls')
        .snapshots()
        .listen((snap) {
      if (snap.exists && snap.data() != null) {
        final d = snap.data()!;
        if (mounted) {
          setState(() {
            _notikEnabled = d['notikEnabled'] ?? false;
            _notikUrl = d['notikUrl'] ?? '';
            _earnkaroEnabled = d['earnkaroEnabled'] ?? false;
            _earnkaroUrl = d['earnkaroUrl'] ?? '';
          });
        }
      }
    });
  }

  Future<void> _openExternalLink(String url) async {
    if (url.isEmpty) return;
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error opening URL: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tasks & Offerwalls',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= 1. OFFERWALLS SECTION =================
            if (_notikEnabled || _earnkaroEnabled) ...[
              const Text(
                '💼 Premium Offerwalls',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Notik Offerwall Button
                  if (_notikEnabled)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openExternalLink(_notikUrl),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111622),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.3)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.layers_rounded, color: Colors.lightBlueAccent, size: 24),
                              SizedBox(height: 8),
                              Text('Notik Offers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('High Coins', style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_notikEnabled && _earnkaroEnabled) const SizedBox(width: 12),
                  // EarnKaro Deals Button
                  if (_earnkaroEnabled)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openExternalLink(_earnkaroUrl),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111622),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shopping_bag_rounded, color: Colors.amber, size: 24),
                              SizedBox(height: 8),
                              Text('EarnKaro Deals', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Shop & Earn', style: TextStyle(color: Colors.amber, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // ================= 2. SOCIAL TASKS SECTION =================
            const Text(
              '🎯 Social & Daily Tasks',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Live Firestore Tasks Stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFF00FF87)),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111622),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'No tasks available right now. Check back soon!',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                  );
                }

                final tasks = snapshot.data!.docs;

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = tasks[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Task';
                    final coins = data['coins'] ?? 50;
                    final category = data['category'] ?? 'Social';
                    final taskUrl = data['url'] ?? '';

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111622),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF87).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star_rounded, color: Color(0xFF00FF87), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  category,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF87),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              await _openExternalLink(taskUrl);
                              widget.onCompleteTask(title, coins);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('+$coins Coins added for completing $title!'),
                                    backgroundColor: const Color(0xFF111622),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              '+$coins',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

