import 'package:flutter_test/flutter_test.dart';
import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/services/resume_json.dart';
import 'package:resume_builder/core/utils/cloud_resume_sync.dart';

ResumeModel _resume({
  required String id,
  required DateTime updatedAt,
  String fontFamily = 'Merriweather',
  String layoutStyle = 'timeline',
}) {
  return ResumeModel(
    id: id,
    title: 'Resume $id',
    personalInfo: PersonalInfo(fullName: 'Test User'),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: updatedAt,
    writingLanguage: 'Spanish',
    fontFamily: fontFamily,
    layoutStyle: layoutStyle,
  );
}

void main() {
  test('cloud resume is applied when the local copy is missing', () {
    final cloudResume = _resume(id: 'one', updatedAt: DateTime(2026, 4, 18));

    expect(
      shouldApplyCloudResume(
        localResume: null,
        cloudResume: cloudResume,
      ),
      isTrue,
    );
  });

  test('cloud resume is applied when the cloud copy is newer', () {
    final localResume = _resume(id: 'one', updatedAt: DateTime(2026, 4, 17));
    final cloudResume = _resume(id: 'one', updatedAt: DateTime(2026, 4, 18));

    expect(
      shouldApplyCloudResume(
        localResume: localResume,
        cloudResume: cloudResume,
      ),
      isTrue,
    );
  });

  test('cloud resume is skipped when the local copy is current', () {
    final localResume = _resume(id: 'one', updatedAt: DateTime(2026, 4, 18));
    final cloudResume = _resume(id: 'one', updatedAt: DateTime(2026, 4, 18));

    expect(
      shouldApplyCloudResume(
        localResume: localResume,
        cloudResume: cloudResume,
      ),
      isFalse,
    );
  });

  test('resume json round-trip preserves font and layout settings', () {
    final original = _resume(
      id: 'two',
      updatedAt: DateTime(2026, 4, 18),
      fontFamily: 'Lora',
      layoutStyle: 'compact',
    );

    final restored = ResumeJson.fromMap(ResumeJson.toMap(original));

    expect(restored.fontFamily, 'Lora');
    expect(restored.layoutStyle, 'compact');
    expect(restored.writingLanguage, 'Spanish');
  });
}