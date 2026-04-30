import '../models/resume_model.dart';

bool shouldApplyCloudResume({
  required ResumeModel? localResume,
  required ResumeModel cloudResume,
}) {
  return localResume == null ||
      localResume.updatedAt.isBefore(cloudResume.updatedAt);
}