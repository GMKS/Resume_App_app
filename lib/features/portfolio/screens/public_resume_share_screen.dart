import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/resume_json.dart';
import '../../preview/screens/preview_screen.dart';

class PublicResumeShareScreen extends ConsumerStatefulWidget {
  const PublicResumeShareScreen({
    super.key,
    required this.shareId,
    this.resumePayload,
  });

  final String shareId;
  final String? resumePayload;

  @override
  ConsumerState<PublicResumeShareScreen> createState() =>
      _PublicResumeShareScreenState();
}

class _PublicResumeShareScreenState
    extends ConsumerState<PublicResumeShareScreen> {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'public_resume_shares';

  Map<String, dynamic>? _decodeResumePayload(String? payload) {
    final raw = payload?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    try {
      final decoded = utf8.decode(base64Url.decode(raw));
      final json = jsonDecode(decoded);
      if (json is! Map) {
        return null;
      }

      return json.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadSharedResume() async {
    debugPrint(
      'PublicResumeShareScreen.load start shareId=${widget.shareId} '
      'hasPayload=${(widget.resumePayload?.trim().isNotEmpty ?? false)}',
    );

    final payloadResume = _decodeResumePayload(widget.resumePayload);
    if (payloadResume != null) {
      debugPrint('PublicResumeShareScreen.load using query payload');
      return payloadResume;
    }

    if (widget.shareId.trim().isEmpty) {
      debugPrint('PublicResumeShareScreen.load missing shareId');
      return null;
    }

    try {
      final snapshot =
          await _db.collection(_collection).doc(widget.shareId).get();
      final data = snapshot.data();
      debugPrint(
        'PublicResumeShareScreen.load snapshot '
        'exists=${snapshot.exists} active=${data?['active']} '
        'hasResume=${data?['resume'] is Map}',
      );
      if (data == null || data['active'] != true) {
        return null;
      }

      final resumeData = data['resume'];
      if (resumeData is! Map) {
        final storedPayload = data['resumePayload'];
        if (storedPayload is String) {
          final decoded = _decodeResumePayload(storedPayload);
          if (decoded != null) {
            debugPrint(
                'PublicResumeShareScreen.load using stored payload fallback');
            return decoded;
          }
        }
        return null;
      }

      return resumeData.map((key, value) => MapEntry(key.toString(), value));
    } catch (error) {
      debugPrint(
          'PublicResumeShareScreen.load failed shareId=${widget.shareId} error=$error');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadSharedResume(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Shared portfolio is unavailable.')),
          );
        }

        final resumeMap = snapshot.data;
        if (resumeMap == null) {
          return const Scaffold(
            body: Center(child: Text('Shared portfolio is unavailable.')),
          );
        }

        final resume = ResumeJson.fromMap(resumeMap);
        return PreviewScreen(
          resumeId: resume.id,
          initialResume: resume,
        );
      },
    );
  }
}
