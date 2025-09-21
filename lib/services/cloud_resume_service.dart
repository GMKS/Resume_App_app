import '../models/saved_resume.dart';

class CloudResumeService {
  CloudResumeService._();
  static final CloudResumeService instance = CloudResumeService._();

  final List<SavedResume> _cloud = [];

  static const int classicLimit = 2;

  List<SavedResume> get all => List.unmodifiable(_cloud);

  bool canUploadClassic() =>
      _cloud.where((r) => r.template == 'Classic').length < classicLimit;

  Future<bool> uploadClassic(SavedResume resume) async {
    if (resume.template != 'Classic') return false;
    if (!canUploadClassic()) return false;
    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 400));
    _cloud.removeWhere((r) => r.id == resume.id);
    _cloud.add(resume);
    return true;
  }
}