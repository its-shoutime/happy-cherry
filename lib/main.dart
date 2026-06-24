import 'package:flutter/material.dart';

import 'game_state.dart';
import 'info_button.dart';
import 'login.dart';
import 'models/pet.dart';
import 'pet_animation.dart';
import 'rename_button.dart';
import 'time_tracker.dart';
import 'user_input.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Happy Cherry',
      theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
      home: isLoggedIn
          ? const HomePage()
          : LoginPage(
              onLogin: () {
                setState(() {
                  isLoggedIn = true;
                });
              },
            ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Pet pet;
  late PetTimeTracker timeTracker;
  bool _isLoading = true;
  bool _showFood = false;
  bool _showStars = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    final loadedPet = await GameState.loadPet();
    setState(() {
      pet = loadedPet ?? Pet(name: "Mochi");
      timeTracker = PetTimeTracker(pet: pet, onTick: _onTick);
      timeTracker.start();
      _isLoading = false;
    });
    await GameState.savePet(pet);
  }

  void _onTick() {
    setState(() {});
    GameState.savePet(pet);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(pet.name),
        centerTitle: true,
        actions: [
          RenameButton(
            pet: pet,
            onRename: (newName) {
              setState(() => pet.name = newName);
              GameState.savePet(pet);
            },
          ),
          InfoButton(pet: pet),
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
                    GameState.savePet(pet);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (!mounted) return;
                      setState(() => _showFood = false);
                    });
                  }
                },
                onPlay: () {
                  if (pet.happiness < 100) {
                    setState(() {
                      pet.play();
                      _showStars = true;
                    });
                    GameState.savePet(pet);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (!mounted) return;
                      setState(() => _showStars = false);
                    });
                  } else {
                    // still play action even if full, keep original behavior
                    setState(() => pet.play());
                    GameState.savePet(pet);
                  }
                },
                onClean: () {
                  setState(() => pet.cleanPoop());
                  GameState.savePet(pet);
                },
                onHeal: () {
                  setState(() => pet.heal());
                  GameState.savePet(pet);
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
