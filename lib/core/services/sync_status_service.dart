import 'storage_service.dart';

class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    this.lastBackupAt,
    this.lastRestoreAt,
    this.lastSummary,
  });

  final DateTime? lastBackupAt;
  final DateTime? lastRestoreAt;
  final String? lastSummary;
}

class SyncStatusService {
  const SyncStatusService._();

  static const String _lastBackupAtKey = 'sync_last_backup_at';
  static const String _lastRestoreAtKey = 'sync_last_restore_at';
  static const String _lastSummaryKey = 'sync_last_summary';

  static Future<SyncStatusSnapshot> load() async {
    final prefs = StorageService.prefs;
    final lastBackupAt = prefs.getInt(_lastBackupAtKey);
    final lastRestoreAt = prefs.getInt(_lastRestoreAtKey);
    final lastSummary = prefs.getString(_lastSummaryKey)?.trim();

    return SyncStatusSnapshot(
      lastBackupAt: lastBackupAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastBackupAt),
      lastRestoreAt: lastRestoreAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastRestoreAt),
      lastSummary: lastSummary != null && lastSummary.isNotEmpty
          ? lastSummary
          : null,
    );
  }

  static Future<void> recordBackup(
    String summary, {
    DateTime? at,
  }) async {
    final prefs = StorageService.prefs;
    final timestamp = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await prefs.setInt(_lastBackupAtKey, timestamp);
    await prefs.setString(_lastSummaryKey, summary);
  }

  static Future<void> recordRestore(
    String summary, {
    DateTime? at,
  }) async {
    final prefs = StorageService.prefs;
    final timestamp = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await prefs.setInt(_lastRestoreAtKey, timestamp);
    await prefs.setString(_lastSummaryKey, summary);
  }

  static Future<void> recordStatus(String summary) async {
    final prefs = StorageService.prefs;
    await prefs.setString(_lastSummaryKey, summary);
  }
}