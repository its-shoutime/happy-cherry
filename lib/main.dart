import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

import 'app_theme.dart';
import 'audio_manager.dart';
import 'death.dart';
import 'firebase_options.dart';
import 'game.dart';
import 'game_state.dart';
import 'hatch_screen.dart';
import 'info_button.dart';
import 'loading_screen.dart';
import 'login.dart';
import 'models/pet.dart';
import 'pet_animation.dart';
import 'rename_button.dart';
import 'shop_page.dart';
import 'time_tracker.dart';
import 'user_input.dart';
import 'wardrobe_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Happy Cherry',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<void> _startupFuture = _initialize();

  Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      await FirebaseFirestore.instance.enableNetwork();
    } catch (error, stackTrace) {
      // Don't block startup if persistence settings fail on a given platform.
      debugPrint('Firestore setup warning: $error\n$stackTrace');
    }
    await AudioManager.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LoadingScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.backgroundPink,
            body: Center(
              child: Text(
                'Failed to start Happy Cherry.',
                style: AppTheme.pixelText(
                  fontSize: 18,
                  color: AppTheme.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            final user = snapshot.data;
            if (user == null) {
              return const LoginPage();
            }

            return HomePage(userId: user.uid, onLogout: _handleLogout);
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    await AudioManager.instance.stopBgm();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error, stackTrace) {
      debugPrint('Error during sign out: $error\n$stackTrace');
    }
  }
}

class HomePage extends StatefulWidget {
  final String userId;
  final Future<void> Function() onLogout;

  const HomePage({super.key, required this.userId, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Pet pet;
  late PetTimeTracker timeTracker;
  int coins = 0;
  Set<String> ownedAccessories = {};
  bool _isLoading = true;
  bool _loadFailed = false;
  String _loadErrorMessage = '';
  bool _isHatching = false;
  bool _isDead = false;
  bool _showFood = false;
  bool _showStars = false;
  bool _muted = AudioManager.instance.muted;

  @override
  void initState() {
    super.initState();
    pet = Pet(name: "Mochi");
    timeTracker = PetTimeTracker(pet: pet, onTick: _onTick, onDeath: _onDeath);
    _loadGame();
    AudioManager.instance.playBgm();
  }

  Future<void> _loadGame() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
      _loadErrorMessage = '';
    });

    try {
      // Warm the auth token if possible, but never block gameplay on it.
      try {
        await FirebaseAuth.instance.currentUser?.getIdToken();
      } catch (error) {
        debugPrint('Auth token warm-up failed: $error');
      }

      final loaded = await GameState.loadPet(userId: widget.userId);
      if (!mounted) return;

      timeTracker.stop();
      setState(() {
        if (loaded != null) {
          pet = loaded.pet;
          coins = loaded.coins;
          ownedAccessories = {...loaded.ownedAccessories};
          timeTracker = PetTimeTracker(
            pet: pet,
            onTick: _onTick,
            onDeath: _onDeath,
          );
          timeTracker.start();
          _isHatching = false;
        } else {
          // Brand-new account (or no reachable save): hatch a baby.
          pet = Pet(name: "Mochi");
          ownedAccessories = {};
          timeTracker = PetTimeTracker(
            pet: pet,
            onTick: _onTick,
            onDeath: _onDeath,
          );
          _isHatching = true;
        }
        _isLoading = false;
        _loadFailed = false;
        _loadErrorMessage = '';
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to load progress: $error\n$stackTrace');
      if (!mounted) return;
      timeTracker.stop();
      setState(() {
        _isLoading = false;
        _loadFailed = true;
        _isHatching = false;
        _loadErrorMessage = _describeLoadError(error);
      });
    }
  }

  String _describeLoadError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'Cloud save permission was denied. Check Firestore rules, then retry.';
    }
    if (text.contains('unavailable') || text.contains('failed-precondition')) {
      return 'Cloud save is offline or unavailable right now.';
    }
    if (text.contains('network')) {
      return 'Network error while loading your cloud save.';
    }
    return 'Could not reach your cloud save.';
  }

  Future<void> _backFromLoadFailure() async {
    AudioManager.instance.playButton();
    timeTracker.stop();
    await widget.onLogout();
  }

  void _beginNewBaby({required String name}) {
    timeTracker.stop();
    setState(() {
      // Keep account coins + owned clothing; new baby starts unequipped.
      pet = Pet(name: name);
      _isDead = false;
      _showFood = false;
      _showStars = false;
      _isHatching = true;
      timeTracker = PetTimeTracker(
        pet: pet,
        onTick: _onTick,
        onDeath: _onDeath,
      );
    });
  }

  void _onHatchComplete() {
    if (!mounted) return;
    setState(() {
      _isHatching = false;
      timeTracker = PetTimeTracker(
        pet: pet,
        onTick: _onTick,
        onDeath: _onDeath,
      );
      timeTracker.start();
    });
    unawaited(_saveProgress());
  }

  Future<void> _saveProgress() {
    return GameState.savePet(
      pet,
      coins: coins,
      ownedAccessories: ownedAccessories.toList()..sort(),
      userId: widget.userId,
    );
  }

  Future<void> _logout() async {
    timeTracker.stop();
    AudioManager.instance.playButton();
    // Don't let a slow/hung Firestore write block sign-out.
    try {
      await _saveProgress().timeout(const Duration(seconds: 3));
    } catch (_) {}
    await widget.onLogout();
  }

  Future<void> _openShop() async {
    if (!mounted) return;
    await AudioManager.instance.playButton();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShopPage(
          pet: pet,
          coins: coins,
          ownedAccessories: ownedAccessories,
          onCoinsChanged: (value) {
            setState(() => coins = value);
            unawaited(_saveProgress());
          },
          onOwnedChanged: (owned) {
            setState(() => ownedAccessories = {...owned});
            unawaited(_saveProgress());
          },
        ),
      ),
    );
  }

  Future<void> _openWardrobe() async {
    if (!mounted) return;
    await AudioManager.instance.playButton();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WardrobePage(
          pet: pet,
          ownedAccessories: ownedAccessories,
          onAccessorySelected: (accessory) {
            setState(() {
              pet.accessory = accessory;
            });
            unawaited(_saveProgress());
          },
        ),
      ),
    );
  }

  Future<void> _toggleMute() async {
    await AudioManager.instance.toggleMute();
    if (!mounted) return;
    setState(() => _muted = AudioManager.instance.muted);
  }

  void _onDeath() {
    AudioManager.instance.pauseBgm();
    AudioManager.instance.playDeath();
    setState(() {
      _isDead = true;
    });
    _saveProgress();
  }

  void _restartFromDeath() {
    AudioManager.instance.playButton();
    _beginNewBaby(name: 'Mochi');
    AudioManager.instance.playBgm();
  }

  void _abandonPet() {
    AudioManager.instance.playButton();
    _beginNewBaby(name: pet.name);
  }

  void _onTick() {
    setState(() {});
    _saveProgress();
  }

  @override
  void dispose() {
    timeTracker.stop();
    super.dispose();
  }

  Widget buildPetGraphic() {
    return PetGraphic(
      pet: pet,
      height: 200,
      showFood: _showFood,
      showStars: _showStars,
    );
  }

  Color get bodyTextColor =>
      pet.lightsOff ? AppTheme.textLight : AppTheme.textDark;

  TextStyle pixelBodyText(double fontSize, {FontWeight? fontWeight}) {
    return AppTheme.pixelText(
      fontSize: fontSize,
      color: bodyTextColor,
      shadowColor: pet.lightsOff ? const Color(0x80000000) : null,
    ).copyWith(fontWeight: fontWeight);
  }

  Widget buildHeartMeter(String label, double value) {
    // 1 unit = half a heart. Use ceil so a segment stays filled until that
    // whole half-heart has been lost (avoids dropping immediately after refill).
    final halfHearts = value <= 0
        ? 0
        : value.ceil().clamp(0, Pet.maxStat.toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: pixelBodyText(18)),

        const SizedBox(height: 5),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final unitsInHeart = (halfHearts - index * 2).clamp(0, 2);
            if (unitsInHeart >= 2) {
              return const Icon(Icons.favorite, color: Colors.red, size: 28);
            }
            if (unitsInHeart >= 1) {
              return buildHalfHeart();
            }
            return const Icon(
              Icons.favorite_border,
              color: Colors.red,
              size: 28,
            );
          }),
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildHalfHeart() {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        const Icon(Icons.favorite_border, color: Colors.red, size: 28),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 0.5,
            child: const Icon(Icons.favorite, color: Colors.red, size: 28),
          ),
        ),
      ],
    );
  }

  Widget buildPoopDisplay() {
    if (pet.poopCount <= 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Poop", style: pixelBodyText(18)),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(pet.poopCount, (index) {
            return const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('💩', style: TextStyle(fontSize: 28)),
            );
          }),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget buildAttentionIndicator() {
    // Show attention when there are 2 full hearts or fewer remaining (≤ 4).
    final lowHearts = pet.hunger <= 4 || pet.happiness <= 4;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lowHearts) ...[
          Icon(Icons.notification_important, color: Colors.red, size: 30),
          const SizedBox(width: 8),
        ],
        Text(
          lowHearts ? 'Attention needed' : 'All good!',
          style: pixelBodyText(
            16,
            fontWeight: FontWeight.bold,
          ).copyWith(color: lowHearts ? Colors.red : bodyTextColor),
        ),
      ],
    );
  }

  Widget buildLightsControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Lights', style: pixelBodyText(16)),
        Switch(
          value: !pet.lightsOff,
          onChanged: (lightsOn) {
            setState(() {
              pet.lightsOff = !lightsOn;
              if (!pet.hasAttentionCondition) {
                pet.attentionSuppressed = false;
                pet.attentionSeconds = 0;
              }
            });
            _saveProgress();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }
    if (_loadFailed) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPink,
        appBar: AppBar(
          backgroundColor: AppTheme.appBarPink,
          foregroundColor: AppTheme.textDark,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back to login',
            onPressed: () => unawaited(_backFromLoadFailure()),
          ),
          title: Text(
            'Load failed',
            style: AppTheme.pixelText(fontSize: 18, color: AppTheme.textDark),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load your progress.',
                    textAlign: TextAlign.center,
                    style: AppTheme.pixelText(
                      fontSize: 20,
                      color: AppTheme.textDark,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _loadErrorMessage.isEmpty
                        ? 'Check your connection and try again.'
                        : _loadErrorMessage,
                    textAlign: TextAlign.center,
                    style: AppTheme.pixelText(
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your cloud save was not overwritten.\n'
                    'Retry again, or go back to login.',
                    textAlign: TextAlign.center,
                    style: AppTheme.pixelText(
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  PixelButton(
                    logicalWidth: 36,
                    logicalHeight: 12,
                    width: 180,
                    pressChildOffset: const Offset(0, 1),
                    onPressed: () {
                      AudioManager.instance.playButton();
                      unawaited(_loadGame());
                    },
                    semanticsLabel: 'Retry',
                    child: Text(
                      'Retry',
                      style: AppTheme.buttonLabel(AppTheme.textDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PixelButton(
                    logicalWidth: 36,
                    logicalHeight: 12,
                    width: 180,
                    pressChildOffset: const Offset(0, 1),
                    onPressed: () => unawaited(_backFromLoadFailure()),
                    semanticsLabel: 'Back to login',
                    child: Text(
                      'Back',
                      style: AppTheme.buttonLabel(AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_isHatching) {
      return HatchScreen(onComplete: _onHatchComplete);
    }
    if (_isDead) {
      return DeathScreen(onRestart: _restartFromDeath);
    }

    return Theme(
      data: AppTheme.forLightsOff(pet.lightsOff),
      child: Scaffold(
        appBar: AppBar(
          title: Text(pet.name, style: pixelBodyText(20)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              tooltip: _muted ? 'Unmute' : 'Mute',
              onPressed: _toggleMute,
            ),
            RenameButton(
              pet: pet,
              onRename: (newName) {
                setState(() => pet.name = newName);
                _saveProgress();
              },
            ),
            InfoButton(
              pet: pet,
              coins: coins,
              lightsOff: pet.lightsOff,
              onAbandon: _abandonPet,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        backgroundColor: pet.lightsOff ? Colors.black : AppTheme.backgroundPink,

        body: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // top spacing
                const SizedBox(height: 20),

                // pet graphic
                Center(child: buildPetGraphic()),

                const SizedBox(height: 20),

                // pet mood
                Text(
                  pet.feels,
                  textAlign: TextAlign.center,
                  style: pixelBodyText(22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 24),

                buildHeartMeter("Hunger", pet.hunger),
                buildHeartMeter("Happiness", pet.happiness),
                buildAttentionIndicator(),
                const SizedBox(height: 16),
                buildLightsControl(),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PixelButton(
                      logicalWidth: 28,
                      logicalHeight: 12,
                      width: 140,
                      pressChildOffset: const Offset(0, 1),
                      onPressed: _openShop,
                      semanticsLabel: 'Shop',
                      child: Text(
                        'Shop',
                        style: AppTheme.buttonLabel(AppTheme.textDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    PixelButton(
                      logicalWidth: 28,
                      logicalHeight: 12,
                      width: 140,
                      pressChildOffset: const Offset(0, 1),
                      onPressed: _openWardrobe,
                      semanticsLabel: 'Wardrobe',
                      child: Text(
                        'Wardrobe',
                        style: AppTheme.buttonLabel(AppTheme.textDark),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                UserActions(
                  isSleeping: pet.mood == PetMood.sleeping,
                  canHeal: pet.isSick,

                  onFeed: () {
                    if (pet.hunger < Pet.maxStat) {
                      AudioManager.instance.playFeed();
                      setState(() {
                        pet.feed();
                        _showFood = true;
                      });

                      _saveProgress();

                      Future.delayed(const Duration(seconds: 2), () {
                        if (!mounted) return;
                        setState(() => _showFood = false);
                      });
                    }
                  },

                  onPlay: () async {
                    AudioManager.instance.playButton();
                    final score = await Navigator.of(context).push<int>(
                      MaterialPageRoute(
                        builder: (_) => CherryCatchGame(userId: widget.userId),
                      ),
                    );

                    if (!mounted) return;
                    AudioManager.instance.playBgm();

                    if (score == null) return;

                    setState(() {
                      coins += score;
                      if (score > 0) {
                        AudioManager.instance.playCoin();
                      }
                      if (score > 3) {
                        if (pet.happiness < Pet.maxStat) {
                          _showStars = true;
                        }
                        pet.play();
                      }
                    });

                    _saveProgress();

                    if (_showStars) {
                      Future.delayed(const Duration(seconds: 2), () {
                        if (!mounted) return;
                        setState(() => _showStars = false);
                      });
                    }
                  },

                  onClean: () {
                    AudioManager.instance.playClean();
                    setState(() => pet.cleanPoop());
                    _saveProgress();
                  },

                  onHeal: () {
                    AudioManager.instance.playHeal();
                    setState(() => pet.heal());
                    _saveProgress();
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
