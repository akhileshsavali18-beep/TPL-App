import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';


class ReferScreen extends StatelessWidget {
  final double referCash;
  final List<Map<String, String>> invitedFriends;
  final VoidCallback onNavigateToWallet;

  const ReferScreen({
    super.key,
    required this.referCash,
    required this.invitedFriends,
    required this.onNavigateToWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        title: const Text(
          'Refer & Earn Cash',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Referral Cash Balance Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E283D), Color(0xFF121724)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.35)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Referral Cash',
                        style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${referCash.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00FF87),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${invitedFriends.length} Friends Joined',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onNavigateToWallet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF87),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Invite Code Box & Share Actions
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Your Unique Referral Code',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6C63FF), width: 1.5),
                    ),
                    child: const Text(
                      'TPL8821',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        shareReferralLink("TPL0821");
                      },
                      
                      icon: const Icon(Icons.share, color: Colors.white, size: 20),
                      label: const Text(
                        'INVITE FRIENDS (EARN ₹5 EACH)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Invited Friends List Header
            const Row(
              children: [
                Icon(Icons.people, color: Color(0xFF00FF87), size: 20),
                SizedBox(width: 8),
                Text('Invited Friends History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // Friends List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invitedFriends.length,
              itemBuilder: (context, index) {
                final friend = invitedFriends[index];
                bool isDone = friend['status'] == 'Completed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDone ? const Color(0xFF00FF87).withOpacity(0.15) : Colors.white12,
                            child: Icon(
                              isDone ? Icons.check : Icons.hourglass_top,
                              color: isDone ? const Color(0xFF00FF87) : Colors.grey,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(friend['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                '${friend['id']!} • ${friend['status']!}',
                                style: TextStyle(fontSize: 11, color: isDone ? Colors.grey : Colors.amber),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        friend['reward']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: isDone ? const Color(0xFF00FF87) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
Future<void> shareReferralLink(String userReferCode) async {
  try {
    DocumentSnapshot configSnap = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('referral')
        .get();

    bool isGplinksEnabled = true;
    String apiKey = "6fbb840dff7b4f2e4239b3200e0d62fce9b5fbab";
    String appUrl = "https://tplpro.in";
    String baseMessage = "Earn daily cash by playing games on TPL Pro! Download now:";

    if (configSnap.exists) {
      final data = configSnap.data() as Map<String, dynamic>;
      isGplinksEnabled = data['gplinksEnabled'] ?? isGplinksEnabled;
      apiKey = data['gplinksApiKey'] ?? apiKey;
      appUrl = data['appDownloadUrl'] ?? appUrl;
      baseMessage = data['shareMessage'] ?? baseMessage;
    }

    String finalShareUrl = "$appUrl?ref=$userReferCode";

    if (isGplinksEnabled && apiKey.isNotEmpty) {
      try {
        final gplinksApiUrl = Uri.parse(
          'https://api.gplinks.com/st?api=$apiKey&url=${Uri.encodeComponent(finalShareUrl)}',
        );

        final response = await http.get(gplinksApiUrl).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          if (resData['status'] == 'success' && resData['shortenedUrl'] != null) {
            finalShareUrl = resData['shortenedUrl'];
          }
        }
      } catch (e) {
        // Fallback to direct URL
      }
    }

    await Share.share(
      "$baseMessage\n$finalShareUrl\nUse my Referral Code: $userReferCode",
      subject: "Download TPL Pro",
    );
  } catch (e) {
    // Error handling
  }
}

