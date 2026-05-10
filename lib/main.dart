import 'dart:async';
import 'package:flutter/material.dart';
import 'models/pet.dart';

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
  final Pet pet = Pet(name: "Mochi");

  Timer? timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() {
        pet.decayStats();
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String getPetEmoji() {
    switch (pet.mood) {
      case PetMood.happy:
        return "😄";

      case PetMood.okay:
        return "🙂";

      case PetMood.sad:
        return "😭";

      case PetMood.sleeping:
        return "😴";

      case PetMood.sick:
        return "🤒";
    }
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

            Text(getPetEmoji(), style: const TextStyle(fontSize: 120)),

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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      pet.feed();
                    });
                  },
                  child: const Text("Feed"),
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      pet.play();
                    });
                  },
                  child: const Text("Play"),
                ),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      pet.sleep();
                    });
                  },
                  child: const Text("Sleep"),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
