import 'package:happy_cherry/core/pet.dart';

/// Snapshot loaded from disk or cloud, including when it was written.
typedef StoredSave = ({
  Pet pet,
  int coins,
  List<String> ownedAccessories,
  DateTime savedAt,
});

/// Progress returned to UI after load (time already advanced).
typedef LoadedSave = ({Pet pet, int coins, List<String> ownedAccessories});
