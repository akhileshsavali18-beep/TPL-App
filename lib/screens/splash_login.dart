import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _inviteController = TextEditingController();

  bool _isInviteValid = false;
  bool _isCheckingInvite = false;
  String? _verifiedReferrerUid;

  @override
  void initState() {
    super.initState();
    _prefillReferralFromClipboard();
    _checkAutoLogin();
  }

  Future<void> _prefillReferralFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final raw = data?.text?.trim() ?? '';
      if (!mounted || raw.isEmpty) return;
      String code = raw.toUpperCase();
      final uri = Uri.tryParse(raw);
      final refParam = uri?.queryParameters['ref'];
      if (refParam != null && refParam.trim().isNotEmpty) {
        code = refParam.trim().toUpperCase();
      }
      final match = RegExp(r'TPL[A-Z0-9]{5,}').firstMatch(code);
      if (match == null) return;
      _inviteController.text = match.group(0)!;
      if (mounted) setState(() => _isLoginMode = false);
      await _verifyInviteCode();
    } catch (e) {
      debugPrint('Referral prefill error: $e');
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      setState(() => _isCheckingAuth = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address first to reset password.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent. Check your email.'),
            backgroundColor: Color(0xFF00FF87),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Could not send reset link.';
      if (e.code == 'user-not-found') message = 'No account found with this email.';
      if (e.code == 'invalid-email') message = 'Please enter a valid email address.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _verifyInviteCode() async {
    final code = _inviteController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isCheckingInvite = true);
    try {
      final valid = await SecurityApi.instance.validateReferralCode(code);
      setState(() {
        _isInviteValid = valid;
        _verifiedReferrerUid = valid ? 'server' : null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(valid
                ? '🎉 Valid Code! ₹5 bonus unlocks after 2 qualified tasks.'
                : 'Invalid referral code. Please check.'),
            backgroundColor: valid ? const Color(0xFF00FF87) : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Referral check failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingInvite = false);
    }
  }


  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    String randomStr = List.generate(5, (index) => chars[rand.nextInt(chars.length)]).join();
    return 'TPL$randomStr';
  }

  Future<void> _handleSubmit() async {
    final username = _usernameController.text.trim();
    final loginIdentifier = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isLoginMode &&
        (username.length < 3 ||
            username.length > 20 ||
            !RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be 3–20 characters (letters, numbers, underscore).')),
      );
      return;
    }

    if (_isLoginMode) {
      if (loginIdentifier.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your email or username.')),
        );
        return;
      }
    } else if (loginIdentifier.isEmpty || !loginIdentifier.contains('@')) {
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
        String emailForLogin = loginIdentifier;
        if (!loginIdentifier.contains('@')) {
          emailForLogin = await SecurityApi.instance.resolveUsername(loginIdentifier);
          if (emailForLogin.isEmpty) {
            throw FirebaseAuthException(code: 'user-not-found');
          }
        }

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailForLogin,
          password: password,
        );
      } else {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: loginIdentifier,
          password: password,
        );

        final user = cred.user;
        if (user != null) {
          final referralCode =
              _isInviteValid ? _inviteController.text.trim().toUpperCase() : null;
          try {
            await SecurityApi.instance.initializeUser(
              username: username,
              email: loginIdentifier,
              referralCode: referralCode,
            );
          } on FirebaseFunctionsException catch (e) {
            // Account was created in Firebase Auth; sign out if secure
            // server-side profile initialization fails so no half-created
            // reward account can continue.
            await FirebaseAuth.instance.signOut();
            throw FirebaseAuthException(
              code: e.code,
              message: e.message,
            );
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
      if (e.code == 'user-not-found') message = 'No account found with this email or username.';
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
      return const Scaffold(
        backgroundColor: Color(0xFF080B10),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00FF87), strokeWidth: 2.5),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                      '100% Instant UPI Payouts',
                      style: TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('TPL Pro', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                'Play Games • Complete Tasks • Withdraw Cash',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
              const SizedBox(height: 28),

              // Switch Mode
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111622),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
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
                              'Sign Up',
                              style: TextStyle(
                                color: !_isLoginMode ? Colors.black : Colors.white70,
                                fontWeight: FontWeight.w900,
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
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    if (!_isLoginMode) ...[
                      TextField(
                        controller: _usernameController,
                        textCapitalization: TextCapitalization.none,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                          filled: true,
                          fillColor: const Color(0xFF080B10),
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00FF87), size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _emailController,
                      keyboardType: _isLoginMode ? TextInputType.text : TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isLoginMode ? 'Email or Username' : 'Email Address',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00FF87), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Password (min 6 characters)',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: const Color(0xFF080B10),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00FF87), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Color(0xFF00FF87), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

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
                                hintText: 'Invite Code (Get ₹5 Bonus)',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                filled: true,
                                fillColor: const Color(0xFF080B10),
                                prefixIcon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Icon(_isInviteValid ? Icons.check : Icons.arrow_forward, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : _handleSubmit,
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : Text(
                                _isLoginMode ? 'Login to TPL' : 'Create Account',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
