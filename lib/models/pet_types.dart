enum PetStage { baby, child, teen, adult }

class PetType {
  final String name;
  final String assetPath;
  final Duration bedTime;
  final Duration wakeTime;
  final PetStage stage;

  const PetType({
    required this.name,
    required this.assetPath,
    required this.bedTime,
    required this.wakeTime,
    required this.stage,
  });
}

const PetType blob = PetType(
  name: 'Blob',
  assetPath: 'assets/pets/blob',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.baby,
);

const PetType sprout = PetType(
  name: 'Sprout',
  assetPath: 'assets/pets/sprout',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.child,
);

const PetType squeaky = PetType(
  name: 'Squeaky',
  assetPath: 'assets/pets/squeaky',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.child,
);

const PetType mousse = PetType(
  name: 'Mousse',
  assetPath: 'assets/pets/mousse',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.teen,
);

const PetType starfruit = PetType(
  name: 'starfruit',
  assetPath: 'assets/pets/starfruit',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.teen,
);

const PetType lloyd = PetType(
  name: 'Lloyd',
  assetPath: 'assets/pets/lloyd',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.teen,
);

const PetType angel = PetType(
  name: 'Angel',
  assetPath: 'assets/pets/angel',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.adult,
);

const PetType cherry = PetType(
  name: 'Cherry',
  assetPath: 'assets/pets/cherry',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.adult,
);

const PetType flower = PetType(
  name: 'Flower',
  assetPath: 'assets/pets/flower',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.adult,
);

const PetType puffaloo = PetType(
  name: 'Puffaloo',
  assetPath: 'assets/pets/puffaloo',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.adult,
);

const PetType bear = PetType(
  name: 'Bear',
  assetPath: 'assets/pets/bear',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.adult,
);

const PetType demon = PetType(
  name: 'Demon',
  assetPath: 'assets/pets/demon',
  bedTime: Duration(hours: 23), // 11pm–8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.adult,
);

const List<PetType> allPetTypes = [blob, angel, bear, cherry, demon, flower, lloyd, mousse, puffaloo, sprout, squeaky, starfruit];

PetType petTypeFromName(String? name) {
  if (name == null) return blob;
  final key = name.toLowerCase();
  return allPetTypes.firstWhere(
    (t) => t.name.toLowerCase() == key,
    orElse: () => blob,
  );
}
