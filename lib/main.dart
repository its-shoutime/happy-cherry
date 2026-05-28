import 'package:flutter/material.dart';
import 'models/pet.dart';
import 'pet_animation.dart';
import 'user_input.dart';
import 'time_tracker.dart';

void main() {
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Pet pet = Pet(name: "Mochi", type: PetType.blob);

  late PetTimeTracker timeTracker;

  @override
  void initState() {
    super.initState();

    timeTracker = PetTimeTracker(pet: pet, onTick: () => setState(() {}));
    timeTracker.start();
  }

  @override
  void dispose() {
    timeTracker.stop();
    super.dispose();
  }

  Widget buildPetGraphic() {
    return PetGraphic(pet: pet, height: 200);
  }

  String getPetFeels() {
    switch (pet.mood) {
      case PetMood.happy:
        return "YAY";

      case PetMood.okay:
        return "...";

      case PetMood.sad:
        return "*cries";

      case PetMood.sleeping:
        return "zzzz";

      case PetMood.sick:
        return "ouch";
    }
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
      appBar: AppBar(title: Text("${pet.name}"), centerTitle: true),
      backgroundColor: const Color.fromARGB(255, 205, 150, 168),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            buildPetGraphic(),

            const SizedBox(height: 20),

            Text(
              getPetFeels(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 40),

            buildStatBar("Hunger", pet.hunger),
            buildStatBar("Happiness", pet.happiness),
            buildStatBar("Energy", pet.energy),

            const Spacer(),

            UserActions(
              onFeed: () => setState(() => pet.feed()),
              onPlay: () => setState(() => pet.play()),
              onSleep: () => setState(() => pet.sleep()),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
