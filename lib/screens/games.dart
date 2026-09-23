import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
  static const String _rewardedPlacementId = 'BP_Rewarded_Android';

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  int _lastTickSlice = -1;

  // 3-Task Scratch Card Loop State
  int _taskProgress = 0; // 0 to 3
  bool _scratchRevealed = false;

  // 🎡 Visual Slices (50 & 200 are high attractions)
  final List<_WheelItem> wheelSlices = [
    _WheelItem(label: '1 Coin', coins: 1, color: const Color(0xFF00FF87)),
    _WheelItem(label: '50 Coins', coins: 50, color: const Color(0xFFFF5252), isBait: true),
    _WheelItem(label: '5 Coins', coins: 5, color: const Color(0xFF6C63FF)),
    _WheelItem(label: 'Better Luck', coins: 0, color: const Color(0xFF374151)),
    _WheelItem(label: '200 Coins', coins: 200, color: const Color(0xFFFFD700), isBait: true),
    _WheelItem(label: '12 Coins', coins: 12, color: const Color(0xFF00C0FF)),
  ];

  // 🎮 Top Instant Gamezop Games
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
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  // 🛡️ Owner-Safe Weighted Probability Selector (Never selects 50 or 200)
  int _pickSafeOutcomeIndex() {
    final rand = math.Random().nextInt(100);
    if (rand < 45) {
      return 0; // 1 Coin (45% chance)
    } else if (rand < 80) {
      return 2; // 5 Coins (35% chance)
    } else if (rand < 95) {
      return 5; // 12 Coins (15% chance)
    } else {
      return 3; // Better Luck (5% chance)
    }
  }

  void _watchAdAndSpin() {
    if (widget.spinsLeft <= 0 || _isSpinning) return;

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (id) => _spinWheel(),
      onFailed: (id, err, msg) {
        debugPrint("Ad failed: $err. Spinning directly.");
        _spinWheel();
      },
      onSkipped: (id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Watch full ad to get your daily spin!')),
          );
        }
      },
    );
  }

  void _spinWheel() {
    setState(() => _isSpinning = true);

    final chosenIndex = _pickSafeOutcomeIndex();
    final sliceAngle = (2 * math.pi) / wheelSlices.length;

    // Align target slice precisely under top pointer (12 o'clock = 1.5 * pi)
    const double targetPointerAngle = 1.5 * math.pi;
    final double sliceCenter = (chosenIndex + 0.5) * sliceAngle;

    double neededOffset = (targetPointerAngle - sliceCenter) % (2 * math.pi);
    if (neededOffset < 0) neededOffset += (2 * math.pi);

    final double currentModulo = _currentAngle % (2 * math.pi);
    final double extraTurns = (6 * 2 * math.pi); // 6 full rotations
    final double targetAngle = _currentAngle + extraTurns + (neededOffset - currentModulo);

    _spinAnimation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCirc),
    )..addListener(() {
        // Ticking audio/haptic feedback on passing slices
        final currentSliceIndex = ((_spinAnimation.value / sliceAngle).floor()) % wheelSlices.length;
        if (currentSliceIndex != _lastTickSlice) {
          _lastTickSlice = currentSliceIndex;
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.selectionClick();
        }
        setState(() {});
      });

    _spinController.forward(from: 0).then((_) {
      _currentAngle = targetAngle % (2 * math.pi);
      final wonItem = wheelSlices[chosenIndex];
      setState(() => _isSpinning = false);

      if (wonItem.coins > 0) {
        widget.onSpinWin(wonItem.coins);
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
                ? 'You won +${wonItem.coins} Coins in the Lucky Wheel!'
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

  // 🎁 Scratch Card: Ad + Win + Reset Loop
  void _watchAdAndScratch() {
    if (_taskProgress < 3 || _scratchRevealed) return;

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (id) => _revealScratchReward(),
      onFailed: (id, err, msg) => _revealScratchReward(),
      onSkipped: (id) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Watch full video to scratch!')),
          );
        }
      },
    );
  }

  void _revealScratchReward() {
    setState(() => _scratchRevealed = true);
    HapticFeedback.mediumImpact();
    widget.onScratchWin(6); // Safe profit: 6 Coins (₹0.06)

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Reset card back to 0/3 tasks requirement loop
        setState(() {
          _taskProgress = 0;
          _scratchRevealed = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 +6 Coins added! Complete 3 more tasks to unlock another card.'),
            backgroundColor: Color(0xFF00FF87),
          ),
        );
      }
    });
  }

  Future<void> _playGame(String url, int coins, String title) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url, mode: LaunchMode.externalApplication);
        widget.onSpinWin(coins);
        // Playing a game counts towards scratch card progress
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
            // Status bar
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
                        Text('Daily Spin: ${widget.spinsLeft}/1', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

            // 1. Wheel Card
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
                  const Text('Win up to 200 Free Coins daily', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                      // Top arrow pointer
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
                    mainAxisAlignment: MainAxisAlignment.between,
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
                                    '+6 COINS WON!',
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

            // 3. Gamezop Mini Games
            const Text(
              '🎮 Play Instant Games (Gives Progress)',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),

            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: gamezopGames.length,
              itemBuilder: (context, index) {
                final game = gamezopGames[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _playGame(game['url'], game['coins'], game['title']),
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
                            color: (game['color'] as Color).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(game['icon'] as IconData, color: game['color'] as Color, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game['title'],
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+${game['coins']} Coins & Task +1',
                          style: const TextStyle(color: Color(0xFF00FF87), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
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

// 🎨 Wheel Painter with Clear Rotated Labels
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

      // Draw slice border
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

      // Draw Text inside slice
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

      // Position text along the radius
      canvas.translate(radius * 0.58, -tp.height / 2);
      tp.paint(canvas, Offset.zero);

      canvas.restore();
    }

    // Wheel Center Pin
    canvas.drawCircle(center, 24, Paint()..color = const Color(0xFF0B0E14));
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF00FF87));
    canvas.drawCircle(center, 8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
