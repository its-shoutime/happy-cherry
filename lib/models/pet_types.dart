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
  bedTime: Duration(hours: 23), //10pm-8am
  wakeTime: Duration(hours: 8),
  stage: PetStage.baby,
);

const List<PetType> allPetTypes = [blob];

PetType petTypeFromName(String? name) {
  if (name == null) return blob;
  final key = name.toLowerCase();
  return allPetTypes.firstWhere(
    (t) => t.name.toLowerCase() == key,
    orElse: () => blob,
  );
}
