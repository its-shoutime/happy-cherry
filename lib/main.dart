import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'game.dart';
import 'game_state.dart';
import 'info_button.dart';
import 'login.dart';
import 'death.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/pet.dart';
import 'pet_animation.dart';
import 'rename_button.dart';
import 'time_tracker.dart';
import 'user_input.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Happy Cherry',
      theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
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
  bool _isLoading = true;
  bool _isDead = false;
  bool _showFood = false;
  bool _showStars = false;

  @override
  void initState() {
    super.initState();
    pet = Pet(name: "Mochi");
    _startTimeTracker();
    _loadCachedPet();
    _loadGame();
  }

  void _startTimeTracker() {
    timeTracker = PetTimeTracker(pet: pet, onTick: _onTick);
    timeTracker.start();
  }

  Future<void> _loadCachedPet() async {
    final cachedPet = await GameState.loadCachedPet(userId: widget.userId);
    if (!mounted || cachedPet == null) return;

    timeTracker.stop();
    setState(() {
      pet = cachedPet;
      _startTimeTracker();
    });
  }

  Future<void> _loadGame() async {
    final loadedPet = await GameState.loadPet(userId: widget.userId);
    if (!mounted || loadedPet == null) return;

    timeTracker.stop();
    setState(() {
      pet = loadedPet ?? Pet(name: "Mochi");
      timeTracker = PetTimeTracker(pet: pet, onTick: _onTick, onDeath: _onDeath);
      timeTracker.start();
      _isLoading = false;
    });
  }

  void _onDeath() {
    setState(() {
      _isDead = true;
    });
    // Persist the dead state if desired.
    GameState.savePet(pet);
  }

  void _restartFromDeath() {
    timeTracker.stop();
    setState(() {
      pet = Pet(name: "Mochi");
      _isDead = false;
      timeTracker = PetTimeTracker(pet: pet, onTick: _onTick, onDeath: _onDeath);
      timeTracker.start();
    });
    GameState.savePet(pet);
  }

  void _onTick() {
    setState(() {});
    GameState.savePet(pet, userId: widget.userId);
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

  Color get bodyTextColor => pet.lightsOff ? Colors.black : Colors.white;

  Widget buildHeartMeter(String label, double value, Color textColor) {
    final heartUnits = value / 25.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 18, color: textColor)),

        const SizedBox(height: 5),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            final heartValue = (heartUnits - index).clamp(0.0, 1.0);
            if (heartValue >= 1.0) {
              return const Icon(Icons.favorite, color: Colors.red, size: 28);
            }
            if (heartValue >= 0.5) {
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
        Text("Poop", style: TextStyle(fontSize: 18, color: bodyTextColor)),
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
    // Show attention when there are 2 full hearts or less remaining.
    // Each full heart represents 25 points, so 2 full hearts = 50.
    final lowHearts = pet.hunger <= 50 || pet.happiness <= 50;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (lowHearts) ...[
          Icon(Icons.notification_important, color: Colors.red, size: 30),
          const SizedBox(width: 8),
        ],
        Text(
          lowHearts ? 'Attention needed' : 'All good!',
          style: TextStyle(
            color: lowHearts ? Colors.red : bodyTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildLightsControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Lights', style: TextStyle(fontSize: 16, color: bodyTextColor)),
        Switch(
          value: pet.lightsOff,
          onChanged: (value) {
            setState(() {
              pet.lightsOff = !value;
              if (!pet.hasAttentionCondition) {
                pet.attentionSuppressed = false;
                pet.attentionSeconds = 0;
              }
              GameState.savePet(pet);
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Happy Cherry"), centerTitle: true),
        backgroundColor: const Color.fromARGB(255, 205, 150, 168),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_isDead) {
      return DeathScreen(onRestart: _restartFromDeath);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        centerTitle: true,
        actions: [
          RenameButton(
            pet: pet,
            onRename: (newName) {
              setState(() => pet.name = newName);
              GameState.savePet(pet, userId: widget.userId);
            },
          ),
          InfoButton(pet: pet),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      backgroundColor: pet.lightsOff
          ? Colors.black
          : const Color.fromARGB(255, 205, 150, 168),

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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: bodyTextColor,
                ),
              ),

              const SizedBox(height: 24),

              buildHeartMeter("Hunger", pet.hunger, bodyTextColor),
              buildHeartMeter("Happiness", pet.happiness, bodyTextColor),
              buildAttentionIndicator(),
              const SizedBox(height: 16),
              if (DateTime.now().hour >= 23 || DateTime.now().hour < 8)
                buildLightsControl(),

              const SizedBox(height: 18),

UserActions(
  isSleeping: pet.mood == PetMood.sleeping,
  canHeal: pet.isSick,

  onFeed: () {
    if (pet.hunger < 100) {
      setState(() {
        pet.feed();
        _showFood = true;
      });

      GameState.savePet(pet, userId: widget.userId);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showFood = false);
      });
    }
  },

  onPlay: () async {
    final score = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const CherryCatchGame()),
    );

    if (score != null && score > 3) {
      setState(() {
        if (pet.happiness < 100) {
          _showStars = true;
        }
        pet.play();
      });

      GameState.savePet(pet, userId: widget.userId);

      if (_showStars) {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() => _showStars = false);
        });
      }
    }
  },

  onClean: () {
    setState(() => pet.cleanPoop());
    GameState.savePet(pet, userId: widget.userId);
  },

  onHeal: () {
    setState(() => pet.heal());
    GameState.savePet(pet, userId: widget.userId);
  },
),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
