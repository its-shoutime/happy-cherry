import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'models/pet.dart';
import 'models/pet_types.dart';
import 'pet_animation.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _FloatingCharm {
  final double x;
  final double y;
  final double size;
  final double phase;
  final IconData icon;
  final Color color;

  const _FloatingCharm({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.icon,
    required this.color,
  });
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Waking up your cherry...',
    'Preparing breakfast...',
    'Cleaning the room...',
    'Getting everything ready...',
  ];

  static const _charms = [
    _FloatingCharm(
      x: 0.12,
      y: 0.16,
      size: 24,
      phase: 0,
      icon: Icons.local_florist,
      color: Color(0xFFF18EB8),
    ),
    _FloatingCharm(
      x: 0.75,
      y: 0.10,
      size: 18,
      phase: 1.3,
      icon: Icons.favorite,
      color: Color(0xFFDB86A0),
    ),
    _FloatingCharm(
      x: 0.88,
      y: 0.42,
      size: 20,
      phase: 2.1,
      icon: Icons.local_florist,
      color: Color(0xFFFFC1D6),
    ),
    _FloatingCharm(
      x: 0.24,
      y: 0.62,
      size: 22,
      phase: 3.2,
      icon: Icons.favorite,
      color: Color(0xFFF6A8C7),
    ),
    _FloatingCharm(
      x: 0.55,
      y: 0.78,
      size: 16,
      phase: 4.0,
      icon: Icons.local_florist,
      color: Color(0xFFFFD5E6),
    ),
  ];

  late final AnimationController _animationController;
  late final Timer _messageTimer;
  int _messageIndex = 0;
  final Pet _loadingPet = Pet(
    name: 'Cherry',
    type: cherry,
    stage: PetStage.adult,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _messageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = _messages[_messageIndex];
    return Scaffold(
      backgroundColor: AppTheme.backgroundPink,
      body: SafeArea(
        child: Stack(
          children: [
            _FloatingBackground(controller: _animationController),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Happy Cherry',
                      textAlign: TextAlign.center,
                      style: AppTheme.pixelText(
                        fontSize: 32,
                        color: AppTheme.textDark,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTheme.pixelText(
                        fontSize: 16,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Transform.translate(
                      offset: Offset(
                        0,
                        sin(_animationController.value * 2 * pi) * 14,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 190,
                              child: PetGraphic(pet: _loadingPet, height: 190),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'A cozy world is waking up...',
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
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: AppTheme.buttonDisabledFill,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.buttonFill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBackground extends StatelessWidget {
  final Animation<double> controller;

  const _FloatingBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: _LoadingScreenState._charms.map((charm) {
                final offset =
                    sin((controller.value * 2 * pi) + charm.phase) * 8;
                return Positioned(
                  left: charm.x * constraints.maxWidth,
                  top: charm.y * constraints.maxHeight + offset,
                  child: Icon(
                    charm.icon,
                    color: charm.color.withValues(alpha: 0.92),
                    size: charm.size,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
