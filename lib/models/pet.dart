enum PetMood { happy, okay, sad, sleeping, sick }

enum PetType { cat, dog, rabbit, fox }

extension PetTypeDisplay on PetType {
  String get displayName {
    switch (this) {
      case PetType.cat:
        return 'Cat';
      case PetType.dog:
        return 'Dog';
      case PetType.rabbit:
        return 'Rabbit';
      case PetType.fox:
        return 'Fox';
    }
  }
}

class Pet {
  String name;
  PetType type;
  int hunger; // 0 = starving, 100 = full
  int happiness; // 0 = sad, 100 = happy
  int energy; // 0 = tired, 100 = energetic
  int age;
  int xp;

  Pet({
    required this.name,
    this.type = PetType.cat,
    this.hunger = 100,
    this.happiness = 100,
    this.energy = 100,
    this.age = 0,
    this.xp = 0,
  });

  static const Map<PetType, Map<PetMood, String>> _emojiMap = {
    PetType.cat: {
      PetMood.happy: '😺',
      PetMood.okay: '😸',
      PetMood.sad: '😿',
      PetMood.sleeping: '😽',
      PetMood.sick: '🤢',
    },
    PetType.dog: {
      PetMood.happy: '🐶',
      PetMood.okay: '🙂',
      PetMood.sad: '😢',
      PetMood.sleeping: '🐕‍🦺',
      PetMood.sick: '🤒',
    },
    PetType.rabbit: {
      PetMood.happy: '🐰',
      PetMood.okay: '😌',
      PetMood.sad: '😿',
      PetMood.sleeping: '😴',
      PetMood.sick: '🤕',
    },
    PetType.fox: {
      PetMood.happy: '🦊',
      PetMood.okay: '🙂',
      PetMood.sad: '😔',
      PetMood.sleeping: '🌙',
      PetMood.sick: '😷',
    },
  };

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

  String get emoji => _emojiMap[type]![mood]!;

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
