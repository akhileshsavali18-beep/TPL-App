import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isCheckingAuth = true;
  bool _isLoginMode = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  bool _isInviteValid = false;
  bool _isCheckingInvite = false;
  String? _verifiedReferrerUid;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  // 1. Auto-Login Check (Problem 15 Fix)
  Future<void> _checkAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && mounted) {
      // User already logged in -> Direct Home Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      setState(() => _isCheckingAuth = false);
    }
  }

  // 2. Invite Code Verification (Problem 2 Fix)
  Future<void> _verifyInviteCode() async {
    final code = _inviteController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isCheckingInvite = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('referralCode', isEqualTo: code)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        setState(() {
          _isInviteValid = true;
          _verifiedReferrerUid = snap.docs.first.id;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Valid Referral Code! +Bonus applied.'),
              backgroundColor: Color(0xFF00FF87),
            ),
          );
        }
      } else {
        setState(() {
          _isInviteValid = false;
          _verifiedReferrerUid = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid referral code. Please check and try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Invite verify error: $e");
    } finally {
      if (mounted) setState(() => _isCheckingInvite = false);
    }
  }

  // Generate Unique Referral Code for New User
  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    String randomStr = List.generate(5, (index) => chars[rand.nextInt(chars.length)]).join();
    return 'TPL$randomStr';
  }

  // 3. Email & Password Auth Submit (Problem 3 Fix)
  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address!')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // === LOGIN ===
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // === SIGN UP ===
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = cred.user;
        if (user != null) {
          final myReferralCode = _generateReferralCode();

          // Create User Profile in Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': email,
            'displayName': email.split('@')[0],
            'coins': 50, // 50 Welcome bonus coins
            'taskCash': 0.0,
            'referCash': 0.0,
            'spinsLeft': 3,
            'scratchLeft': 2,
            'referralCode': myReferralCode,
            'referredBy': _isInviteValid ? _inviteController.text.trim().toUpperCase() : null,
            'streakClaimedToday': false,
            'hasConvertedToday': false,
            'hasTaskWithdrawnToday': false,
            'hasReferWithdrawnToday': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // If valid referral, give referral bonus to inviter
          if (_isInviteValid && _verifiedReferrerUid != null) {
            await FirebaseFirestore.instance.collection('users').doc(_verifiedReferrerUid).update({
              'referCash': FieldValue.increment(5.0), // ₹5 refer bonus
            });
          }
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Authentication failed';
      if (e.code == 'user-not-found') message = 'No account found with this email.';
      if (e.code == 'wrong-password') message = 'Incorrect password.';
      if (e.code == 'email-already-in-use') message = 'Email already registered. Please Login.';
      if (e.code == 'weak-password') message = 'Password is too weak.';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: const Color(0xFF080B10),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF87).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Image.asset('assets/images/logo.png', errorBuilder: (_, __, ___) {
                  return const Icon(Icons.flash_on, size: 50, color: Color(0xFF00FF87));
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                'TASK PREMIER LEAGUE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF00FF87)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Header Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Color(0xFF00FF87), size: 14),
                    SizedBox(width: 6),
                    Text(
                      '100% Instant UPI Payouts',
                      style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logo & App Name
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF87).withOpacity(0.2),
                      blurRadius: 25,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Image.asset('assets/images/logo.png', errorBuilder: (_, __, ___) {
                  return const Icon(Icons.flash_on, size: 45, color: Color(0xFF00FF87));
                }),
              ),
              const SizedBox(height: 14),
              const Text(
                'Welcome to TPL',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Play Games • Complete Tasks • Withdraw to UPI',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),

              const SizedBox(height: 28),

              // Switch Tab: Login vs Sign Up
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111622),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLoginMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLoginMode ? const Color(0xFF00FF87) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: _isLoginMode ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLoginMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isLoginMode ? const Color(0xFF00FF87) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(
                                color: !_isLoginMode ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Inputs Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111622),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  children: [
                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00FF87), size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 chars)',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00FF87), size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // Invite Code (Only in Sign-Up mode)
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _inviteController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Invite Code (Optional)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                                filled: true,
                                fillColor: const Color(0xFF080B10),
                                prefixIcon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isInviteValid ? const Color(0xFF00FF87) : const Color(0xFF1F293D),
                                foregroundColor: _isInviteValid ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: _isCheckingInvite ? null : _verifyInviteCode,
                              child: _isCheckingInvite
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(
                                      _isInviteValid ? Icons.check : Icons.arrow_forward,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 6,
                        ),
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                _isLoginMode ? 'Login to TPL' : 'Create Account & Claim 50 Coins',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'By signing in, you agree to TPL Terms & Privacy Policy',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
