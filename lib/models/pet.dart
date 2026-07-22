import 'pet_types.dart';

enum PetMood { happy, okay, sad, sleeping, sick }

extension PetTypeDisplay on PetType {
  String get displayName => name;
}

class Pet {
  static const double maxStat = 8.0;

  String name;
  PetType type;
  PetStage stage;
  double hunger; // 0 = starving, 8 = full (1 unit = half a heart)
  double happiness; // 0 = sad, 8 = happy (1 unit = half a heart)
  int ageInMinutes;
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
    this.hunger = maxStat,
    this.happiness = maxStat,
    this.ageInMinutes = 0,
    this.poopCount = 0,
    this.secondsSinceLastPoop = 0,
    this.isSick = false,
    this.lightsOff = false,
    this.careMistakes = 0,
    this.attentionSeconds = 0,
    this.attentionSuppressed = false,
  });

  PetMood get mood => moodAt(DateTime.now());

  PetMood moodAt(DateTime now) {
    if (isSick) {
      return PetMood.sick;
    }

    if (isAsleepAt(now)) {
      return PetMood.sleeping;
    }

    // Sad at 2 half-hearts or fewer.
    if (hunger <= 2 || happiness <= 2) {
      return PetMood.sad;
    }

    // Happy when meters look full. Heart UI uses ceil, so a half-heart stays
    // filled until that whole unit is lost (e.g. 7.1 still shows as full).
    if (_isVisuallyFull(hunger) && _isVisuallyFull(happiness)) {
      return PetMood.happy;
    }

    return PetMood.okay;
  }

  /// Matches [buildHeartMeter]: a segment stays filled until fully depleted.
  static bool _isVisuallyFull(double value) {
    if (value <= 0) return false;
    return value.ceil() >= maxStat;
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

  bool get isAsleep => isAsleepAt(DateTime.now());

  bool isAsleepAt(DateTime now) {
    final currentTime = Duration(hours: now.hour, minutes: now.minute);
    if (type.bedTime <= type.wakeTime) {
      return currentTime >= type.bedTime && currentTime < type.wakeTime;
    } else {
      return currentTime >= type.bedTime || currentTime < type.wakeTime;
    }
  }

  bool get hasAttentionCondition => hasAttentionConditionAt(DateTime.now());

  bool hasAttentionConditionAt(DateTime now) {
    return hunger <= 0 ||
        happiness <= 0 ||
        poopCount > 0 ||
        (isAsleepAt(now) && !lightsOff);
  }

  bool get attentionVisible => attentionVisibleAt(DateTime.now());

  bool attentionVisibleAt(DateTime now) {
    return hasAttentionConditionAt(now) && !attentionSuppressed;
  }

  void updateAttention(Duration elapsed, {DateTime? now}) {
    if (elapsed.isNegative) return;

    final clock = now ?? DateTime.now();
    if (hasAttentionConditionAt(clock)) {
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
      final previousType = type;
      final previousStage = stage;
      evolve();
      // Guard against incomplete evolution rules hanging the tick loop.
      if (identical(type, previousType) && stage == previousStage) {
        break;
      }
    }
  }

  String get assetPath => '${type.assetPath}/${mood.name}.png';

  double get hungerDecayRatePerMinute {
    switch (stage) {
      case PetStage.baby:
        return 0.04 / 10; // 0.004 per minute (scaled from 0–100)
      case PetStage.child:
        return 0.04 / 20;
      case PetStage.teen:
        return 0.04 / 30;
      case PetStage.adult:
        return 0.04 / 60;
    }
  }

  double get happinessDecayRatePerMinute {
    switch (stage) {
      case PetStage.baby:
        return 0.04 / 10;
      case PetStage.child:
        return 0.04 / 20;
      case PetStage.teen:
        return 0.04 / 30;
      case PetStage.adult:
        return 0.04 / 60;
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
    hunger = (hunger - hungerDecayRatePerMinute * minutes).clamp(0.0, maxStat);
    happiness = (happiness - happinessDecayRatePerMinute * minutes).clamp(
      0.0,
      maxStat,
    );
    advancePoopTimer(elapsed);
    updateAttention(elapsed);
  }

  void feed() {
    hunger = (hunger + 2).clamp(0.0, maxStat);
  }

  void play() {
    happiness = (happiness + 2).clamp(0.0, maxStat);
    hunger = (hunger - 1).clamp(0.0, maxStat);
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
          // Child→Lloyd can happen at exactly 2 mistakes; treat ≤2 as the
          // best Lloyd-line adult so evolution never stalls.
          if (careMistakes >= 10) {
            type = demon;
          } else if (careMistakes >= 7) {
            type = bear;
          } else {
            type = puffaloo;
          }
          stage = PetStage.adult;
        } else if (type == mousse) {
          if (careMistakes >= 7) {
            type = bear;
          } else {
            type = puffaloo;
          }
          stage = PetStage.adult;
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
    hunger: _normalizeStat(json['hunger']),
    happiness: _normalizeStat(json['happiness']),
    ageInMinutes: (json['ageInMinutes'] as num?)?.toInt() ?? 0,
    poopCount: (json['poopCount'] as num?)?.toInt() ?? 0,
    secondsSinceLastPoop: (json['secondsSinceLastPoop'] as num?)?.toInt() ?? 0,
    isSick: json['isSick'] as bool? ?? false,
    lightsOff: _readBool(json['lightsOff']),
    careMistakes: (json['careMistakes'] as num?)?.toInt() ?? 0,
    attentionSeconds: (json['attentionSeconds'] as num?)?.toInt() ?? 0,
    attentionSuppressed: json['attentionSuppressed'] as bool? ?? false,
  );

  /// Migrates legacy 0–100 saves onto the 0–8 half-heart scale.
  static double _normalizeStat(Object? value) {
    final raw = (value as num?)?.toDouble() ?? maxStat;
    if (raw > maxStat) {
      return (raw * maxStat / 100.0).clamp(0.0, maxStat);
    }
    return raw.clamp(0.0, maxStat);
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
