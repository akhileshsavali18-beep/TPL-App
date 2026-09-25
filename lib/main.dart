import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Services
import 'services/security_service.dart';
import 'services/ad_service.dart';
import 'services/remote_config_service.dart';
import 'services/app_update_service.dart';

// Screens
import 'screens/splash_login.dart';
import 'screens/home.dart';
import 'screens/tasks.dart';
import 'screens/refer.dart';
import 'screens/wallet.dart';
import 'widgets/profile_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    await RemoteConfigService.instance.init();
    
    // ಅಡ್ಮಿನ್ ಕಂಟ್ರೋಲ್ ಪ್ರಕಾರ ಆಡ್ಸ್ ಇನಿಶಿಯಲೈಸ್ ಮಾಡುವುದು
    await AdService.instance.init();
  } catch (e) {
    debugPrint("Init notice: $e");
  }

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

  bool _isVpnDetected = false;

  @override
  void initState() {
    super.initState();
    _checkVpnStatus();
    _listenToUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) AppUpdateService.instance.checkAndPrompt(context);
      });
    });
  }

  Future<void> _checkVpnStatus() async {
    final isVpn = await SecurityService.instance.isVpnActive();
    if (mounted && isVpn) {
      setState(() => _isVpnDetected = true);
    }
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
        final now = DateTime.now();
        final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final dailyDate = data['dailyBonusDate']?.toString() ?? '';
        final isToday = dailyDate == todayKey;
        setState(() {
          coins = data['coins'] ?? 50;
          taskCash = (data['taskCash'] ?? 0.0).toDouble();
          referCash = (data['referCash'] ?? 0.0).toDouble();
          savedUpiId = data['upiId'];
          spinsLeft = isToday ? (data['spinsLeft'] ?? 0) : 0;
          scratchLeft = isToday ? (data['scratchLeft'] ?? 0) : 0;
          streakClaimedToday = data['streakClaimedToday'] ?? false;
          hasConvertedToday = data['hasConvertedToday'] ?? false;
          hasTaskWithdrawnToday = data['hasTaskWithdrawnToday'] ?? false;
          hasReferWithdrawnToday = data['hasReferWithdrawnToday'] ?? false;
        });
        if (!isToday) {
          FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'dailyBonusDate': todayKey,
            'dailyTaskProgress': 0,
            'spinsLeft': 0,
            'scratchLeft': 0,
          }, SetOptions(merge: true));
        }
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

  Future<void> _completeSocialTask(String name, int reward) async {
    if (currentUid == null) return;
    try {
      await _updateCoinsInFirebase(reward, 'Completed $name');
    } catch (e) {
      debugPrint('Social task completion error: $e');
    }
  }


  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 Maintenance Mode check
    if (RemoteConfigService.instance.maintenanceMode) {
      return const Scaffold(
        backgroundColor: Color(0xFF080B10),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_rounded, size: 80, color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'Under Maintenance',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'The app is currently undergoing scheduled maintenance. Please check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 🛡️ Anti-Cheat VPN check
    if (_isVpnDetected) {
      return const Scaffold(
        backgroundColor: Color(0xFF080B10),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 80, color: Colors.redAccent),
                SizedBox(height: 16),
                Text(
                  'VPN Detected!',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Using VPN or Proxy is strictly prohibited. Please turn off VPN and restart the app.',
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
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenTasks: () => switchTab(1),
      ),
      TasksTabScreen(
        spinsLeft: spinsLeft,
        scratchLeft: scratchLeft,
        onCompleteTask: (name, reward) {
          _completeSocialTask(name, reward);
        },
        onSpinUsed: () {
          if (currentUid != null) {
            FirebaseFirestore.instance.collection('users').doc(currentUid).update({
              'spinsLeft': FieldValue.increment(-1),
            });
          }
        },
        onScratchUsed: () {
          if (currentUid != null) {
            FirebaseFirestore.instance.collection('users').doc(currentUid).update({
              'scratchLeft': FieldValue.increment(-1),
            });
          }
        },
      ),
      ReferScreen(
        referCash: referCash,
        invitedFriends: invitedFriends,
        onNavigateToWallet: () => switchTab(3),
      ),
      WalletScreen(
        coins: coins,
        taskCash: taskCash,
        referCash: referCash,
        cashHistory: cashHistory,
        onCoinsConverted: () {
          setState(() {});
        },
      ),
    ];
    return Scaffold(
      key: _scaffoldKey,
      drawer: ProfileDrawer(
        onWalletTap: () => switchTab(4),
        onReferTap: () => switchTab(3),
      ),
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
            NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group, color: Color(0xFF00FF87)), label: 'Refer'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF00FF87)), label: 'Wallet'),
          ],
        ),
      ),
    );
  }
}
