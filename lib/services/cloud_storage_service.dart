import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_resume.dart';

class CloudStorageService {
  static Future<void> saveResumeToCloud(SavedResume resume) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('resumes').doc(resume.id).set(resume.toJson());
  }

  static Future<List<SavedResume>> getResumesFromCloud() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('resumes').get();
    return snapshot.docs
        .map((doc) => SavedResume.fromJson(doc.data()))
        .toList();
  }
}
