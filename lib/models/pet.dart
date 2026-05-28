enum PetMood { happy, okay, sad, sleeping, sick }

enum PetType { blob }

enum PetStage { baby, child, teen, adult }

extension PetTypeDisplay on PetType {
  String get displayName {
    switch (this) {
      case PetType.blob:
        return 'Blob';
    }
  }
}

class Pet {
  String name;
  PetType type;
  PetStage stage;
  int hunger; // 0 = starving, 100 = full
  int happiness; // 0 = sad, 100 = happy
  int energy; // 0 = tired, 100 = energetic
  int ageInMinutes;
  int xp;

  Pet({
    required this.name,
    this.type = PetType.blob,
    this.stage = PetStage.baby,
    this.hunger = 100,
    this.happiness = 100,
    this.energy = 100,
    this.ageInMinutes = 0,
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

  String get assetPath => 'assets/pets/${type.name}/${mood.name}.png';

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

  void evolve() {
    if (ageInMinutes >= 60 && stage == PetStage.baby) {
      stage = PetStage.child;
    } else if (ageInMinutes >= 1440 && stage == PetStage.child) {
      stage = PetStage.teen;
    } else if (ageInMinutes >= 4320 && stage == PetStage.teen) {
      stage = PetStage.adult;
    }
  }
}
