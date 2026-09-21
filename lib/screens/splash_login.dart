import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) => Transform.scale(
                scale: _glowAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FF87).withOpacity(0.4),
                        blurRadius: 35,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF151922),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FF87), width: 2),
                        ),
                        child: const Center(
                          child: Text('TPL', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF00FF87))),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TASK PREMIER LEAGUE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                '⚡ Next-Gen Rewards Engine',
                style: TextStyle(fontSize: 11, color: Color(0xFF00FF87), letterSpacing: 1),
              ),
            ),
            const Spacer(),
            const Text('DEVELOPED BY', style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            const Text(
              'A28 TECHNOLOGIES',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2.5, color: Colors.white),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _referralController = TextEditingController();
  bool _showReferralField = false;
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        var userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
        var doc = await userRef.get();

        if (!doc.exists) {
          await userRef.set({
            'uid': user.uid,
            'name': user.displayName ?? 'TPL Player',
            'email': user.email ?? '',
            'coins': 50,
            'taskCash': 0.0,
            'referCash': 0.0,
            'appliedReferral': _referralController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: Continuing to Dashboard... ($e)')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 14, color: Color(0xFF00FF87)),
                    SizedBox(width: 6),
                    Text('100% Instant UPI Payouts', style: TextStyle(fontSize: 11, color: Color(0xFF00FF87), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF00FF87).withOpacity(0.3), blurRadius: 25),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(45),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF151922),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF00FF87), width: 1.5),
                      ),
                      child: const Center(
                        child: Text('TPL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text('Welcome to TPL', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('Play Games • Complete Tasks • Withdraw to UPI', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF111520),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  children: [
                    _featureRow(Icons.currency_rupee, 'Low Minimum Payout: Start at just ₹5', const Color(0xFF00FF87)),
                    const SizedBox(height: 14),
                    _featureRow(Icons.auto_awesome, '3 Free Lucky Spins & Scratch Daily', const Color(0xFFFFD700)),
                    const SizedBox(height: 14),
                    _featureRow(Icons.group_add, 'Earn ₹5 Cash on Every Referral', const Color(0xFF6C63FF)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              if (!_showReferralField)
                InkWell(
                  onTap: () => setState(() => _showReferralField = true),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard, size: 16, color: Color(0xFF00FF87)),
                        SizedBox(width: 8),
                        Text('Have an invite code? Tap to apply', style: TextStyle(color: Color(0xFF00FF87), fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: _referralController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'ENTER CODE (E.G. TPL8821)',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle, color: Color(0xFF00FF87), size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite Code Saved!')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata, color: Colors.red, size: 34),
                            SizedBox(width: 6),
                            Text('Continue with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'By signing in, you agree to TPL Terms & Privacy Policy',
                style: TextStyle(fontSize: 10, color: Colors.white38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
      ],
    );
  }
}
