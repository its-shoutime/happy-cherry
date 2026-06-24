import 'pet_types.dart';

enum PetMood { happy, okay, sad, sleeping, sick }

extension PetTypeDisplay on PetType {
  String get displayName => name;
}

class Pet {
  String name;
  PetType type;
  PetStage stage;
  double hunger; // 0 = starving, 100 = full
  double happiness; // 0 = sad, 100 = happy
  int ageInMinutes;
  int xp;
  int poopCount;
  int secondsSinceLastPoop;
  bool isSick;
  bool lightsOff;
  int careMistakes;
  int attentionSeconds;
  bool attentionSuppressed;

  Pet({
    required this.name,
    this.type = blob,
    this.stage = PetStage.baby,
    this.hunger = 100.0,
    this.happiness = 100.0,
    this.ageInMinutes = 0,
    this.xp = 0,
    this.poopCount = 0,
    this.secondsSinceLastPoop = 0,
    this.isSick = false,
    this.lightsOff = false,
    this.careMistakes = 0,
    this.attentionSeconds = 0,
    this.attentionSuppressed = false,
  });

  PetMood get mood {
    if (isSick) {
      return PetMood.sick;
    }

    if (isAsleep) {
      return PetMood.sleeping;
    }

    if (secondsSinceLastPoop >= 120 && poopCount >= 3) {
      return PetMood.sick;
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
    if (type.bedTime <= type.wakeTime) {
      return currentTime >= type.bedTime && currentTime < type.wakeTime;
    } else {
      return currentTime >= type.bedTime || currentTime < type.wakeTime;
    }
  }

  bool get hasAttentionCondition {
    return hunger <= 0 ||
        happiness <= 0 ||
        poopCount > 0 ||
        (isAsleep && !lightsOff);
  }

  bool get attentionVisible {
    return hasAttentionCondition && !attentionSuppressed;
  }

  void updateAttention(Duration elapsed) {
    if (elapsed.isNegative) return;

    if (hasAttentionCondition) {
      if (attentionSuppressed) {
        return;
      }
      attentionSeconds += elapsed.inSeconds;
      if (attentionSeconds >= 15 * 60) {
        attentionSuppressed = true;
        careMistakes += 1;
        attentionSeconds = 0;
      }
    } else {
      attentionSuppressed = false;
      attentionSeconds = 0;
    }
  }

  String get assetPath => '${type.assetPath}/${mood.name}.png';

  double get hungerDecayRatePerMinute {
    switch (stage) {
      case PetStage.baby:
        return 0.5 / 10; // 0.05 per minute
      case PetStage.child:
        return 0.5 / 20; // 0.025 per minute
      case PetStage.teen:
        return 0.5 / 30; // 0.0167 per minute
      case PetStage.adult:
        return 0.5 / 60; // 0.0083 per minute
    }
  }

  double get happinessDecayRatePerMinute {
    switch (stage) {
      case PetStage.baby:
        return 0.5 / 10; // 0.05 per minute
      case PetStage.child:
        return 0.5 / 20; // 0.025 per minute
      case PetStage.teen:
        return 0.5 / 30; // 0.0167 per minute
      case PetStage.adult:
        return 0.5 / 60; // 0.0083 per minute
    }
  }

  void advancePoopTimer(Duration elapsed) {
    if (elapsed.isNegative) return;

    if (poopCount >= 3) {
      secondsSinceLastPoop = 120;
      if (!isSick) {
        isSick = true;
      }
      return;
    }

    secondsSinceLastPoop += elapsed.inSeconds;
    while (secondsSinceLastPoop >= 120 && poopCount < 3) {
      poopCount += 1;
      secondsSinceLastPoop -= 120;
    }

    if (poopCount >= 3 && !isSick) {
      isSick = true;
      secondsSinceLastPoop = 120;
    }
  }

  void decayStats([Duration elapsed = const Duration(seconds: 5)]) {
    final minutes = elapsed.inSeconds / 60.0;
    hunger = (hunger - hungerDecayRatePerMinute * minutes).clamp(0.0, 100.0);
    happiness = (happiness - happinessDecayRatePerMinute * minutes).clamp(
      0.0,
      100.0,
    );
    advancePoopTimer(elapsed);
    updateAttention(elapsed);
  }

  void feed() {
    hunger = (hunger + 20).clamp(0.0, 100.0);
  }

  void play() {
    happiness = (happiness + 20).clamp(0.0, 100.0);
    hunger = (hunger - 5).clamp(0.0, 100.0);
    xp += 5;
  }

  void cleanPoop() {
    poopCount = 0;
    secondsSinceLastPoop = 0;
    if (!hasAttentionCondition) {
      attentionSuppressed = false;
      attentionSeconds = 0;
    }
  }

  void heal() {
    isSick = false;
    if (!hasAttentionCondition) {
      attentionSuppressed = false;
      attentionSeconds = 0;
    }
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

  void advanceTime(Duration elapsed, {bool lightsOff = false}) {
    if (elapsed.isNegative) return;

    this.lightsOff = !lightsOff;
    decayStats(elapsed);

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
    'poopCount': poopCount,
    'secondsSinceLastPoop': secondsSinceLastPoop,
    'isSick': isSick,
    'lightsOff': lightsOff,
    'careMistakes': careMistakes,
    'attentionSeconds': attentionSeconds,
    'attentionSuppressed': attentionSuppressed,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    name: json['name'] as String,
    type: petTypeFromName(json['type'] as String?),
    stage: PetStage.values.byName(json['stage'] as String),
    hunger: (json['hunger'] as num).toDouble(),
    happiness: (json['happiness'] as num).toDouble(),
    ageInMinutes: json['ageInMinutes'] as int,
    xp: json['xp'] as int,
    poopCount: json['poopCount'] as int? ?? 0,
    secondsSinceLastPoop: json['secondsSinceLastPoop'] as int? ?? 0,
    isSick: json['isSick'] as bool? ?? false,
    lightsOff: json['lightsOff'] as bool? ?? false,
    careMistakes: json['careMistakes'] as int? ?? 0,
    attentionSeconds: json['attentionSeconds'] as int? ?? 0,
    attentionSuppressed: json['attentionSuppressed'] as bool? ?? false,
  );
}
