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
        poopCount >= 3 ||
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

  bool get isDead => hunger == 0 && happiness == 0;

  static const int _babyToChildAgeMinutes = 60;
  static const int _childToTeenAgeMinutes = 24 * 60;
  static const int _teenToAdultAgeMinutes = 3 * 24 * 60;

  int get _evolutionAgeThresholdMinutes {
    switch (stage) {
      case PetStage.baby:
        return _babyToChildAgeMinutes;
      case PetStage.child:
        return _childToTeenAgeMinutes;
      case PetStage.teen:
        return _teenToAdultAgeMinutes;
      case PetStage.adult:
        return -1;
    }
  }

  bool get canEvolve =>
      stage != PetStage.adult && ageInMinutes >= _evolutionAgeThresholdMinutes;

  void maybeEvolve() {
    while (canEvolve) {
      evolve();
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

  static const int _poopIntervalSeconds = 4 * 60 * 60;
  static const int _sickAfterFullPoopSeconds = 4 * 60 * 60;

  void advancePoopTimer(Duration elapsed) {
    if (elapsed.isNegative) return;

    secondsSinceLastPoop += elapsed.inSeconds;

    while (secondsSinceLastPoop >= _poopIntervalSeconds && poopCount < 3) {
      secondsSinceLastPoop -= _poopIntervalSeconds;
      poopCount += 1;
    }

    if (poopCount >= 3 && secondsSinceLastPoop >= _sickAfterFullPoopSeconds) {
      isSick = true;
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
    switch (stage) {
      case PetStage.baby:
        type = careMistakes < 1 ? sprout : squeaky;
        stage = PetStage.child;
        break;
      case PetStage.child:
        if (careMistakes < 2) {
          type = starfruit;
        } else if (careMistakes >= 3 && careMistakes <= 4) {
          type = mousse;
        } else {
          type = lloyd;
        }
        stage = PetStage.teen;
        break;
      case PetStage.teen:
        if (type == starfruit) {
          if (careMistakes == 0) {
            type = cherry;
          } else if (careMistakes >= 1 && careMistakes <= 3) {
            type = flower;
          } else {
            type = angel;
          }
          stage = PetStage.adult;
        } else if (type == lloyd) {
          if (careMistakes >= 10) {
            type = demon;
            stage = PetStage.adult;
          } else if (careMistakes >= 3 && careMistakes <= 6) {
            type = puffaloo;
            stage = PetStage.adult;
          } else if (careMistakes >= 7) {
            type = bear;
            stage = PetStage.adult;
          }
        } else if (type == mousse) {
          if (careMistakes >= 3 && careMistakes <= 6) {
            type = puffaloo;
            stage = PetStage.adult;
          } else if (careMistakes >= 7) {
            type = bear;
            stage = PetStage.adult;
          }
        }
        break;
      case PetStage.adult:
        break;
    }
  }

  void advanceTime(Duration elapsed) {
    if (elapsed.isNegative) return;

    decayStats(elapsed);

    ageInMinutes += elapsed.inMinutes;
    maybeEvolve();
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
