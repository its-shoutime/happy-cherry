import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Full-screen egg hatch intro shown when a brand-new baby pet is created.
class HatchScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final Duration duration;

  const HatchScreen({
    super.key,
    required this.onComplete,
    this.duration = const Duration(seconds: 10),
  });

  static const String eggAssetPath = 'assets/pets/egg/egg.png';

  @override
  State<HatchScreen> createState() => _HatchScreenState();
}

class _HatchScreenState extends State<HatchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _progressController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward().whenComplete(_finish);
  }

  void _finish() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onComplete();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPink,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The egg is hatching...',
                  textAlign: TextAlign.center,
                  style: AppTheme.pixelText(
                    fontSize: 22,
                    color: AppTheme.textDark,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _shakeController,
                    _progressController,
                  ]),
                  builder: (context, child) {
                    final intensity = 0.35 + _progressController.value * 0.65;
                    final wobble = (_shakeController.value * 2) - 1;
                    final angle = wobble * 0.18 * intensity;
                    final dx = wobble * 10 * intensity;

                    return Transform.translate(
                      offset: Offset(dx, sin(_shakeController.value * pi) * 2),
                      child: Transform.rotate(angle: angle, child: child),
                    );
                  },
                  child: Image.asset(
                    HatchScreen.eggAssetPath,
                    height: 200,
                    filterQuality: FilterQuality.none,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Something cute is about to appear!',
                  textAlign: TextAlign.center,
                  style: AppTheme.pixelText(
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
