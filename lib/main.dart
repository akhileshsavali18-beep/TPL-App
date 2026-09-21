import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

// Screens import
import 'screens/splash_login.dart';
import 'screens/home.dart';
import 'screens/tasks.dart';
import 'screens/games.dart';
import 'screens/refer.dart';
import 'screens/wallet.dart';
import 'widgets/profile_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization notice: $e");
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

  // Central app state
  int coins = 12450;
  double taskCash = 100.00;
  double referCash = 15.00;
  String? savedUpiId = "user@upi";

  bool hasConvertedToday = false;
  bool hasTaskWithdrawnToday = false;
  bool hasReferWithdrawnToday = false;
  int spinsLeft = 3;
  int scratchLeft = 2;
  bool streakClaimedToday = false;

  final List<String> coinHistory = [
    '+50 Coins - Welcome Bonus',
    '+20 Coins - Daily Streak Day 1',
  ];
  final List<String> cashHistory = [
    '+₹10.00 - Converted from Coins',
  ];
  final List<String> referHistory = [
    '+₹5.00 - Friend Suresh Joined',
  ];
  final List<Map<String, String>> invitedFriends = [
    {'name': 'Suresh K', 'id': 'TPL#4102', 'reward': '₹5.00', 'status': 'Completed'},
    {'name': 'Ramesh P', 'id': 'TPL#8891', 'reward': '₹5.00', 'status': 'Completed'},
  ];

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        coins: coins,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenWallet: () => switchTab(4),
        streakClaimed: streakClaimedToday,
        onClaimStreak: () {
          setState(() {
            coins += 20;
            streakClaimedToday = true;
            coinHistory.insert(0, '+20 Coins - Daily Streak');
          });
        },
        onTaskClick: (name, reward) => switchTab(1),
      ),
      TasksTabScreen(
        onCompleteTask: (name, reward) {
          setState(() {
            coins += reward;
            coinHistory.insert(0, '+$reward Coins - Completed $name');
          });
        },
      ),
      GamesScreen(
        spinsLeft: spinsLeft,
        scratchLeft: scratchLeft,
        onSpinWin: (winCoins) {
          setState(() {
            spinsLeft--;
            coins += winCoins;
            coinHistory.insert(0, '+$winCoins Coins - Spin Win');
          });
        },
        onScratchWin: (winCoins) {
          setState(() {
            scratchLeft--;
            coins += winCoins;
            coinHistory.insert(0, '+$winCoins Coins - Scratch Card');
          });
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
        onSaveUpi: (newUpi) => setState(() => savedUpiId = newUpi),
        onConvertCoins: (entered) {
          double inRupees = entered / 100.0;
          setState(() {
            coins -= entered;
            taskCash += inRupees;
            hasConvertedToday = true;
            coinHistory.insert(0, '-$entered Coins - Converted to ₹${inRupees.toStringAsFixed(2)}');
            cashHistory.insert(0, '+₹${inRupees.toStringAsFixed(2)} - Converted from Coins');
          });
        },
        onWithdrawTaskCash: (amt) {
          setState(() {
            taskCash -= amt;
            hasTaskWithdrawnToday = true;
            cashHistory.insert(0, '-₹${amt.toStringAsFixed(2)} - UPI Paid');
          });
        },
        onWithdrawReferCash: (amt) {
          setState(() {
            referCash -= amt;
            hasReferWithdrawnToday = true;
            referHistory.insert(0, '-₹${amt.toStringAsFixed(2)} - UPI Paid');
          });
        },
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
