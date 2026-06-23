import 'pet_types.dart';

enum PetMood { happy, okay, sad, sleeping, sick }

extension PetTypeDisplay on PetType {
  String get displayName => name;
}

class Pet {
  String name;
  PetType type;
  PetStage stage;
  int hunger; // 0 = starving, 100 = full
  int happiness; // 0 = sad, 100 = happy
  int ageInMinutes;
  int xp;

  Pet({
    required this.name,
    this.type = blob,
    this.stage = PetStage.baby,
    this.hunger = 100,
    this.happiness = 100,
    this.ageInMinutes = 0,
    this.xp = 0,
  });

  PetMood get mood {
    if (isAsleep) {
      return PetMood.sleeping;
    }

    if (hunger <= 20 || happiness <= 20) {
      return PetMood.sad;
    }

    if (hunger >= 70 && happiness >= 70) {
      return PetMood.happy;
    }

    return PetMood.okay;
  }

  String get feels {
    switch (mood) {
      case PetMood.happy:
        return 'YAY';
      case PetMood.okay:
        return '...';
      case PetMood.sad:
        return '*cries';
      case PetMood.sleeping:
        return 'zzzz';
      case PetMood.sick:
        return 'ouch';
    }
  }

  bool get isAsleep {
    final now = DateTime.now();
    final currentTime = Duration(hours: now.hour, minutes: now.minute);
    if (type.bedtime <= type.waketime) {
      return currentTime >= type.bedtime && currentTime < type.waketime;
    } else {
      return currentTime >= type.bedtime || currentTime < type.waketime;
    }
  }

  bool get isDead => hunger == 0 && happiness == 0;

  String get assetPath => '${type.assetPath}/${mood.name}.png';

  void decayStats() {
    hunger = (hunger - 5).clamp(0, 100);
    happiness = (happiness - 3).clamp(0, 100);
  }

  void feed() {
    hunger = (hunger + 20).clamp(0, 100);
    happiness = (happiness + 5).clamp(0, 100);
  }

  void play() {
    happiness = (happiness + 20).clamp(0, 100);
    hunger = (hunger - 5).clamp(0, 100);
    xp += 5;
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

  void advanceTime(Duration elapsed) {
    if (elapsed.isNegative) return;

    final tickCount = elapsed.inSeconds ~/ 5;
    hunger = (hunger - 5 * tickCount).clamp(0, 100);
    happiness = (happiness - 3 * tickCount).clamp(0, 100);

    ageInMinutes += elapsed.inMinutes;
    evolve();
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type.name,
    'stage': stage.name,
    'hunger': hunger,
    'happiness': happiness,
    'ageInMinutes': ageInMinutes,
    'xp': xp,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    name: json['name'] as String,
    type: blob,
    stage: PetStage.values.byName(json['stage'] as String),
    hunger: json['hunger'] as int,
    happiness: json['happiness'] as int,
    ageInMinutes: json['ageInMinutes'] as int,
    xp: json['xp'] as int,
  );
}
