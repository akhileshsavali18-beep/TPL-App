import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ad_service.dart';

class MiniGamesSection extends StatelessWidget {
  const MiniGamesSection({super.key});

  @override
  Widget build(BuildContext context) {
    // ಅಡ್ಮಿನ್ ಪ್ಯಾನೆಲ್‌ನ 'games' ಕಲೆಕ್ಷನ್‌ಗೆ ನೇರ ಸಿಂಕ್
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('games').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        // isActive: false ಆಗಿಲ್ಲದ ಎಲ್ಲ ಗೇಮ್‌ಗಳನ್ನು ತೋರಿಸುವುದು
        final games = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;
          return data['isActive'] != false;
        }).toList();

        if (games.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const Text(
                    '🎮 Play & Win (Gamezop)',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'No Install',
                      style: TextStyle(color: Color(0xFF00FF87), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final data = games[index].data() as Map<String, dynamic>;
                final title = (data['title'] ?? data['name'] ?? 'Game').toString();
                final coins = int.tryParse(data['coins']?.toString() ?? '') ?? 20;
                // iconUrl ಅಥವಾ icon ಅಥವಾ imageUrl
                final iconUrl = (data['iconUrl'] ?? data['icon'] ?? data['imageUrl'] ?? '').toString();
                // gameUrl ಅಥವಾ url ಅಥವಾ link
                final gameUrl = (data['gameUrl'] ?? data['url'] ?? data['link'] ?? '').toString();

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    if (gameUrl.trim().isNotEmpty) {
                      final uri = Uri.parse(gameUrl.trim());
                      if (await canLaunchUrl(uri)) {
                        await AdService.instance.showInterstitialAd(context: context);
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111622),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.07),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: iconUrl.isNotEmpty
                              ? Image.network(
                                  iconUrl,
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 52,
                                    height: 52,
                                    color: Colors.white10,
                                    child: const Icon(Icons.sports_esports, color: Color(0xFF00FF87), size: 30),
                                  ),
                                )
                              : Container(
                                  width: 52,
                                  height: 52,
                                  color: Colors.white10,
                                  child: const Icon(Icons.sports_esports, color: Color(0xFF00FF87), size: 30),
                                ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Play • Game bonus',
                          style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
