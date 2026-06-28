import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'game_state.dart';
import 'info_button.dart';
import 'login.dart';
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
      pet = loadedPet;
      _startTimeTracker();
    });
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
                GameState.savePet(pet, userId: widget.userId);
              },
              onPlay: () {
                setState(() => pet.play());
                GameState.savePet(pet, userId: widget.userId);
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
