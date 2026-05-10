enum PetMood { happy, okay, sad, sleeping, sick }

class Pet {
  String name;
  int hunger; // 0 = starving, 100 = full
  int happiness; // 0 = sad, 100 = happy
  int energy; // 0 = tired, 100 = energetic
  int age;
  int xp;

  Pet({
    required this.name,
    this.hunger = 100,
    this.happiness = 100,
    this.energy = 100,
    this.age = 0,
    this.xp = 0,
  });

  PetMood get mood {
    if (energy <= 15) {
      return PetMood.sleeping;
    }

    if (hunger <= 20 || happiness <= 20) {
      return PetMood.sad;
    }

    if (hunger >= 70 && happiness >= 70 && energy >= 70) {
      return PetMood.happy;
    }

    return PetMood.okay;
  }

  void decayStats() {
    hunger = (hunger - 5).clamp(0, 100);
    happiness = (happiness - 3).clamp(0, 100);
    energy = (energy - 2).clamp(0, 100);
  }

  void feed() {
    hunger = (hunger + 20).clamp(0, 100);
    happiness = (happiness + 5).clamp(0, 100);
  }

  void play() {
    happiness = (happiness + 20).clamp(0, 100);
    energy = (energy - 10).clamp(0, 100);
    hunger = (hunger - 5).clamp(0, 100);
    xp += 5;
  }

  void sleep() {
    energy = (energy + 30).clamp(0, 100);
  }
}
