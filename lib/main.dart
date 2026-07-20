import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'audio_manager.dart';
import 'game.dart';
import 'game_state.dart';
import 'info_button.dart';
import 'login.dart';
import 'death.dart';
import 'firebase_options.dart';
import 'models/pet.dart';
import 'pet_animation.dart';
import 'rename_button.dart';
import 'time_tracker.dart';
import 'user_input.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AudioManager.instance.init();
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          }

          return HomePage(userId: user.uid, onLogout: _handleLogout);
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AudioManager.instance.stopBgm();
    await FirebaseAuth.instance.signOut();
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
  bool _isLoading = true;
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
    final loaded = await GameState.loadPet(userId: widget.userId);
    if (!mounted) return;

    timeTracker.stop();
    setState(() {
      if (loaded != null) {
        pet = loaded.pet;
        coins = loaded.coins;
      }
      timeTracker = PetTimeTracker(pet: pet, onTick: _onTick, onDeath: _onDeath);
      timeTracker.start();
      _isLoading = false;
    });
  }

  Future<void> _saveProgress() {
    return GameState.savePet(pet, coins: coins, userId: widget.userId);
  }

  Future<void> _logout() async {
    await _saveProgress();
    await AudioManager.instance.playButton();
    await widget.onLogout();
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
    timeTracker.stop();
    setState(() {
      pet = Pet(name: "Mochi");
      _isDead = false;
      timeTracker = PetTimeTracker(pet: pet, onTick: _onTick, onDeath: _onDeath);
      timeTracker.start();
    });
    _saveProgress();
    AudioManager.instance.playBgm();
  }

  void _abandonPet() {
    AudioManager.instance.playButton();
    final petName = pet.name;
    timeTracker.stop();
    setState(() {
      pet = Pet(name: petName);
      _isDead = false;
      _showFood = false;
      _showStars = false;
      timeTracker = PetTimeTracker(pet: pet, onTick: _onTick, onDeath: _onDeath);
      timeTracker.start();
    });
    // Keep account coins when replacing the pet.
    _saveProgress();
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
          style: pixelBodyText(16, fontWeight: FontWeight.bold).copyWith(
            color: lowHearts ? Colors.red : bodyTextColor,
          ),
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
      return Theme(
        data: AppTheme.light(),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Happy Cherry', style: pixelBodyText(20)),
            centerTitle: true,
          ),
          backgroundColor: AppTheme.backgroundPink,
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
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
      backgroundColor: pet.lightsOff
          ? Colors.black
          : AppTheme.backgroundPink,

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
      MaterialPageRoute(builder: (_) => const CherryCatchGame()),
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
