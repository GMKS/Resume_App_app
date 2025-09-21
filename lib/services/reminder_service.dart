import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_resume.dart';

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _enabledKey = 'resume_reminder_enabled';
  static const _lastPromptKey = 'resume_reminder_last_prompt';
  static const reminderIntervalDays = 90;

  bool _enabled = true;
  DateTime? _lastPrompt;

  bool get enabled => _enabled;
  DateTime? get lastPrompt => _lastPrompt;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    final ts = prefs.getInt(_lastPromptKey);
    if (ts != null) _lastPrompt = DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> recordPrompt() async {
    _lastPrompt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPromptKey, _lastPrompt!.millisecondsSinceEpoch);
  }

  bool shouldPrompt(List<SavedResume> resumes) {
    if (!_enabled) return false;
    if (resumes.isEmpty) return false;
    final newestUpdate = resumes
        .map((r) => r.updatedAt)
        .fold<DateTime>(
          resumes.first.updatedAt,
          (p, e) => e.isAfter(p) ? e : p,
        );
    final age = DateTime.now().difference(newestUpdate).inDays;
    if (age < reminderIntervalDays) return false;
    // Avoid re-prompting too often: only if last prompt > 7 days ago
    if (_lastPrompt != null &&
        DateTime.now().difference(_lastPrompt!).inDays < 7) {
      return false;
    }
    return true;
  }
}
