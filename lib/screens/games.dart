import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ad_service.dart';
import '../widgets/unity_banner_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/remote_config_service.dart';

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

class _WheelItem {
  final String label;
  final int coins;
  final Color color;
  final bool isBait;

  _WheelItem({
    required this.label,
    required this.coins,
    required this.color,
    this.isBait = false,
  });
}

class _GamesScreenState extends State<GamesScreen> with SingleTickerProviderStateMixin {
  // Remote Ads Configuration from Admin Panel
  bool _adsActive = true;

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  int _lastTickSlice = -1;

  // Audio Player Instance
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 3-Task Scratch Card Loop State
  int _taskProgress = 0;
  bool _scratchRevealed = false;

  // Visual Slices (50 & 200 are bait slices)
  List<_WheelItem> wheelSlices = [
    _WheelItem(label: '1 Bonus', coins: 1, color: const Color(0xFF00FF87)),
    _WheelItem(label: '50 Bonus', coins: 50, color: const Color(0xFFFF5252), isBait: true),
    _WheelItem(label: '5 Bonus', coins: 5, color: const Color(0xFF6C63FF)),
    _WheelItem(label: 'Better Luck', coins: 0, color: const Color(0xFF374151)),
    _WheelItem(label: '200 Bonus', coins: 200, color: const Color(0xFFFFD700), isBait: true),
    _WheelItem(label: '12 Bonus', coins: 12, color: const Color(0xFF00C0FF)),
  ];

  // Default Fallback Instant Games
  final List<Map<String, dynamic>> gamezopGames = [
    {
      'title': 'Cricket Gunda',
      'category': 'Sports',
      'coins': 2,
      'url': 'https://www.gamezop.com/g/r1W50d89?id=tpl_cricket',
      'icon': Icons.sports_cricket,
      'color': const Color(0xFF00FF87),
    },
    {
      'title': 'Fruit Chop',
      'category': 'Arcade',
      'coins': 2,
      'url': 'https://www.gamezop.com/g/rkXG0O85?id=tpl_fruit',
      'icon': Icons.local_pizza,
      'color': const Color(0xFFFF6584),
    },
    {
      'title': 'Bottle Shoot',
      'category': 'Action',
      'coins': 2,
      'url': 'https://www.gamezop.com/g/B1w5CdL5?id=tpl_bottle',
      'icon': Icons.gps_fixed,
      'color': const Color(0xFFFFD700),
    },
    {
      'title': 'Bubble Wipeout',
      'category': 'Puzzle',
      'coins': 2,
      'url': 'https://www.gamezop.com/g/SkWG0u8q?id=tpl_bubble',
      'icon': Icons.bubble_chart,
      'color': const Color(0xFF6C63FF),
    },
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );
    _listenRemoteGameLimits();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _listenRemoteGameLimits() {
    FirebaseFirestore.instance
        .collection('settings')
        .doc('game_limits')
        .snapshots()
        .listen((snap) {
      if (!mounted || !snap.exists || snap.data() == null) return;
      final rawSlices = snap.data()!['wheelSlices'];
      if (rawSlices is! List) return;

      final values = rawSlices
          .map((value) => int.tryParse(value.toString()))
          .whereType<int>()
          .toList();
      if (values.length < 2) return;

      setState(() {
        wheelSlices = values.map((coins) => _WheelItem(
          label: coins <= 0 ? 'Better Luck' : '$coins Bonus',
          coins: coins,
          color: _wheelColor(coins),
          isBait: coins >= 50,
        )).toList();
      });
    });
  }

  Color _wheelColor(int coins) {
    switch (coins) {
      case 0:
        return const Color(0xFF374151);
      case 1:
        return const Color(0xFF00FF87);
      case 5:
        return const Color(0xFF6C63FF);
      case 12:
        return const Color(0xFF00C0FF);
      case 50:
        return const Color(0xFFFF5252);
      case 200:
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF00C0FF);
    }
  }

  void _playTickSound() {
    try {
      _audioPlayer.play(AssetSource('sounds/ticktick.mp3'), mode: PlayerMode.lowLatency);
    } catch (_) {}
  }

  void _playWinSound() {
    try {
      _audioPlayer.play(AssetSource('sounds/win.mp3'));
    } catch (_) {}
  }

  // Choose only configured low-value outcomes; never assume fixed slice indexes.
  int _pickSafeOutcomeIndex() {
    final safeIndexes = <int>[];
    for (var i = 0; i < wheelSlices.length; i++) {
      if (wheelSlices[i].coins <= 12) safeIndexes.add(i);
    }
    if (safeIndexes.isEmpty) return 0;
    if (safeIndexes.length == 1) return safeIndexes.first;

    final rand = math.Random().nextInt(100);
    if (rand < 45) return safeIndexes.first;
    return safeIndexes[math.Random().nextInt(safeIndexes.length)];
  }

  void _watchAdAndSpin() {
    if (widget.spinsLeft <= 0 || _isSpinning) return;
    final config = RemoteConfigService.instance;
    if (!config.rewardedSpinEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Extra Spin ads are currently disabled.')));
      return;
    }
    AdService.instance.showRewardedAd(
      context: context,
      onReward: _spinWheel,
      onFailed: () {},
    );
  }

  void _spinWheel() {
    setState(() => _isSpinning = true);

    final chosenIndex = _pickSafeOutcomeIndex();
    final sliceAngle = (2 * math.pi) / wheelSlices.length;

    const double targetPointerAngle = 1.5 * math.pi;
    final double sliceCenter = (chosenIndex + 0.5) * sliceAngle;

    double neededOffset = (targetPointerAngle - sliceCenter) % (2 * math.pi);
    if (neededOffset < 0) neededOffset += (2 * math.pi);

    final double currentModulo = _currentAngle % (2 * math.pi);
    final double extraTurns = (6 * 2 * math.pi);
    final double targetAngle = _currentAngle + extraTurns + (neededOffset - currentModulo);

    _spinAnimation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCirc),
    )..addListener(() {
        final currentSliceIndex = ((_spinAnimation.value / sliceAngle).floor()) % wheelSlices.length;
        if (currentSliceIndex != _lastTickSlice) {
          _lastTickSlice = currentSliceIndex;
          _playTickSound();
          HapticFeedback.selectionClick();
        }
        setState(() {});
      });

    _spinController.forward(from: 0).then((_) {
      _currentAngle = targetAngle % (2 * math.pi);
      final wonItem = wheelSlices[chosenIndex];
      setState(() => _isSpinning = false);

      if (wonItem.coins > 0) {
        _playWinSound();
        // Game bonus is not cashable and does not change wallet coins.
      }

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF151922),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                wonItem.coins > 0 ? Icons.stars_rounded : Icons.sentiment_neutral_rounded,
                color: wonItem.coins > 0 ? const Color(0xFFFFD700) : Colors.grey,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(wonItem.coins > 0 ? 'Congratulations!' : 'Better Luck!'),
            ],
          ),
          content: Text(
            wonItem.coins > 0
                ? 'You won a game bonus! Your wallet coins are earned from tasks and offers.'
                : 'No luck this time. Come back tomorrow for your next spin!',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK', style: TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  void _watchAdAndScratch() {
    if (_taskProgress < 3 || _scratchRevealed) return;
    final config = RemoteConfigService.instance;
    if (!config.rewardedScratchEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scratch ads are currently disabled.')));
      return;
    }
    AdService.instance.showRewardedAd(
      context: context,
      onReward: _revealScratchReward,
      onFailed: () {},
    );
  }

  void _revealScratchReward() {
    setState(() => _scratchRevealed = true);
    _playWinSound();
    HapticFeedback.mediumImpact();
    // Scratch is a gameplay bonus only; it never credits cashable coins.

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _taskProgress = 0;
          _scratchRevealed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Bonus scratch completed! Complete 3 more games to unlock another card.'),
            backgroundColor: Color(0xFF00FF87),
          ),
        );
      }
    });
  }

  Future<void> _playGame(String url, int coins, String title) async {
    final config = RemoteConfigService.instance;
    try {
      if (await canLaunchUrlString(url)) {
        if (config.interstitialEnabled) {
          await AdService.instance.showInterstitialAd(context: context);
        }
        await launchUrlString(url, mode: LaunchMode.externalApplication);
        if (_taskProgress < 3) {
          setState(() => _taskProgress += 1);
        }
      }
    } catch (e) {
      debugPrint("Game launch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        title: const Text('Games & Lucky Zone', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UnityBannerWidget(),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF151922),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00FF87).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rotate_right_rounded, color: Color(0xFF00FF87), size: 20),
                        const SizedBox(width: 8),
                        Text('Daily Spin: ${widget.spinsLeft}/${RemoteConfigService.instance.dailySpinLimit}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFFD700), size: 20),
                        const SizedBox(width: 8),
                        Text('Task Progress: $_taskProgress/3', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 1. Lucky Spin Wheel Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  const Text('Lucky Spin Wheel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Play & unlock game bonuses daily', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),

                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Transform.rotate(
                          angle: _isSpinning ? _spinAnimation.value : _currentAngle,
                          child: CustomPaint(
                            size: const Size(220, 220),
                            painter: StylizedWheelPainter(wheelSlices),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 42, color: Colors.white),
                    ],
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: 190,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: (_isSpinning || widget.spinsLeft <= 0) ? null : _watchAdAndSpin,
                      icon: const Icon(Icons.play_circle_fill, size: 20),
                      label: Text(
                        _isSpinning ? 'SPINNING...' : (widget.spinsLeft > 0 ? 'SPIN NOW' : 'DAILY OVER'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // 2. PhonePe Style Scratch Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PhonePe Gold Scratch Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$_taskProgress/3 Tasks',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _taskProgress >= 3
                        ? '🎉 Card Unlocked! Tap to watch ad & scratch.'
                        : 'Play mini games or complete tasks to unlock (${3 - _taskProgress} remaining)',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  GestureDetector(
                    onTap: _taskProgress >= 3 ? _watchAdAndScratch : null,
                    child: Container(
                      height: 105,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: _scratchRevealed
                            ? const LinearGradient(colors: [Color(0xFF1E2638), Color(0xFF111622)])
                            : LinearGradient(
                                colors: _taskProgress >= 3
                                    ? [const Color(0xFFFFD700), const Color(0xFFFFA000), const Color(0xFFFF8F00)]
                                    : [const Color(0xFF262B3A), const Color(0xFF181C26)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _taskProgress >= 3 ? const Color(0xFFFFD700) : Colors.white12,
                          width: 1.5,
                        ),
                        boxShadow: _taskProgress >= 3
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withOpacity(0.3),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                )
                              ]
                            : [],
                      ),
                      child: Center(
                        child: _scratchRevealed
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF00FF87), size: 30),
                                  SizedBox(height: 4),
                                  Text(
                                    'BONUS UNLOCKED!',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00FF87), fontSize: 16),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _taskProgress >= 3 ? Icons.touch_app_rounded : Icons.lock_outline_rounded,
                                    color: _taskProgress >= 3 ? Colors.black87 : Colors.white38,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _taskProgress >= 3 ? 'TAP TO WATCH & SCRATCH' : 'LOCKED: COMPLETE 3 TASKS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: _taskProgress >= 3 ? Colors.black87 : Colors.white38,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Gamezop Mini Games (Live Stream from Admin Panel with Default Fallback)
            const Text(
              '🎮 Play Instant Games (Gives Progress)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('games').snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> displayedGames = [];

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  for (var doc in snapshot.data!.docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    if (d['isActive'] != false) displayedGames.add({
                      'title': d['title'] ?? 'Mini Game',
                      'category': d['category'] ?? 'Arcade',
                      'coins': d['coins'] is int ? d['coins'] : (int.tryParse(d['coins'].toString()) ?? 2),
                      'url': d['url'] ?? d['gameUrl'] ?? 'https://www.gamezop.com',
                      'icon': Icons.sports_esports_rounded,
                      'color': const Color(0xFF00FF87),
                    });
                  }
                } else {
                  displayedGames = gamezopGames;
                }

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: displayedGames.length,
                  itemBuilder: (context, index) {
                    final game = displayedGames[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _playGame(
                        game['url'],
                        game['coins'] as int,
                        game['title'],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF151922),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ((game['color'] as Color?) ?? const Color(0xFF00FF87)).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                (game['icon'] as IconData?) ?? Icons.sports_esports_rounded,
                                color: (game['color'] as Color?) ?? const Color(0xFF00FF87),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              game['title'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+1 Game Progress',
                              style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class StylizedWheelPainter extends CustomPainter {
  final List<_WheelItem> slices;
  StylizedWheelPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweepAngle = (2 * math.pi) / slices.length;

    for (int i = 0; i < slices.length; i++) {
      final paint = Paint()..color = slices[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        paint,
      );

      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sweepAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i + 0.5) * sweepAngle);

      final textSpan = TextSpan(
        text: slices[i].label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      canvas.translate(radius * 0.58, -tp.height / 2);
      tp.paint(canvas, Offset.zero);

      canvas.restore();
    }

    canvas.drawCircle(center, 24, Paint()..color = const Color(0xFF0B0E14));
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF00FF87));
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
