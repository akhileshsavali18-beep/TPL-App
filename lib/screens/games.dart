import 'dart:math' as math;
import 'package:flutter/material.dart';

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

  void _spinWheel() {
    if (widget.spinsLeft <= 0 || _isSpinning) return;

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
            // Daily Chances Status Bar
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
                  const Text('Spin daily to win up to 200 free coins', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: (_isSpinning || widget.spinsLeft <= 0) ? null : _spinWheel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00FF87),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isSpinning ? 'SPINNING...' : (widget.spinsLeft > 0 ? 'SPIN NOW' : 'DAILY OVER'),
                        style: const TextStyle(fontWeight: FontWeight.w900),
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
                  const Text('Tap or scratch to reveal mystery rewards', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () {
                      if (widget.scratchLeft > 0 && !_scratchRevealed) {
                        setState(() => _scratchRevealed = true);
                        widget.onScratchWin(45);
                      }
                    },
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
                            : Text(
                                widget.scratchLeft > 0 ? 'TAP TO SCRATCH' : 'TODAY FINISHED',
                                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
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

