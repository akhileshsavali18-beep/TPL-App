import 'package:flutter/material.dart';

void main() {
  runApp(const TPLApp());
}

class TPLApp extends StatelessWidget {
  const TPLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TPL - Task Premier League',
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

// ----------------------------------------------------
// 1. SPLASH SCREEN (Flow Router)
// ----------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Firebase ಜೋಡಿಸುವವರೆಗೆ ಮೊದಲ ಬಾರಿ ಲಾಗಿನ್ ಸ್ಕ್ರೀನ್ ಬರಲು false ಇಡಲಾಗಿದೆ
  final bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (isLoggedIn) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2235),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF00FF87), width: 2),
                  ),
                  child: const Icon(Icons.bolt, size: 65, color: Color(0xFF00FF87)),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'Powered by',
              style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            const Text(
              'A28 TECHNOLOGIES',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 2. FIRST-TIME LOGIN & WELCOME SCREEN
// ----------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _referralController = TextEditingController();
  bool _hasReferralCode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2235),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF87), width: 1.5),
                    ),
                    child: const Icon(Icons.bolt, size: 40, color: Color(0xFF00FF87)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'TASK PREMIER LEAGUE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Play Tasks • Spin Wheels • Earn Real UPI Cash',
                style: TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Feature Highlights Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _highlightRow(Icons.bolt, 'Instant UPI Withdrawal from ₹5', const Color(0xFF00FF87)),
                    const SizedBox(height: 12),
                    _highlightRow(Icons.sports_esports, '3 Daily Free Spins & Scratch Cards', const Color(0xFFFFD700)),
                    const SizedBox(height: 12),
                    _highlightRow(Icons.group, 'Invite Friends & Earn ₹5 per Referral', const Color(0xFF6C63FF)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Referral Code Toggle / Box
              if (!_hasReferralCode)
                TextButton.icon(
                  onPressed: () => setState(() => _hasReferralCode = true),
                  icon: const Icon(Icons.card_giftcard, size: 18, color: Color(0xFF00FF87)),
                  label: const Text('Have a Referral Code? Enter to get bonus', style: TextStyle(color: Color(0xFF00FF87), fontSize: 13)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6C63FF)),
                  ),
                  child: TextField(
                    controller: _referralController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter Invite Code (e.g. TPL8821)',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _hasReferralCode = false),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Firebase login will be linked here
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'By signing in, you agree to our Terms & Privacy Policy',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _highlightRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
      ],
    );
  }
}

// ----------------------------------------------------
// 3. MAIN NAVIGATION CONTAINER (Tabs)
// ----------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  int coins = 12450;
  double taskCash = 100.00;
  double referCash = 15.00;
  int taskWithdrawCount = 0;
  int referWithdrawCount = 0;
  int totalInvitedFriends = 3;

  bool hasConvertedToday = false;
  bool hasTaskWithdrawnToday = false;
  bool hasReferWithdrawnToday = false;

  int spinsLeft = 3;
  int scratchLeft = 2;

  final List<String> coinHistory = [
    '+50 Coins - Daily Streak Day 1',
    '+25 Coins - Spin & Win Reward',
    '+1200 Coins - Monlix App Offer',
    '-1000 Coins - Converted to ₹10 Cash',
  ];

  final List<String> cashHistory = [
    '+₹10.00 - Converted from 1000 Coins',
    '-₹5.00 - UPI Paid to 98****32@paytm',
  ];

  final List<String> referHistory = [
    '+₹5.00 - Friend Suresh Joined',
    '+₹5.00 - Friend Ramesh Joined',
    '+₹5.00 - Friend Praveen Joined',
  ];

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        coins: coins,
        onClaimStreak: (amount) {
          setState(() {
            coins += amount;
            coinHistory.insert(0, '+$amount Coins - Daily Streak Claimed');
          });
        },
        onOpenWallet: () => switchTab(3),
      ),
      GamesScreen(
        spinsLeft: spinsLeft,
        scratchLeft: scratchLeft,
        onSpinWin: (winCoins) {
          setState(() {
            spinsLeft--;
            coins += winCoins;
            coinHistory.insert(0, '+$winCoins Coins - Spin & Win');
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
        invitedCount: totalInvitedFriends,
        onNavigateToWallet: () => switchTab(3),
      ),
      WalletScreen(
        coins: coins,
        taskCash: taskCash,
        referCash: referCash,
        taskWithdrawCount: taskWithdrawCount,
        referWithdrawCount: referWithdrawCount,
        totalInvited: totalInvitedFriends,
        hasConvertedToday: hasConvertedToday,
        hasTaskWithdrawnToday: hasTaskWithdrawnToday,
        hasReferWithdrawnToday: hasReferWithdrawnToday,
        coinHistory: coinHistory,
        cashHistory: cashHistory,
        referHistory: referHistory,
        onConvert: (int enteredCoins) {
          double convertedRupees = enteredCoins / 100.0;
          setState(() {
            coins -= enteredCoins;
            taskCash += convertedRupees;
            hasConvertedToday = true;
            coinHistory.insert(0, '-$enteredCoins Coins - Converted to Cash');
            cashHistory.insert(0, '+₹${convertedRupees.toStringAsFixed(2)} - Converted from Coins');
          });
        },
        onTaskWithdraw: (double amount) {
          setState(() {
            taskCash -= amount;
            taskWithdrawCount++;
            hasTaskWithdrawnToday = true;
            cashHistory.insert(0, '-₹${amount.toStringAsFixed(2)} - Task Cash Withdrawn');
          });
        },
        onReferWithdraw: (double amount) {
          setState(() {
            referCash -= amount;
            referWithdrawCount++;
            hasReferWithdrawnToday = true;
            referHistory.insert(0, '-₹${amount.toStringAsFixed(2)} - Referral Cash Withdrawn');
          });
        },
      ),
    ];

    return Scaffold(
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
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00FF87)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined),
              selectedIcon: Icon(Icons.sports_esports, color: Color(0xFF00FF87)),
              label: 'Games',
            ),
            NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group, color: Color(0xFF00FF87)),
              label: 'Refer',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet, color: Color(0xFF00FF87)),
              label: 'Wallet',
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 4. SIDE PROFILE DRAWER (With Working Logout to Test)
// ----------------------------------------------------
class SideProfileDrawer extends StatelessWidget {
  const SideProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Akhilesh Savale',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'akhilesh@gmail.com',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0E14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('TPL ID: #88219', style: TextStyle(fontSize: 12, color: Color(0xFF00FF87))),
                      SizedBox(width: 8),
                      Icon(Icons.copy, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: Colors.white70),
            title: const Text('Account Verification'),
            subtitle: const Text('Verified Member', style: TextStyle(fontSize: 12, color: Color(0xFF00FF87))),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.telegram, color: Color(0xFF29B6F6)),
            title: const Text('Telegram Support Bot'),
            subtitle: const Text('Get instant help & proofs', style: TextStyle(fontSize: 12)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
            title: const Text('WhatsApp Helpline'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.white70),
            title: const Text('How to Earn (Guide)'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white70),
            title: const Text('Privacy Policy'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'TPL v1.0.0 • Powered by A28 Technologies',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 5. HOME SCREEN
// ----------------------------------------------------
class HomeScreen extends StatelessWidget {
  final int coins;
  final Function(int) onClaimStreak;
  final VoidCallback onOpenWallet;

  const HomeScreen({
    super.key,
    required this.coins,
    required this.onClaimStreak,
    required this.onOpenWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFF1E2235),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'TPL PREMIER',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 18),
        ),
        actions: [
          GestureDetector(
            onTap: onOpenWallet,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 6),
                  Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Payout Ticker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, color: Color(0xFF00FF87), size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Live: User 98****12 just withdrew ₹50 via UPI • Instant',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 7-Day Login Streak Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF261C52), Color(0xFF16192E)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🔥 7-Day Login Streak',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('Day 1 Active', style: TextStyle(color: Color(0xFF00FF87), fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(7, (index) {
                        int dayNumber = index + 1;
                        int reward = dayNumber == 7 ? 250 : (dayNumber * 10);
                        bool isCurrent = dayNumber == 1;

                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF00FF87).withOpacity(0.2) : const Color(0xFF121522),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCurrent ? const Color(0xFF00FF87) : Colors.white12,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text('Day $dayNumber', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 6),
                              const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                              const SizedBox(height: 4),
                              Text('+$reward', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        onClaimStreak(10);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Day 1: +10 Coins Added!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('CLAIM TODAY (10 COINS)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Offerwall Cards
            const Text('Super Offerwalls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFF6584).withOpacity(0.4)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔥 MONLIX', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6584))),
                        SizedBox(height: 4),
                        Text('High Pay Tasks', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        Text('Earn ₹10 - ₹500', style: TextStyle(fontSize: 11, color: Color(0xFF00FF87))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚡ CPALEAD', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF))),
                        SizedBox(height: 4),
                        Text('Fast Installs', style: TextStyle(fontSize: 12, color: Colors.white70)),
                        Text('Instant Credits', style: TextStyle(fontSize: 11, color: Color(0xFF00FF87))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Direct Tasks
            const Text('Premier Daily Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _taskItem('Join Official Telegram', '+100 Coins (₹1.00)', Icons.send, const Color(0xFF0088CC)),
            _taskItem('Subscribe A28 YouTube', '+100 Coins (₹1.00)', Icons.play_arrow, const Color(0xFFFF0000)),
            _taskItem('Install Meesho & Register', '+1200 Coins (₹12.00)', Icons.shopping_bag, const Color(0xFF9C27B0)),
          ],
        ),
      ),
    );
  }
Widget _taskItem(String title, String reward, IconData icon, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: bg.withOpacity(0.2),
            child: Icon(icon, color: bg, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(reward, style: const TextStyle(color: Color(0xFF00FF87), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 6. GAMES SCREEN (3 Spins & Scratch)
// ----------------------------------------------------
class GamesScreen extends StatelessWidget {
  final int spinsLeft;
  final int scratchLeft;
  final Function(int) onSpinWin;
  final Function(int) onScratchWin;

  const GamesScreen({
    super.key,
    required this.spinsLeft,
    required this.scratchLeft,
    required this.onSpinWin,
    required this.onScratchWin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games & Rewards', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.refresh, color: Color(0xFF00FF87)),
                        const SizedBox(width: 8),
                        Text('Spins Left: $spinsLeft / 3', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
                        const SizedBox(width: 8),
                        Text('Scratch: $scratchLeft / 2', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text('Spin & Win Real Coins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Win up to 200 Coins in every spin!', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FF87), width: 4),
                          gradient: const SweepGradient(
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF261C52),
                              Color(0xFF00FF87),
                              Color(0xFFFFD700),
                              Color(0xFF6C63FF),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: spinsLeft > 0
                            ? () {
                                onSpinWin(50);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('🎉 You won 50 Coins!')),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(22),
                          backgroundColor: const Color(0xFF0B0E14),
                        ),
                        child: Text(
                          spinsLeft > 0 ? 'SPIN' : 'LIMIT',
                          style: TextStyle(
                            color: spinsLeft > 0 ? const Color(0xFF00FF87) : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (spinsLeft == 0)
                    const Text('Watch Video Ad to unlock extra spins (Coming Soon)', style: TextStyle(fontSize: 12, color: Colors.orange)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFF261C52),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: const Icon(Icons.touch_app, color: Color(0xFFFFD700), size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Golden Scratch Card', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          scratchLeft > 0 ? 'Tap to scratch & reveal coins' : 'Today limit finished',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: scratchLeft > 0
                        ? () {
                            onScratchWin(30);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🎉 Revealed 30 Coins!')),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
                    child: const Text('Scratch'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 7. REFER & EARN SCREEN
// ----------------------------------------------------
class ReferScreen extends StatelessWidget {
  final double referCash;
  final int invitedCount;
  final VoidCallback onNavigateToWallet;

  const ReferScreen({
    super.key,
    required this.referCash,
    required this.invitedCount,
    required this.onNavigateToWallet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refer & Earn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1E283D), Color(0xFF121724)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Referral Cash Balance', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('₹${referCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
                      Text('$invitedCount Friends Invited', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: onNavigateToWallet,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('WITHDRAW'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF87),
                      foregroundColor: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text('Your Referral Code', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6C63FF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'TPL8821',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        SizedBox(width: 14),
                        Icon(Icons.copy, color: Color(0xFF00FF87), size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening WhatsApp to share invite link...')),
                        );
                      },
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text('SHARE ON WHATSAPP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Referral Rules:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('1. Friend signs up using your code.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text('2. You get ₹5 instantly on their first task.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  Text('3. 1st withdrawal at ₹5. Next withdrawals at ₹50 (10 invites).', style: TextStyle(fontSize: 12, color: Color(0xFF00FF87))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ----------------------------------------------------
// 8. WALLET SCREEN (Daily 1 Limit & 3 Passbooks)
// ----------------------------------------------------
class WalletScreen extends StatelessWidget {
  final int coins;
  final double taskCash;
  final double referCash;
  final int taskWithdrawCount;
  final int referWithdrawCount;
  final int totalInvited;
  final bool hasConvertedToday;
  final bool hasTaskWithdrawnToday;
  final bool hasReferWithdrawnToday;
  final List<String> coinHistory;
  final List<String> cashHistory;
  final List<String> referHistory;

  final Function(int) onConvert;
  final Function(double) onTaskWithdraw;
  final Function(double) onReferWithdraw;

  const WalletScreen({
    super.key,
    required this.coins,
    required this.taskCash,
    required this.referCash,
    required this.taskWithdrawCount,
    required this.referWithdrawCount,
    required this.totalInvited,
    required this.hasConvertedToday,
    required this.hasTaskWithdrawnToday,
    required this.hasReferWithdrawnToday,
    required this.coinHistory,
    required this.cashHistory,
    required this.referHistory,
    required this.onConvert,
    required this.onTaskWithdraw,
    required this.onReferWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TPL Passbook & Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. COIN BANK (Daily 1 Convert)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('🪙 Coin Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('100 Coins = ₹1.00', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('$coins Coins', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasConvertedToday ? null : () => _showConvertDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          hasConvertedToday ? 'CONVERTED TODAY (COME TOMORROW)' : 'CONVERT COINS TO CASH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. TASK CASH WALLET
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('💵 Task & Games Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF0B0E14), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            taskWithdrawCount == 0 ? 'Next Min: ₹5' : (taskWithdrawCount == 1 ? 'Next Min: ₹25' : 'Min: ₹50'),
                            style: const TextStyle(fontSize: 11, color: Color(0xFF00FF87)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('₹${taskCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasTaskWithdrawnToday ? null : () => _showTaskWithdrawDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF87),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          hasTaskWithdrawnToday ? 'WITHDRAWN TODAY (LIMIT 1/DAY)' : 'WITHDRAW TASK CASH TO UPI',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. REFERRAL CASH WALLET
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('👥 Referral Cash Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFF0B0E14), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            referWithdrawCount == 0 ? '1st Min: ₹5' : 'Next Min: ₹50 (10 Invites)',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6C63FF)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('₹${referCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasReferWithdrawnToday ? null : () => _showReferWithdrawDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          hasReferWithdrawnToday ? 'WITHDRAWN TODAY (LIMIT 1/DAY)' : 'WITHDRAW REFERRAL CASH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. TRANSACTION PASSBOOK
              const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFF00FF87),
                labelColor: Color(0xFF00FF87),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Coins History'),
                  Tab(text: 'Task Cash Payouts'),
                  Tab(text: 'Referral History'),
                ],
              ),
              SizedBox(
                height: 240,
                child: TabBarView(
                  children: [
                    _historyList(coinHistory),
                    _historyList(cashHistory),
                    _historyList(referHistory),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyList(List<String> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF00FF87)),
            const SizedBox(width: 10),
            Expanded(child: Text(items[index], style: const TextStyle(fontSize: 13))),
          ],
        ),
      ),
    );
  }

  void _showConvertDialog(BuildContext context) {
    final textController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: const Text('Convert Coins to Cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Minimum 100 coins (Limit: 1 time per day)', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Coins',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              int entered = int.tryParse(textController.text) ?? 0;
              if (entered < 100) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 100 coins required!')));
                return;
              }
              if (entered > coins) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient coins!')));
                return;
              }
              Navigator.pop(context);
              onConvert(entered);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
            child: const Text('Convert Now'),
          )
        ],
      ),
    );
  }

  void _showTaskWithdrawDialog(BuildContext context) {
    double minRequired = taskWithdrawCount == 0 ? 5.0 : (taskWithdrawCount == 1 ? 25.0 : 50.0);
    final upiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text('Withdraw ₹${minRequired.toInt()} Task Cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Daily limit: 1 time per day\nCurrent Balance: ₹${taskCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(hintText: 'Enter UPI ID (e.g. 98****@paytm)', border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (taskCash < minRequired) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient balance! Need ₹$minRequired')));
                return;
              }
              if (upiController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid UPI ID!')));
                return;
              }
              Navigator.pop(context);
              onTaskWithdraw(minRequired);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            child: const Text('Submit Payout'),
          )
        ],
      ),
    );
  }

  void _showReferWithdrawDialog(BuildContext context) {
    double minRequired = referWithdrawCount == 0 ? 5.0 : 50.0;
    final upiController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text('Withdraw ₹${minRequired.toInt()} Refer Cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (referWithdrawCount > 0 && totalInvited < 10)
              const Text('⚠️ Requires 10 completed invites to unlock ₹50 payout!', style: TextStyle(color: Colors.orange, fontSize: 12))
            else
              Text('Daily limit: 1 time per day\nCurrent Balance: ₹${referCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(hintText: 'Enter UPI ID (e.g. 98****@apl)', border: OutlineInputBorder()),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (referWithdrawCount > 0 && totalInvited < 10) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite at least 10 friends to withdraw ₹50!')));
                return;
              }
              if (referCash < minRequired) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Insufficient balance! Need ₹$minRequired')));
                return;
              }
              if (upiController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid UPI ID!')));
                return;
              }
              Navigator.pop(context);
              onReferWithdraw(minRequired);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
            child: const Text('Submit Payout'),
          )
        ],
      ),
    );
  }
}
