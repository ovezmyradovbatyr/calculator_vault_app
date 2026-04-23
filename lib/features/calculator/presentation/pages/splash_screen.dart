import 'dart:math' as math;
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final AnimationController _fadeCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _exitCtrl;

  late final Animation<double> _scale;
  late final Animation<double> _logoFade;
  late final Animation<double> _ring;
  late final Animation<double> _exitFade;

  bool _done = false;

  @override
  void initState() {
    super.initState();

    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scale = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _logoFade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _ring = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
    _exitFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _run();
  }

  Future<void> _run() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeCtrl.forward();
    _scaleCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _ringCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1400));
    _exitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _done = true);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _ringCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    return FadeTransition(
      opacity: _exitFade,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            // Subtle background grid
            CustomPaint(painter: _GridPainter(), size: Size.infinite),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rings + icon
                  AnimatedBuilder(
                    animation: Listenable.merge([_scale, _ring, _logoFade]),
                    builder: (_, __) => SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ring
                          Opacity(
                            opacity: _ring.value,
                            child: Transform.scale(
                              scale: 0.5 + _ring.value * 0.5,
                              child: Container(
                                width: 170,
                                height: 170,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF9F0A,
                                    ).withValues(alpha: 0.25),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Middle ring
                          Opacity(
                            opacity: (_ring.value * 1.4).clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.5 + _ring.value * 0.4,
                              child: Container(
                                width: 130,
                                height: 130,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF9F0A,
                                    ).withValues(alpha: 0.45),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Icon
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _scale,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1C1C1E),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF9F0A,
                                      ).withValues(alpha: 0.35),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App name
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Text(
                      'CALCULATOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Text(
                      '& Secret Vault',
                      style: TextStyle(
                        color: Color(0xFFFF9F0A),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom loading bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: AnimatedBuilder(
                animation: _ring,
                builder: (_, __) => Center(
                  child: SizedBox(
                    width: 140,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(1),
                      child: LinearProgressIndicator(
                        value: _ring.value,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFF9F0A),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Orange accent dots at intersections (sparse)
    final dotPaint = Paint()
      ..color = const Color(0xFFFF9F0A).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final rng = math.Random(42);
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        if (rng.nextDouble() > 0.85) {
          canvas.drawCircle(Offset(x, y), 2, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
