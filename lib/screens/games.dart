import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

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
  static const String _rewardedPlacementId = 'BP_Rewarded_Android';

  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  double _currentAngle = 0;
  bool _isSpinning = false;
  bool _scratchRevealed = false;

  final List<int> sliceRewards = [10, 50, 25, 100, 15, 200];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  // 1. Show Rewarded Ad before Spinning
  void _watchAdAndSpin() {
    if (widget.spinsLeft <= 0 || _isSpinning) return;

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        _spinWheel();
      },
      onFailed: (placementId, error, message) {
        debugPrint('Ad failed to load: $error $message. Continuing spin for testing.');
        _spinWheel();
      },
      onSkipped: (placementId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Watch the full video ad to unlock your spin!')),
          );
        }
      },
    );
  }

  void _spinWheel() {
    setState(() => _isSpinning = true);
    final random = math.Random();
    int chosenIndex = random.nextInt(sliceRewards.length);
    double targetAngle = _currentAngle + (math.pi * 2 * 5) + (chosenIndex * (math.pi * 2 / sliceRewards.length));

    _spinAnimation = Tween<double>(begin: _currentAngle, end: targetAngle).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.decelerate),
    )..addListener(() => setState(() {}));

    _spinController.forward(from: 0).then((_) {
      _currentAngle = targetAngle % (math.pi * 2);
      int wonCoins = sliceRewards[chosenIndex];
      widget.onSpinWin(wonCoins);
      setState(() => _isSpinning = false);

      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF151922),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.stars, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text('Congratulations!'),
            ],
          ),
          content: Text(
            'You won +$wonCoins Coins from the Lucky Wheel!',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Collect Reward', style: TextStyle(color: Color(0xFF00FF87), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  // 2. Show Rewarded Ad before Scratching
  void _watchAdAndScratch() {
    if (widget.scratchLeft <= 0 || _scratchRevealed) return;

    UnityAds.showVideoAd(
      placementId: _rewardedPlacementId,
      onComplete: (placementId) {
        setState(() => _scratchRevealed = true);
        widget.onScratchWin(45);
      },
      onFailed: (placementId, error, message) {
        debugPrint('Ad failed to load: $error $message. Continuing scratch.');
        setState(() => _scratchRevealed = true);
        widget.onScratchWin(45);
      },
      onSkipped: (placementId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Watch full video to reveal scratch reward!')),
          );
        }
      },
    );
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
          children: [
            // Chances status indicators
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

            // 1. Lucky Spin Wheel Card
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
                  const Text('Watch a short video & win up to 200 free coins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 20),
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
                      const Icon(Icons.arrow_drop_down, size: 38, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 180,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: (_isSpinning || widget.spinsLeft <= 0) ? null : _watchAdAndSpin,
                      icon: const Icon(Icons.play_circle_fill, size: 20),
                      label: Text(
                        _isSpinning ? 'SPINNING...' : (widget.spinsLeft > 0 ? 'SPIN NOW' : 'DAILY OVER'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Scratch & Win Card
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
                  const Text('Golden Scratch Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('Watch video to reveal guaranteed coins', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _watchAdAndScratch,
                    child: Container(
                      height: 90,
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
                            ? const Text(
                                '+45 COINS REVEALED!',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00FF87), fontSize: 16),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.play_circle_outline, color: Colors.black87),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.scratchLeft > 0 ? 'TAP TO WATCH & SCRATCH' : 'TODAY FINISHED',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
                                  ),
                                ],
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
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * sweepAngle, sweepAngle, true, paint);
    }
    canvas.drawCircle(center, 22, Paint()..color = const Color(0xFF0B0E14));
    canvas.drawCircle(center, 18, Paint()..color = const Color(0xFF00FF87));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
