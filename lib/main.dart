import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
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

// ----------------------------------------------------
// 1. SPLASH SCREEN
// ----------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isLoggedIn ? const MainNavigationScreen() : const LoginScreen(),
          ),
        );
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00FF87), width: 3),
              ),
              child: const Center(
                child: Text(
                  'TPL',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Color(0xFF00FF87),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Text('Powered by', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            const Text(
              'A28 TECHNOLOGIES',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 2. LOGIN SCREEN
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
              const SizedBox(height: 30),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00FF87), width: 2),
                ),
                child: const Center(
                  child: Text('TPL', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF00FF87))),
                ),
              ),
              const SizedBox(height: 16),
              const Text('TASK PREMIER LEAGUE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              const Text('Play Tasks • Earn Real UPI Cash', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 35),

              if (!_hasReferralCode)
                TextButton.icon(
                  onPressed: () => setState(() => _hasReferralCode = true),
                  icon: const Icon(Icons.card_giftcard, size: 18, color: Color(0xFF00FF87)),
                  label: const Text('Have an invite code? Enter here', style: TextStyle(color: Color(0xFF00FF87))),
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
                      hintText: 'Enter Referral Code',
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _hasReferralCode = false),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.g_mobiledata, color: Colors.red, size: 30),
                      SizedBox(width: 8),
                      Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 3. MAIN CONTAINER (5 TABS & WORKING DRAWER)
// ----------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  // Global Reactive States
  int coins = 12450;
  double taskCash = 100.00;
  double referCash = 15.00;
  String? savedUpiId = "akhilesh@okhdfcbank"; // Saved UPI demo state

  bool hasConvertedToday = false;
  bool hasTaskWithdrawnToday = false;
  bool hasReferWithdrawnToday = false;

  int spinsLeft = 3;
  int scratchLeft = 2;
  bool streakClaimedToday = false;

  final List<String> coinHistory = [
    '+50 Coins - Daily Streak Day 1',
    '+25 Coins - Spin & Win Reward',
    '+1200 Coins - Notik Game Offer',
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

  final List<Map<String, String>> invitedFriends = [
    {'name': 'Suresh K', 'id': 'TPL#4102', 'reward': '₹5.00', 'status': 'Completed'},
    {'name': 'Ramesh P', 'id': 'TPL#8891', 'reward': '₹5.00', 'status': 'Completed'},
    {'name': 'Praveen M', 'id': 'TPL#2201', 'reward': '₹5.00', 'status': 'Completed'},
    {'name': 'Vinay B', 'id': 'TPL#9012', 'reward': '₹0.00', 'status': 'Pending (Need 1 Task)'},
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
            coinHistory.insert(0, '+20 Coins - Daily Streak Claimed');
          });
        },
        onTaskClick: (taskName, coinReward) {
          switchTab(1); // Redirect to Tasks tab
        },
      ),
      TasksTabScreen(
        onCompleteTask: (name, reward) {
          setState(() {
            coins += reward;
            coinHistory.insert(0, '+$reward Coins - Completed $name');
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task Finished: +$reward Coins!')));
        },
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
        onSaveUpi: (newUpi) {
          setState(() => savedUpiId = newUpi);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID Saved Successfully!')));
        },
        onConvertCoins: (int enteredCoins) {
          double convertedRupees = enteredCoins / 100.0;
          setState(() {
            coins -= enteredCoins;
            taskCash += convertedRupees;
            hasConvertedToday = true;
            coinHistory.insert(0, '-$enteredCoins Coins - Converted to ₹${convertedRupees.toStringAsFixed(2)}');
            cashHistory.insert(0, '+₹${convertedRupees.toStringAsFixed(2)} - Converted from Coins');
          });
        },
        onWithdrawTaskCash: (double amount) {
          setState(() {
            taskCash -= amount;
            hasTaskWithdrawnToday = true;
            cashHistory.insert(0, '-₹${amount.toStringAsFixed(2)} - UPI Paid to $savedUpiId');
          });
        },
        onWithdrawReferCash: (double amount) {
          setState(() {
            referCash -= amount;
            hasReferWithdrawnToday = true;
            referHistory.insert(0, '-₹${amount.toStringAsFixed(2)} - UPI Paid to $savedUpiId');
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
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: Color(0xFF00FF87)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment, color: Color(0xFF00FF87)),
              label: 'Tasks',
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
// 4. SIDE PROFILE DRAWER
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
                  radius: 32,
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.person, size: 38, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text('Akhilesh Savale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('akhilesh@gmail.com', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF0B0E14), borderRadius: BorderRadius.circular(6)),
                  child: const Text('TPL ID: #88219', style: TextStyle(fontSize: 12, color: Color(0xFF00FF87))),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.telegram, color: Color(0xFF29B6F6)),
            title: const Text('Join Telegram Channel'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFFE1306C)),
            title: const Text('Follow Instagram'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_fill, color: Color(0xFFFF0000)),
            title: const Text('Subscribe YouTube'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.white70),
            title: const Text('FAQs & Payment Proofs'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 5. TAB 1: HOME SCREEN (Hero Slider, Compact Streak, Tasks)
// ----------------------------------------------------
class HomeScreen extends StatefulWidget {
  final int coins;
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenWallet;
  final bool streakClaimed;
  final VoidCallback onClaimStreak;
  final Function(String, int) onTaskClick;

  const HomeScreen({
    super.key,
    required this.coins,
    required this.onOpenDrawer,
    required this.onOpenWallet,
    required this.streakClaimed,
    required this.onClaimStreak,
    required this.onTaskClick,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  final List<Map<String, dynamic>> banners = [
    {
      'title': '🔥 Notik Super Offerwall',
      'desc': 'Play Popular Games & Earn up to ₹500',
      'color': const Color(0xFF6C63FF),
      'tag': 'TOP OFFER'
    },
    {
      'title': '⚡ EarnKaro App Deals',
      'desc': 'Install Meesho & Kotak 811 to get ₹45 Cash',
      'color': const Color(0xFFFF6584),
      'tag': 'HIGH PAY'
    },
    {
      'title': '📱 Official Telegram Channel',
      'desc': 'Join for Daily Giveaway Codes & Instant 100 Coins',
      'color': const Color(0xFF0088CC),
      'tag': 'FREE BONUS'
    },
    {
      'title': '📸 Follow us on Instagram',
      'desc': 'Watch Payment Proofs & Earn 50 Coins',
      'color': const Color(0xFFE1306C),
      'tag': 'SOCIAL'
    },
    {
      'title': '👥 Invite & Earn Big',
      'desc': 'Get ₹5 Instant Cash on Every Friend Join',
      'color': const Color(0xFF00FF87),
      'tag': 'REFERRAL'
    },
    {
      'title': '🎯 Spin & Win Real Cash',
      'desc': '3 Free Daily Spins are Waiting for You!',
      'color': const Color(0xFFFFD700),
      'tag': 'GAMES'
    },
  ];

  @override
  Widget build(BuildContext context) {
    double rupees = widget.coins / 100.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            radius: 17,
            backgroundColor: Color(0xFF1E2235),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: widget.onOpenDrawer,
        ),
        // Item 4: Only "TPL"
        title: const Text(
          'TPL',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 22, color: Color(0xFF00FF87)),
        ),
        actions: [
          // Item 5: Coins + Rupees (₹)
          GestureDetector(
            onTap: widget.onOpenWallet,
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
                  const SizedBox(width: 5),
                  Text('${widget.coins}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Container(
                    height: 14,
                    width: 1,
                    color: Colors.white24,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  Text(
                    '₹${rupees.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FF87), fontSize: 13),
                  ),
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
            // Item 6: Chillar-like Hero Carousel (6 Slides)
            SizedBox(
              height: 140,
              child: PageView.builder(
                controller: _bannerController,
                itemCount: banners.length,
                onPageChanged: (i) => setState(() => _currentBannerIndex = i),
                itemBuilder: (context, index) {
                  final b = banners[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [b['color'].withOpacity(0.85), const Color(0xFF151922)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b['tag'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 8),
                        Text(b['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(b['desc'], style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                banners.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentBannerIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentBannerIndex == i ? const Color(0xFF00FF87) : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Item 2: Compact Chillar-style Daily Streak
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 26),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Daily Check-in (Day 1)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Claim 20 Coins daily bonus', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: widget.streakClaimed ? null : widget.onClaimStreak,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF87),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      widget.streakClaimed ? 'CLAIMED' : 'CLAIM +20',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Item 7: Dual Earning Section (Notik + EarnKaro)
            const Text('Super Earning Walls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _cardWall(
                    title: '🎮 Notik Wall',
                    subtitle: 'Games & Surveys',
                    payout: 'Earn ₹10 - ₹200',
                    color: const Color(0xFF6C63FF),
                    onTap: () => widget.onTaskClick('Notik Wall', 500),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _cardWall(
                    title: '⚡ EarnKaro Hub',
                    subtitle: 'Meesho & Finance',
                    payout: 'Earn ₹25 - ₹100',
                    color: const Color(0xFFFF6584),
                    onTap: () => widget.onTaskClick('EarnKaro Hub', 1000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Item 7: Social Channels Section
            const Text('Official Channels & Social Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _taskTile(
              title: 'Join Official Telegram',
              desc: 'Get live redeem codes & proof',
              reward: '+100 Coins (₹1.00)',
              icon: Icons.send,
              color: const Color(0xFF0088CC),
              onTap: () => widget.onTaskClick('Join Telegram', 100),
            ),
            _taskTile(
              title: 'Subscribe A28 YouTube',
              desc: 'Watch tutorials & app updates',
              reward: '+100 Coins (₹1.00)',
              icon: Icons.play_arrow,
              color: const Color(0xFFFF0000),
              onTap: () => widget.onTaskClick('Subscribe YouTube', 100),
            ),
            _taskTile(
              title: 'Follow on Instagram',
              desc: 'Follow for daily contest alerts',
              reward: '+50 Coins (₹0.50)',
              icon: Icons.camera_alt,
              color: const Color(0xFFE1306C),
              onTap: () => widget.onTaskClick('Follow Instagram', 50),
            ),
          ],
        ),
      ),
    );
  }
  Widget _cardWall({
    required String title,
    required String subtitle,
    required String payout,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF151922),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            const SizedBox(height: 2),
            Text(payout, style: const TextStyle(fontSize: 11, color: Color(0xFF00FF87), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _taskTile({
    required String title,
    required String desc,
    required String reward,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(reward, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
            const SizedBox(height: 2),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

// ----------------------------------------------------
// 6. TAB 2: TASKS SCREEN (Item 8: Ongoing, Completed, Expired)
// ----------------------------------------------------
class TasksTabScreen extends StatelessWidget {
  final Function(String, int) onCompleteTask;

  const TasksTabScreen({super.key, required this.onCompleteTask});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Task Central', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00FF87),
            labelColor: Color(0xFF00FF87),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'Completed'),
              Tab(text: 'Expired'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Ongoing Tasks
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ongoingItem(context, 'Install Meesho & Register (EarnKaro)', '+1200 Coins (₹12)', 1200),
                _ongoingItem(context, 'Play Lords Mobile 5 mins (Notik)', '+450 Coins (₹4.5)', 450),
                _ongoingItem(context, 'Kotak 811 Account Open (EarnKaro)', '+3500 Coins (₹35)', 3500),
              ],
            ),
            // Completed Tasks
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _completedItem('Join Official Telegram', '+100 Coins', 'Verified'),
                _completedItem('Daily Streak Day 1', '+20 Coins', 'Claimed'),
                _completedItem('Welcome Bonus', '+50 Coins', 'Claimed'),
              ],
            ),
            // Expired Tasks
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _expiredItem('Weekend Special Cricket Survey', 'Expired 2 days ago'),
                _expiredItem('Ludo Supreme 10-min Trial', 'Offer Limit Reached'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _ongoingItem(BuildContext context, String title, String reward, int coinValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF261C52),
            child: Icon(Icons.bolt, color: Color(0xFF00FF87)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(reward, style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => onCompleteTask(title, coinValue),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF87),
              foregroundColor: Colors.black,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Complete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _completedItem(String title, String reward, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00FF87)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(reward, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(status, style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _expiredItem(String title, String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151922),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                Text(reason, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 7. TAB 3: GAMES SCREEN (Item 9: Upgraded Wheel & Scratch)
// ----------------------------------------------------
class GamesScreen extends StatefulWidget {
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
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  bool _scratchRevealed = false;

  final List<int> sliceRewards = [10, 50, 25, 100, 15, 200];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spinWheel() {
    if (widget.spinsLeft <= 0 || _isSpinning) return;

    setState(() => _isSpinning = true);
    final random = math.Random();
    int chosenIndex = random.nextInt(sliceRewards.length);
    double targetAngle = _currentAngle + (math.pi * 2 * 5) + (chosenIndex * (math.pi * 2 / sliceRewards.length));

    _spinAnimation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.decelerate),
    )..addListener(() {
        setState(() {});
      });

    _spinController.forward(from: 0).then((_) {
      _currentAngle = targetAngle % (math.pi * 2);
      int wonCoins = sliceRewards[chosenIndex];
      widget.onSpinWin(wonCoins);
      setState(() => _isSpinning = false);

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF151922),
          title: const Text('🎉 Congratulations!'),
          content: Text('You won $wonCoins Coins from Spin & Win!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Claim to Wallet', style: TextStyle(color: Color(0xFF00FF87))),
            )
          ],
        ),
      );
    });
  }
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
            // Spins & Scratch counter
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
                        const Icon(Icons.refresh, color: Color(0xFF00FF87), size: 18),
                        const SizedBox(width: 6),
                        Text('Spins: ${widget.spinsLeft} / 3', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        const Icon(Icons.card_giftcard, color: Color(0xFFFFD700), size: 18),
                        const SizedBox(width: 6),
                        Text('Cards: ${widget.scratchLeft} / 2', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Realistic Spin Wheel Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text('Lucky Spin Wheel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Spin & win up to 200 Coins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),

                  // Wheel Stack with Pointer
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Transform.rotate(
                          angle: _isSpinning ? _spinAnimation.value : _currentAngle,
                          child: CustomPaint(
                            size: const Size(200, 200),
                            painter: WheelPainter(sliceRewards),
                          ),
                        ),
                      ),
                      // Pointer Arrow
                      const Icon(Icons.arrow_drop_down, size: 36, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (_isSpinning || widget.spinsLeft <= 0) ? null : _spinWheel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                      child: Text(
                        _isSpinning ? 'SPINNING...' : (widget.spinsLeft > 0 ? 'SPIN NOW' : 'DAILY LIMIT OVER'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Interactive Golden Scratch Card
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
                  const Text('Golden Scratch & Win', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Tap or scratch to reveal your mystery coins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      if (widget.scratchLeft > 0 && !_scratchRevealed) {
                        setState(() => _scratchRevealed = true);
                        widget.onScratchWin(45);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Wow! You revealed 45 Coins!')),
                        );
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _scratchRevealed
                            ? const LinearGradient(colors: [Color(0xFF261C52), Color(0xFF151922)])
                            : const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFD700)),
                      ),
                      child: Center(
                        child: _scratchRevealed
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 32),
                                  SizedBox(height: 4),
                                  Text('+45 COINS REVEALED!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
                                ],
                              )
                            : Text(
                                widget.scratchLeft > 0 ? 'TAP TO SCRATCH' : 'TODAY LIMIT COMPLETED',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1.5),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Wheel Painter
class WheelPainter extends CustomPainter {
  final List<int> slices;
  WheelPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (math.pi * 2) / slices.length;

    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00FF87),
      const Color(0xFFFF6584),
      const Color(0xFFFFD700),
      const Color(0xFF0088CC),
      const Color(0xFF9C27B0),
    ];

    for (int i = 0; i < slices.length; i++) {
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      // Border outline
      final borderPaint = Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * sweepAngle, sweepAngle, true, borderPaint);
    }

    // Center peg
    canvas.drawCircle(center, 22, Paint()..color = const Color(0xFF0B0E14));
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF00FF87));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ----------------------------------------------------
// 8. TAB 4: REFER & EARN (Item 10: With Invited Users List)
// ----------------------------------------------------
class ReferScreen extends StatelessWidget {
  final double referCash;
  final List<Map<String, String>> invitedFriends;
  final VoidCallback onNavigateToWallet;

  const ReferScreen({
    super.key,
    required this.referCash,
    required this.invitedFriends,
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
            // Referral Cash Card
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
                      const Text('Referral Earnings', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text('₹${referCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00FF87))),
                      Text('${invitedFriends.length} Friends Invited', style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onNavigateToWallet,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
                    child: const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Code Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  const Text('Your Invite Code', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0E14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6C63FF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TPL8821', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        SizedBox(width: 10),
                        Icon(Icons.copy, color: Color(0xFF00FF87), size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite message copied & ready to share!')));
                      },
                      icon: const Icon(Icons.share, color: Colors.white, size: 18),
                      label: const Text('SHARE ON WHATSAPP (EARN ₹5)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Item 10: Invited Users List
            const Row(
              children: [
                Icon(Icons.people, color: Color(0xFF00FF87), size: 18),
                SizedBox(width: 8),
                Text('Invited Friends List', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invitedFriends.length,
              itemBuilder: (context, index) {
                final friend = invitedFriends[index];
                bool isCompleted = friend['status'] == 'Completed';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF151922),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(friend['id']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(friend['reward']!, style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? const Color(0xFF00FF87) : Colors.grey)),
                          Text(friend['status']!, style: TextStyle(fontSize: 10, color: isCompleted ? const Color(0xFF00FF87) : Colors.orange)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// ----------------------------------------------------
// 9. TAB 5: WALLET SCREEN (Item 11: Custom Convert & Saved UPI)
// ----------------------------------------------------
class WalletScreen extends StatelessWidget {
  final int coins;
  final double taskCash;
  final double referCash;
  final String? savedUpiId;
  final bool hasConvertedToday;
  final bool hasTaskWithdrawnToday;
  final bool hasReferWithdrawnToday;
  final List<String> coinHistory;
  final List<String> cashHistory;
  final List<String> referHistory;

  final Function(String) onSaveUpi;
  final Function(int) onConvertCoins;
  final Function(double) onWithdrawTaskCash;
  final Function(double) onWithdrawReferCash;

  const WalletScreen({
    super.key,
    required this.coins,
    required this.taskCash,
    required this.referCash,
    required this.savedUpiId,
    required this.hasConvertedToday,
    required this.hasTaskWithdrawnToday,
    required this.hasReferWithdrawnToday,
    required this.coinHistory,
    required this.cashHistory,
    required this.referHistory,
    required this.onSaveUpi,
    required this.onConvertCoins,
    required this.onWithdrawTaskCash,
    required this.onWithdrawReferCash,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Passbook & Payouts', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Saved UPI Management Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF151922),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance, color: Color(0xFF00FF87)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Linked UPI Account', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            savedUpiId ?? 'No UPI ID Added Yet',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showUpiDialog(context),
                      child: Text(savedUpiId == null ? 'ADD UPI' : 'CHANGE', style: const TextStyle(color: Color(0xFF00FF87))),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Coin Bank (Item 11: Custom Amount Convert)
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
                    const SizedBox(height: 8),
                    Text('$coins Coins', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasConvertedToday ? null : () => _showCustomConvertDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          hasConvertedToday ? 'CONVERTED TODAY (LIMIT 1/DAY)' : 'CONVERT COINS TO CASH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Task Cash Wallet (With Saved UPI Payout)
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('💵 Task Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Instant UPI Transfer', style: TextStyle(fontSize: 11, color: Color(0xFF00FF87))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('₹${taskCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasTaskWithdrawnToday ? null : () => _showWithdrawDialog(context, isTaskCash: true),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
                        child: Text(
                          hasTaskWithdrawnToday ? 'WITHDRAWN TODAY' : 'WITHDRAW TASK CASH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Referral Cash Wallet
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('👥 Referral Cash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Min ₹5 (1st) / ₹50', style: TextStyle(fontSize: 11, color: Color(0xFF6C63FF))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('₹${referCash.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: hasReferWithdrawnToday ? null : () => _showWithdrawDialog(context, isTaskCash: false),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white),
                        child: Text(
                          hasReferWithdrawnToday ? 'WITHDRAWN TODAY' : 'WITHDRAW REFERRAL CASH',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Transaction Tabs
              const Text('Passbook History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const TabBar(
                isScrollable: true,
                indicatorColor: Color(0xFF00FF87),
                labelColor: Color(0xFF00FF87),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: 'Coins'),
                  Tab(text: 'Task Cash'),
                  Tab(text: 'Referral'),
                ],
              ),
              SizedBox(
                height: 200,
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
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF00FF87)),
            const SizedBox(width: 8),
            Expanded(child: Text(items[index], style: const TextStyle(fontSize: 12))),
          ],
        ),
      ),
    );
  }

  // Item 11: Custom Convert Dialog
  void _showCustomConvertDialog(BuildContext context) {
    final textController = TextEditingController(text: '100');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: const Text('Convert Coins to Cash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: $coins Coins', style: const TextStyle(fontSize: 13, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Enter amount of coins to convert (Minimum 100 Coins):', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 500, 1000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              int entered = int.tryParse(textController.text.trim()) ?? 0;
              if (entered < 100) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 100 Coins required!')));
                return;
              }
              if (entered > coins) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient Coins!')));
                return;
              }
              Navigator.pop(c);
              onConvertCoins(entered);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
            child: const Text('Convert'),
          )
        ],
      ),
    );
  }

  // Item 11: Add / Save UPI Dialog
  void _showUpiDialog(BuildContext context) {
    final upiCtrl = TextEditingController(text: savedUpiId ?? '');
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: const Text('Save UPI Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your GPay, PhonePe, or Paytm UPI ID:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. 9876543210@paytm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment, color: Color(0xFF00FF87)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (upiCtrl.text.trim().isEmpty || !upiCtrl.text.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid UPI ID!')));
                return;
              }
              Navigator.pop(c);
              onSaveUpi(upiCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            child: const Text('Save UPI'),
          )
        ],
      ),
    );
  }

  // Item 11: Withdraw Dialog with Saved UPI
  void _showWithdrawDialog(BuildContext context, {required bool isTaskCash}) {
    if (savedUpiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please Add UPI ID first before withdrawing!')));
      _showUpiDialog(context);
      return;
    }

    double currentBalance = isTaskCash ? taskCash : referCash;
    final amountCtrl = TextEditingController(text: isTaskCash ? '5' : '5');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF151922),
        title: Text('Withdraw to $savedUpiId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Balance: ₹${currentBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF00FF87))),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              double entered = double.tryParse(amountCtrl.text.trim()) ?? 0;
              if (entered < 5) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum withdrawal is ₹5!')));
                return;
              }
              if (entered > currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient balance!')));
                return;
              }
              Navigator.pop(c);
              if (isTaskCash) {
                onWithdrawTaskCash(entered);
              } else {
                onWithdrawReferCash(entered);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            child: const Text('Confirm Withdraw'),
          )
        ],
      ),
    );
  }
}
