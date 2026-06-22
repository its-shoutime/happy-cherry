import 'package:flutter/material.dart';
import 'models/pet.dart';
import 'pet_animation.dart';
import 'user_input.dart';
import 'time_tracker.dart';
import 'game_state.dart';
import 'info_button.dart';
import 'rename_button.dart';
import 'login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    return PetGraphic(pet: pet, height: 200);
  }

  Widget buildStatBar(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: $value", style: const TextStyle(fontSize: 18)),

        const SizedBox(height: 5),

        SizedBox(
          width: 150,
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 5,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(height: 20),
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
      backgroundColor: const Color.fromARGB(255, 205, 150, 168),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            buildPetGraphic(),

            const SizedBox(height: 20),

            Text(
              pet.feels,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            buildStatBar("Hunger", pet.hunger),
            buildStatBar("Happiness", pet.happiness),

            const Spacer(),

            UserActions(
              isSleeping: pet.mood == PetMood.sleeping,
              onFeed: () {
                setState(() => pet.feed());
                GameState.savePet(pet);
              },
              onPlay: () {
                setState(() => pet.play());
                GameState.savePet(pet);
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
