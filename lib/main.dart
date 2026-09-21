import 'services/ad_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

// Screens import
import 'screens/splash_login.dart';
import 'screens/home.dart';
import 'screens/tasks.dart';
import 'screens/games.dart';
import 'screens/refer.dart';
import 'screens/wallet.dart';
import 'services/remote_config_service.dart';
import 'widgets/profile_drawer.dart';

//  ಹೊಸದಾಗಿ ಬದಲಾಯಿಸಬೇಕಾದ ಕೋಡ್:
    try {
      await Firebase.initializeApp();
      // ಅಡ್ಮಿನ್ ಕಂಟ್ರೋಲ್ಸ್ ಲೈವ್ ಲೋಡ್ ಮಾಡುವುದು
      await RemoteConfigService.instance.init();
    } catch (e) {
      debugPrint("Firebase initialization notice: $e");
    }


  // Initialize Unity Ads
  UnityAds.init(
    gameId: '600377042', // Nimma Unity Game ID
    testMode: true,      // Testing complete aada mele false madabahudu
    onComplete: () => debugPrint('Unity Ads Initialization Complete'),
    onFailed: (error, message) => debugPrint('Unity Ads Init Failed: $error $message'),
  );

  runApp(const TPLApp());
}

class TPLApp extends StatelessWidget {
  const TPLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPL',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: const Color(0xFF00FF87),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF87),
          secondary: Color(0xFF6C63FF),
          surface: Color(0xFF151922),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  // Firebase state
  StreamSubscription<DocumentSnapshot>? _userSub;
  String? currentUid;

  int coins = 0;
  double taskCash = 0.00;
  double referCash = 0.00;
  String? savedUpiId;

  bool hasConvertedToday = false;
  bool hasTaskWithdrawnToday = false;
  bool hasReferWithdrawnToday = false;
  int spinsLeft = 3;
  int scratchLeft = 2;
  bool streakClaimedToday = false;

  final List<String> coinHistory = [];
  final List<String> cashHistory = [];
  final List<String> referHistory = [];
  final List<Map<String, String>> invitedFriends = [];

  @override
  void initState() {
    super.initState();
    _listenToUserData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  void _listenToUserData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    currentUid = user.uid;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          coins = data['coins'] ?? 50;
          taskCash = (data['taskCash'] ?? 0.0).toDouble();
          referCash = (data['referCash'] ?? 0.0).toDouble();
          savedUpiId = data['upiId'];
          spinsLeft = data['spinsLeft'] ?? 3;
          scratchLeft = data['scratchLeft'] ?? 2;
          streakClaimedToday = data['streakClaimedToday'] ?? false;
          hasConvertedToday = data['hasConvertedToday'] ?? false;
          hasTaskWithdrawnToday = data['hasTaskWithdrawnToday'] ?? false;
          hasReferWithdrawnToday = data['hasReferWithdrawnToday'] ?? false;
        });
      }
    });
  }

  Future<void> _updateCoinsInFirebase(int addCoins, String reason) async {
    if (currentUid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
        'coins': FieldValue.increment(addCoins),
      });
      setState(() {
        coinHistory.insert(0, '+$addCoins Coins - $reason');
      });
    } catch (e) {
      debugPrint("Error updating coins: $e");
    }
  }

  Future<void> _saveUpiToFirebase(String newUpi) async {
    if (currentUid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
        'upiId': newUpi,
      });
      setState(() => savedUpiId = newUpi);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UPI ID successfully saved!')),
        );
      }
    } catch (e) {
      debugPrint("Error saving UPI: $e");
    }
  }

  Future<void> _convertCoinsInFirebase(int coinsEntered) async {
    if (currentUid == null) return;
    double rupeesToAdd = coinsEntered / 100.0;
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
        'coins': FieldValue.increment(-coinsEntered),
        'taskCash': FieldValue.increment(rupeesToAdd),
        'hasConvertedToday': true,
      });
      setState(() {
        coinHistory.insert(0, '-$coinsEntered Coins - Converted to ₹${rupeesToAdd.toStringAsFixed(2)}');
        cashHistory.insert(0, '+₹${rupeesToAdd.toStringAsFixed(2)} - Converted from Coins');
      });
    } catch (e) {
      debugPrint("Error converting coins: $e");
    }
  }

  Future<void> _submitWithdrawalRequest(double amount, {required bool isTask}) async {
    if (currentUid == null || savedUpiId == null) return;
    User? user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
        isTask ? 'taskCash' : 'referCash': FieldValue.increment(-amount),
        isTask ? 'hasTaskWithdrawnToday' : 'hasReferWithdrawnToday': true,
      });

      await FirebaseFirestore.instance.collection('withdrawals').add({
        'uid': currentUid,
        'userName': user?.displayName ?? 'TPL Player',
        'userEmail': user?.email ?? '',
        'upiId': savedUpiId,
        'amount': amount,
        'type': isTask ? 'Task Cash' : 'Referral Cash',
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        if (isTask) {
          cashHistory.insert(0, '-₹${amount.toStringAsFixed(2)} - UPI Pending');
        } else {
          referHistory.insert(0, '-₹${amount.toStringAsFixed(2)} - UPI Pending');
        }
      });
    } catch (e) {
      debugPrint("Error creating withdrawal: $e");
    }
  }

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
       // 🔒 ಅಡ್ಮಿನ್ ಪ್ಯಾನೆಲ್‌ನಲ್ಲಿ Maintenance Mode ಆನ್ ಇದ್ದರೆ ಆ್ಯಪ್ ಬ್ಲಾಕ್ ಆಗುತ್ತದೆ
    if (RemoteConfigService.instance.maintenanceMode) {
      return const Scaffold(
        backgroundColor: Color(0xFF080B10),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined, size: 80, color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'Under Maintenance',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'We are upgrading our servers. Please check back shortly!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final screens = [
      HomeScreen(
        coins: coins,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenWallet: () => switchTab(4),
        streakClaimed: streakClaimedToday,
        onClaimStreak: () {
          if (!streakClaimedToday && currentUid != null) {
            FirebaseFirestore.instance.collection('users').doc(currentUid).update({
              'streakClaimedToday': true,
            });
            _updateCoinsInFirebase(20, 'Daily Streak Day 1');
          }
        },
        onTaskClick: (name, reward) => switchTab(1),
      ),
      TasksTabScreen(
        onCompleteTask: (name, reward) {
          _updateCoinsInFirebase(reward, 'Completed $name');
        },
      ),
      GamesScreen(
        spinsLeft: spinsLeft,
        scratchLeft: scratchLeft,
        onSpinWin: (winCoins) {
          if (currentUid != null) {
            FirebaseFirestore.instance.collection('users').doc(currentUid).update({
              'spinsLeft': FieldValue.increment(-1),
            });
            _updateCoinsInFirebase(winCoins, 'Lucky Spin');
          }
        },
        onScratchWin: (winCoins) {
          if (currentUid != null) {
            FirebaseFirestore.instance.collection('users').doc(currentUid).update({
              'scratchLeft': FieldValue.increment(-1),
            });
            _updateCoinsInFirebase(winCoins, 'Golden Scratch');
          }
        },
      ),
      ReferScreen(
        referCash: referCash,
        invitedFriends: invitedFriends,
        onNavigateToWallet: () => switchTab(4),
      ),
      WalletScreen(
        coins: coins,
        taskCash: taskCash,
        referCash: referCash,
        savedUpiId: savedUpiId,
        hasConvertedToday: hasConvertedToday,
        hasTaskWithdrawnToday: hasTaskWithdrawnToday,
        hasReferWithdrawnToday: hasReferWithdrawnToday,
        coinHistory: coinHistory,
        cashHistory: cashHistory,
        referHistory: referHistory,
        onSaveUpi: _saveUpiToFirebase,
        onConvertCoins: _convertCoinsInFirebase,
        onWithdrawTaskCash: (amt) => _submitWithdrawalRequest(amt, isTask: true),
        onWithdrawReferCash: (amt) => _submitWithdrawalRequest(amt, isTask: false),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideProfileDrawer(),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E2235), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF121620),
          indicatorColor: const Color(0xFF00FF87).withOpacity(0.18),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Color(0xFF00FF87)), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment, color: Color(0xFF00FF87)), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports, color: Color(0xFF00FF87)), label: 'Games'),
            NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group, color: Color(0xFF00FF87)), label: 'Refer'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF00FF87)), label: 'Wallet'),
          ],
        ),
      ),
    );
  }
}
