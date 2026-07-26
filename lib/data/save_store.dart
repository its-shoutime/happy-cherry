/// Shared contract for local and remote progress storage (LSP / DIP).
abstract class SaveStore {
  Future<Map<String, dynamic>?> loadRaw(String? userId);

  Future<void> saveRaw(String? userId, Map<String, dynamic> payload);

  Future<void> delete(String? userId);
}
