import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/splash_login.dart';

class SideProfileDrawer extends StatelessWidget {
  const SideProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String userName = currentUser?.displayName ?? "TPL Player";
    String userEmail = currentUser?.email ?? "user@tplrewards.com";

    return Drawer(
      backgroundColor: const Color(0xFF0F121C),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            color: const Color(0xFF171B26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFF6C63FF),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFF00FF87)),
                      SizedBox(width: 6),
                      Text(
                        'TPL Verified Player',
                        style: TextStyle(fontSize: 11, color: Color(0xFF00FF87), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.send, color: Color(0xFF0088CC)),
            title: const Text('Official Telegram Channel'),
            subtitle: const Text('Get daily redeem codes', style: TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Official Telegram Channel...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFFE1306C)),
            title: const Text('Follow on Instagram'),
            subtitle: const Text('Contest announcements & proof', style: TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening Instagram...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_fill, color: Color(0xFFFF0000)),
            title: const Text('Subscribe YouTube'),
            subtitle: const Text('Tutorials & tips', style: TextStyle(fontSize: 11, color: Colors.grey)),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening YouTube Channel...')),
              );
            },
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              await GoogleSignIn().signOut();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

