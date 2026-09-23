import 'unity_banner_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../screens/splash_login.dart';

class SideProfileDrawer extends StatelessWidget {
  const SideProfileDrawer({super.key});

  Future<void> _openSocialLink(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error opening URL: $e");
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? 'No email';
    final String displayName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : (user?.email?.split('@')[0] ?? 'TPL Player');
    final String initialLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    return Drawer(
      backgroundColor: const Color(0xFF0F131C),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFF6C63FF),
                    child: Text(
                      initialLetter,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF87).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Color(0xFF00FF87), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'TPL Verified Player',
                          style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),

            // Social Channels
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF229ED9).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.send_rounded, color: Color(0xFF229ED9), size: 20),
              ),
              title: const Text('Official Telegram Channel', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Get daily redeem codes', style: TextStyle(color: Colors.grey, fontSize: 11)),
              onTap: () => _openSocialLink('https://t.me/your_tpl_channel'),
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1306C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 20),
              ),
              title: const Text('Follow on Instagram', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Contest announcements & proof', style: TextStyle(color: Colors.grey, fontSize: 11)),
              onTap: () => _openSocialLink('https://instagram.com/your_tpl_page'),
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF0000), size: 20),
              ),
              title: const Text('Subscribe YouTube', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Tutorials & tips', style: TextStyle(color: Colors.grey, fontSize: 11)),
              onTap: () => _openSocialLink('https://youtube.com/@your_tpl_channel'),
            ),

            const Spacer(),
            const Divider(color: Colors.white10, height: 1),

            // Logout Button
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
              title: const Text(
                'Logout',
                style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
