import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/unity_banner_widget.dart';
import 'cpalead_offerwall.dart';

class TasksTabScreen extends StatefulWidget {
  final Function(String, int) onCompleteTask;
  const TasksTabScreen({super.key, required this.onCompleteTask});
  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> {
  final Map<String, bool> _completed = {};

  Future<void> _handleTask(String taskId, String title, int coins, String url) async {
    try {
      if (url.trim().isNotEmpty && await canLaunchUrlString(url)) await launchUrlString(url.trim(), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!(_completed[taskId] ?? false)) {
      widget.onCompleteTask(title, coins);
      setState(() => _completed[taskId] = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎉 +' + coins.toString() + ' Coins added for ' + title), backgroundColor: const Color(0xFF00FF87), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(backgroundColor: const Color(0xFF080B10), elevation: 0, title: const Text('Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const UnityBannerWidget(),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF10251D), Color(0xFF111622)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.22))),
            child: Row(children: [
              const Icon(Icons.local_offer_rounded, color: Color(0xFF00FF87), size: 30),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Offer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                SizedBox(height: 3),
                Text('CPAlead app installs, surveys and other offers.', style: TextStyle(color: Colors.white54, fontSize: 10)),
              ])),
              ElevatedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CpaleadOfferwallScreen())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), child: const Text('OPEN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10))),
            ]),
          ),
          const SizedBox(height: 22),
          const Text('🎯 Social Tasks', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF00FF87))));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _empty('No social tasks available right now.');
              final tasks = snapshot.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false).toList();
              if (tasks.isEmpty) return _empty('No social tasks available right now.');
              return ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: tasks.length, separatorBuilder: (_, __) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final doc = tasks[index]; final data = doc.data() as Map<String, dynamic>;
                  final title = data['title']?.toString() ?? 'Social Task';
                  final subtitle = (data['subtitle'] ?? data['description'] ?? 'Complete this task to earn coins').toString();
                  final coins = (data['coins'] as num?)?.toInt() ?? 25;
                  final url = (data['url'] ?? data['link'] ?? '').toString();
                  final done = _completed[doc.id] == true;
                  return Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                    child: Row(children: [
                      const Icon(Icons.task_alt_rounded, color: Color(0xFF00FF87)), const SizedBox(width: 11),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Colors.white45, fontSize: 10)),
                      ])),
                      ElevatedButton(onPressed: done ? null : () => _handleTask(doc.id, title, coins, url), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black, disabledBackgroundColor: Colors.white10, disabledForegroundColor: Colors.white30, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8)), child: Text(done ? 'DONE' : '+' + coins.toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11))),
                    ]),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: const Row(children: [Icon(Icons.auto_awesome, color: Colors.amber), SizedBox(width: 10), Expanded(child: Text('Future earning activities can be added here by Admin without changing the app.', style: TextStyle(color: Colors.white60, fontSize: 11)))]),
          ),
        ]),
      ),
    );
  }

  Widget _empty(String text) => Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(15)), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 12)));
}
