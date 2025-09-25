import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saved_resume.dart';

class CloudStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper method to convert timestamp to DateTime
  static DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now();
  }

  // Upload profile photo
  static Future<String?> uploadProfilePhoto(File imageFile) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final ref = _storage.ref().child(
        'profile_photos/$userId/profile_photo.jpg',
      );
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  // Upload profile photo from bytes (for web)
  static Future<String?> uploadProfilePhotoBytes(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final ref = _storage.ref().child('profile_photos/$userId/$fileName');
      final uploadTask = ref.putData(imageBytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile photo: $e');
      return null;
    }
  }

  // Upload company logo
  static Future<String?> uploadCompanyLogo(
    File imageFile,
    String companyName,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final fileName =
          '${companyName.replaceAll(' ', '_').toLowerCase()}_logo.jpg';
      final ref = _storage.ref().child('company_logos/$userId/$fileName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading company logo: $e');
      return null;
    }
  }

  // Upload resume export (PDF, DOCX, etc.)
  static Future<String?> uploadResumeExport(
    File file,
    String resumeId,
    String format,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final fileName =
          '${resumeId}_${DateTime.now().millisecondsSinceEpoch}.$format';
      final ref = _storage.ref().child('exports/$userId/$fileName');
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading resume export: $e');
      return null;
    }
  }

  // Upload resume export from bytes
  static Future<String?> uploadResumeExportBytes(
    Uint8List bytes,
    String resumeId,
    String format,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final fileName =
          '${resumeId}_${DateTime.now().millisecondsSinceEpoch}.$format';
      final ref = _storage.ref().child('exports/$userId/$fileName');
      final uploadTask = ref.putData(bytes);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading resume export: $e');
      return null;
    }
  }

  // Delete file from storage
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Get user's uploaded files
  static Future<List<String>> getUserFiles(String folder) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final ref = _storage.ref().child('$folder/$userId');
      final result = await ref.listAll();
      final urls = <String>[];

      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      print('Error getting user files: $e');
      return [];
    }
  }

  // Legacy methods for backward compatibility
  static Future<void> saveResumeToCloud(SavedResume resume) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('resumes')
        .doc(resume.id.isEmpty ? null : resume.id)
        .set({
          'title': resume.title,
          'template': resume.template,
          'data': resume.data,
          'createdAt': resume.id.isEmpty
              ? DateTime.now().millisecondsSinceEpoch
              : resume.createdAt.millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
  }

  static Future<List<SavedResume>> getResumesFromCloud() async {
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
}
