import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/unity_banner_widget.dart';
import '../services/ad_service.dart';
import '../services/remote_config_service.dart';

class TasksTabScreen extends StatefulWidget {
  final Function(String, int) onCompleteTask;
  final int spinsLeft;
  final int scratchLeft;
  final VoidCallback? onSpinUsed;
  final VoidCallback? onScratchUsed;

  const TasksTabScreen({
    super.key,
    required this.onCompleteTask,
    this.spinsLeft = 3,
    this.scratchLeft = 2,
    this.onSpinUsed,
    this.onScratchUsed,
  });

  @override
  State<TasksTabScreen> createState() => _TasksTabScreenState();
}

class _TasksTabScreenState extends State<TasksTabScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final Map<String, bool> _completed = {};
  late AnimationController _spinController;
  double _wheelAngle = 0;
  bool _spinning = false;
  int _scratchProgress = 0;
  bool _scratchRevealed = false;
  final List<int> _wheelRewards = [20, 2, 5, 0, 3, 1];
  int _cpaleadQualifiedTasks = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _lastTickSlice = -1;
  Completer<void>? _taskReturnCompleter;
  bool _waitingForTaskReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _spinController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
    _listenForCpaleadProgress();
  }

  void _listenForCpaleadProgress() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
      final data = doc.data();
      if (!mounted || data == null) return;
      setState(() {
        _cpaleadQualifiedTasks = (data['cpaleadQualifiedTasks'] as num?)?.toInt() ?? 0;
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spinController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForTaskReturn) {
      _waitingForTaskReturn = false;
      _taskReturnCompleter?.complete();
      _taskReturnCompleter = null;
    }
  }

  Future<void> _waitForTaskReturn() async {
    _waitingForTaskReturn = true;
    _taskReturnCompleter = Completer<void>();
    try {
      await _taskReturnCompleter!.future.timeout(const Duration(minutes: 10));
    } catch (_) {
      _waitingForTaskReturn = false;
      _taskReturnCompleter = null;
    }
  }

  Future<void> _handleTask(String taskId, String title, int coins, String url) async {
    if (_completed[taskId] ?? false) return;

    final config = RemoteConfigService.instance;
    // Social-task flow: LIVE interstitial must finish before the external
    // Instagram/YouTube/Telegram task opens.
    if (config.interstitialEnabled && config.adsEnabled) {
      final adShown = await AdService.instance.showInterstitialAd(context: context);
      if (!adShown) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Live ad is not available right now. Please try again.'),
          ));
        }
        return;
      }
    }

    if (url.trim().isNotEmpty) {
      try {
        await launchUrlString(url.trim(), mode: LaunchMode.externalApplication);
        await _waitForTaskReturn();
      } catch (_) {
        return;
      }
    }

    if (!mounted || (_completed[taskId] ?? false)) return;
    widget.onCompleteTask(title, coins);
    setState(() => _completed[taskId] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 +$coins Coins added for $title'),
        backgroundColor: const Color(0xFF00FF87),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _watchAdAndSpin() {
    if (widget.spinsLeft <= 0 || _spinning) return;
    if (!RemoteConfigService.instance.rewardedSpinEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spin ads are currently disabled.')));
      return;
    }
    AdService.instance.showRewardedAd(
      context: context,
      onReward: _spinWheel,
      onFailed: () {},
    );
  }

  void _spinWheel() {
    if (_spinning) return;
    final index = math.Random().nextInt(_wheelRewards.length);
    final slice = 2 * math.pi / _wheelRewards.length;
    final target = _wheelAngle + (math.pi * 2 * 5) + ((math.pi * 1.5) - (index + 0.5) * slice);
    setState(() => _spinning = true);
    _spinController
      ..reset()
      ..forward().then((_) {
        if (!mounted) return;
        _wheelAngle = target % (math.pi * 2);
        final reward = _wheelRewards[index];
        setState(() => _spinning = false);
        _playWinSound();
        widget.onSpinUsed?.call();
        if (reward >= 20) widget.onCompleteTask('Spin Bonus', reward);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF151922),
            title: Text(reward == 0 ? 'Better Luck!' : (reward >= 20 ? '🎉 +$reward Coins' : 'Bonus Unlocked!')),
            content: Text(reward == 0
                ? 'No bonus this time. Try again when your next spin is available.'
                : (reward >= 20 ? '20 coins have been added to your wallet.' : 'You unlocked a $reward× gameplay bonus.')),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      });
  }

  Future<void> _unlockScratch() async {
    if (widget.scratchLeft <= 0 || _scratchRevealed) return;
    if (!RemoteConfigService.instance.rewardedScratchEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scratch ads are currently disabled.')));
      return;
    }
    AdService.instance.showRewardedAd(
      context: context,
      onReward: () {
        if (!mounted) return;
        setState(() => _scratchRevealed = true);
        _playWinSound();
        widget.onScratchUsed?.call();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Scratch bonus unlocked!'),
          backgroundColor: Color(0xFF00FF87),
          behavior: SnackBarBehavior.floating,
        ));
      },
      onFailed: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B10),
        elevation: 0,
        title: const Text('Tasks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const UnityBannerWidget(),
            const SizedBox(height: 14),
            _bonusSection(),
            const SizedBox(height: 24),
            const Text('🎯 Social Tasks', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF00FF87))));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _empty('No social tasks available right now.');
                final tasks = snapshot.data!.docs.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] != false).toList();
                if (tasks.isEmpty) return _empty('No social tasks available right now.');
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = tasks[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title']?.toString() ?? 'Social Task';
                    final subtitle = (data['subtitle'] ?? data['description'] ?? 'Complete the social task').toString();
                    final coins = (data['coins'] as num?)?.toInt() ?? 25;
                    final url = (data['url'] ?? data['link'] ?? '').toString();
                    final rawPlatform = (data['platform'] ?? '').toString().toLowerCase();
                    final lowerTitle = title.toLowerCase();
                    final platform = rawPlatform.isNotEmpty && rawPlatform != 'social'
                        ? rawPlatform
                        : lowerTitle.contains('instagram') || lowerTitle.contains('follow') ? 'instagram'
                        : lowerTitle.contains('youtube') || lowerTitle.contains('subscribe') ? 'youtube'
                        : lowerTitle.contains('telegram') || lowerTitle.contains('join') ? 'telegram'
                        : 'social';
                    final done = _completed[doc.id] == true;
                    return _socialCard(doc.id, title, subtitle, coins, url, platform, done);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bonusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Expanded(child: Text('🎁 Daily Bonuses', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900))),
          Text('${widget.spinsLeft} spins • ${widget.scratchLeft} scratches', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _spinCard()),
            const SizedBox(width: 10),
            Expanded(child: _scratchCard()),
          ],
        ),
      ],
    );
  }

  Widget _spinCard() {
    final disabled = _cpaleadQualifiedTasks < 1 || widget.spinsLeft <= 0 || _spinning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF00FF87).withOpacity(.20)),
      ),
      child: Column(children: [
        const Icon(Icons.rotate_right_rounded, color: Color(0xFF00FF87), size: 30),
        const SizedBox(height: 5),
        const Text('Spin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        const Text('Watch ad & spin', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 10),
        SizedBox(
          width: 132, height: 132,
          child: Stack(alignment: Alignment.center, children: [
            AnimatedBuilder(
              animation: _spinController,
              builder: (_, __) {
                final angle = _spinning
                    ? _wheelAngle + (math.pi * 2 * 5) * Curves.easeOut.transform(_spinController.value)
                    : _wheelAngle;
                if (_spinning) {
                  final slice = 2 * math.pi / _wheelRewards.length;
                  final tickSlice = ((angle / slice).floor()) % _wheelRewards.length;
                  if (tickSlice != _lastTickSlice) {
                    _lastTickSlice = tickSlice;
                    _playTickSound();
                  }
                } else {
                  _lastTickSlice = -1;
                }
                return Transform.rotate(
                  angle: angle,
                  child: CustomPaint(size: const Size(128, 128), painter: _MiniWheelPainter(_wheelRewards)),
                );
              },
            ),
            const Align(alignment: Alignment.topCenter, child: Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28)),
          ]),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: disabled ? null : _watchAdAndSpin,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black),
            child: Text(disabled ? (widget.spinsLeft == 0 ? 'No Spins' : 'Spinning…') : 'SPIN NOW', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
          ),
        ),
      ]),
    );
  }

  Widget _scratchCard() {
    final canScratch = _cpaleadQualifiedTasks >= 3 && !_scratchRevealed;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111622),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withOpacity(.20)),
      ),
      child: Column(children: [
        const Icon(Icons.confirmation_number_rounded, color: Color(0xFFFFD700), size: 30),
        const SizedBox(height: 5),
        const Text('Scratch', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        const Text('Watch ad & reveal', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 10)),
        const SizedBox(height: 16),
        GestureDetector(
          onPanUpdate: canScratch ? (_) {} : null,
          onTap: canScratch ? _unlockScratch : null,
          child: Container(
            height: 118,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: SizedBox(
                width: double.infinity,
                child: _scratchRevealed
                  ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.card_giftcard_rounded, color: Colors.black87, size: 30),
                      SizedBox(height: 5),
                      Text('BONUS REVEALED', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 12)),
                      Text('Gameplay bonus', style: TextStyle(color: Colors.black54, fontSize: 10)),
                    ])
                  : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.touch_app_rounded, color: Colors.black87, size: 28),
                      SizedBox(height: 4),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('TAP TO WATCH & SCRATCH', textAlign: TextAlign.center, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 11))),
                    ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _socialCard(String id, String title, String subtitle, int coins, String url, String platform, bool done) {
    final logo = _platformLogo(platform);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(17), border: Border.all(color: Colors.white10)),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: Colors.white.withOpacity(.06), borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: logo.isNotEmpty
              ? Image.network(
                  logo,
                  fit: BoxFit.contain,
                  width: 30,
                  height: 30,
                  errorBuilder: (_, __, ___) => Icon(
                    platform.contains('instagram') ? Icons.camera_alt_rounded
                        : platform.contains('youtube') ? Icons.play_circle_fill_rounded
                        : platform.contains('telegram') ? Icons.send_rounded
                        : Icons.public,
                    color: Colors.white54,
                    size: 28,
                  ),
                )
              : const Icon(Icons.public, color: Colors.white54, size: 28),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: done ? null : () => _handleTask(id, title, coins, url),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF87), foregroundColor: Colors.black, disabledBackgroundColor: Colors.white10, disabledForegroundColor: Colors.white30, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9)),
          child: Text(done ? 'DONE' : '+$coins', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
        ),
      ]),
    );
  }

  String _platformLogo(String platform) {
    if (platform.contains('instagram')) return 'https://www.google.com/s2/favicons?domain=instagram.com&sz=128';
    if (platform.contains('youtube')) return 'https://www.google.com/s2/favicons?domain=youtube.com&sz=128';
    if (platform.contains('telegram')) return 'https://www.google.com/s2/favicons?domain=telegram.org&sz=128';
    return '';
  }

  Widget _empty(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF111622), borderRadius: BorderRadius.circular(15)),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 12)),
  );
}

class _MiniWheelPainter extends CustomPainter {
  final List<int> rewards;
  _MiniWheelPainter(this.rewards);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final slice = 2 * math.pi / rewards.length;
    final colors = [const Color(0xFF00FF87), const Color(0xFF6C63FF), const Color(0xFFFFD700), const Color(0xFF303746), const Color(0xFF00C0FF), const Color(0xFFFF6584)];
    for (int i = 0; i < rewards.length; i++) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), i * slice, slice, true, Paint()..color = colors[i % colors.length]);
      final tp = TextPainter(text: TextSpan(text: rewards[i] == 0 ? 'TRY' : 'x${rewards[i]}', style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((i + .5) * slice);
      tp.paint(canvas, Offset(radius * .48, -tp.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(center, 16, Paint()..color = const Color(0xFF0B0E14));
    canvas.drawCircle(center, 11, Paint()..color = Colors.white);
  }
  @override bool shouldRepaint(covariant _MiniWheelPainter oldDelegate) => oldDelegate.rewards != rewards;
}
