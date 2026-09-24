import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/unity_banner_widget.dart';

class TasksTabScreen extends StatefulWidget {
  final Function(String, int) onCompleteTask;

  const TasksTabScreen({
    super.key,
    required this.onCompleteTask,
  });

  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> {
  final Map<String, bool> _completed = {};

  Future<void> _handleTask(String taskId, String title, int coins, String url) async {
    try {
      if (url.trim().isNotEmpty && await canLaunchUrlString(url)) {
        await launchUrlString(url.trim(), mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (!(_completed[taskId] ?? false)) {
      widget.onCompleteTask(title, coins);
      setState(() => _completed[taskId] = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +$coins Coins claimed for $title!'),
            backgroundColor: const Color(0xFF00FF87),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getBrandColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('telegram')) return const Color(0xFF229ED9);
    if (t.contains('instagram')) return const Color(0xFFE1306C);
    if (t.contains('youtube')) return const Color(0xFFFF0000);
    if (t.contains('earnkaro') || t.contains('shopping') || t.contains('deal')) return Colors.amber;
    return const Color(0xFF00FF87);
  }

  IconData _getBrandIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('telegram')) return Icons.send_rounded;
    if (t.contains('instagram')) return Icons.camera_alt_rounded;
    if (t.contains('youtube')) return Icons.play_arrow_rounded;
    if (t.contains('earnkaro') || t.contains('shopping') || t.contains('deal')) return Icons.shopping_bag;
    return Icons.task_alt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Tasks & Offers', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📺 Top Unity Banner Ad Inside Tasks Tab
            const UnityBannerWidget(),

            const SizedBox(height: 12),

            // 1. Partner Deals Hub (EarnKaro)
            const Text('💼 Partner Deals Hub', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _handleTask('earnkaro_deal', 'EarnKaro Shopping Deals', 10, 'https://earningshub.co/Akhilesh-17901502844466'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag, color: Colors.amber, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EarnKaro Shopping Deals', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Shop & share Flipkart, Myntra deals to earn cashback', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Community & Social Tasks (Firestore Stream)
            const Text('🎯 Community & Social Tasks', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
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
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'No tasks available right now. Check back later!',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }

                final tasks = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isActive'] != false;
                }).toList();

                return ListView.separated(
                  itemCount: tasks.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = tasks[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final taskId = doc.id;
                    final title = (data['title'] ?? 'Complete Task').toString();
                    final subtitle = (data['subtitle'] ?? data['description'] ?? 'Complete this task to earn coins').toString();
                    final coins = int.tryParse(data['coins']?.toString() ?? '') ?? 25;
                    final url = (data['url'] ?? data['link'] ?? '').toString();

                    final brandColor = _getBrandColor(title);
                    final icon = _getBrandIcon(title);
                    final isDone = _completed[taskId] ?? false;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151922),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: brandColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: brandColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: isDone ? null : () => _handleTask(taskId, title, coins, url),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00FF87),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: Colors.white12,
                              disabledForegroundColor: Colors.white38,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              isDone ? 'CLAIMED' : '+$coins',
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
