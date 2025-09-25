import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/saved_resume.dart';

class CloudResumeService {
  CloudResumeService._();
  static final CloudResumeService instance = CloudResumeService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int classicLimit = 2;

  // Helper method to convert timestamp to DateTime
  DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  // Get current user's resumes from Firestore
  Stream<List<SavedResume>> get resumesStream {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('resumes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return SavedResume(
              id: doc.id,
              title: data['title'] ?? '',
              template: data['template'] ?? '',
              createdAt: _timestampToDateTime(data['createdAt']),
              updatedAt: _timestampToDateTime(data['updatedAt']),
              data: Map<String, dynamic>.from(data['data'] ?? {}),
            );
          }).toList();
        });
  }

  // Get all resumes (for backward compatibility)
  Future<List<SavedResume>> get all async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('resumes')
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return SavedResume(
        id: doc.id,
        title: data['title'] ?? '',
        template: data['template'] ?? '',
        createdAt: _timestampToDateTime(data['createdAt']),
        updatedAt: _timestampToDateTime(data['updatedAt']),
        data: Map<String, dynamic>.from(data['data'] ?? {}),
      );
    }).toList();
  }

  // Check if user can upload more classic templates
  Future<bool> canUploadClassic() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('resumes')
        .where('template', isEqualTo: 'Classic')
        .get();

    return snapshot.docs.length < classicLimit;
  }

  // Upload/Save resume to Firestore
  Future<bool> uploadResume(SavedResume resume) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final resumeData = {
        'title': resume.title,
        'template': resume.template,
        'data': resume.data,
        'createdAt': resume.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch
            : resume.createdAt.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (resume.id.isEmpty) {
        // Create new resume
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('resumes')
            .add(resumeData);
      } else {
        // Update existing resume
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('resumes')
            .doc(resume.id)
            .set(resumeData);
      }

      return true;
    } catch (e) {
      print('Error uploading resume: $e');
      return false;
    }
  }

  // Upload classic template (with limit check)
  Future<bool> uploadClassic(SavedResume resume) async {
    if (resume.template != 'Classic') return false;
    if (!await canUploadClassic()) return false;

    return await uploadResume(resume);
  }

  // Delete resume from Firestore
  Future<bool> deleteResume(String resumeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('resumes')
          .doc(resumeId)
          .delete();
      return true;
    } catch (e) {
      print('Error deleting resume: $e');
      return false;
    }
  }

  // Create user profile document
  Future<void> createUserProfile(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Update last login
  Future<void> updateLastLogin() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Update user profile photo
  Future<void> updateProfilePhoto(String photoUrl) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).update({
      'profilePhotoUrl': photoUrl,
      'lastUpdatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Get user profile photo URL
  Future<String?> getProfilePhotoUrl() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['profilePhotoUrl'] as String?;
    } catch (e) {
      print('Error getting profile photo URL: $e');
      return null;
    }
  }
}
