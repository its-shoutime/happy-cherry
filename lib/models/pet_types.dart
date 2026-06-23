enum PetStage { baby, child, teen, adult }

class PetType {
  final String name;
  final String assetPath;
  final Duration bedtime;
  final Duration waketime;
  final PetStage stage;

  const PetType({
    required this.name,
    required this.assetPath,
    required this.bedtime,
    required this.waketime,
    required this.stage,
  });
}

const PetType blob = PetType(
  name: 'Blob',
  assetPath: 'assets/pets/blob',
  bedtime: Duration(hours: 22), //10pm-8am
  waketime: Duration(hours: 8),
  stage: PetStage.baby,
);