import '../../../core/models/resume_model.dart';

class PortfolioUrlResolution {
  const PortfolioUrlResolution({
    required this.url,
    required this.hasAnyCandidate,
  });

  final String url;
  final bool hasAnyCandidate;

  bool get hasUrl => url.isNotEmpty;
}

class PortfolioProfileService {
  static const Set<String> _disallowedPortfolioHosts = <String>{
    'gmail.com',
    'www.gmail.com',
    'mail.google.com',
    'googlemail.com',
    'outlook.com',
    'www.outlook.com',
    'login.live.com',
    'hotmail.com',
    'www.hotmail.com',
    'yahoo.com',
    'www.yahoo.com',
    'mail.yahoo.com',
  };

  static ResumeModel? selectSourceResume(
    List<ResumeModel> resumes, {
    String? preferredResumeId,
  }) {
    if (resumes.isEmpty) {
      return null;
    }

    final normalizedPreferredId = preferredResumeId?.trim() ?? '';
    if (normalizedPreferredId.isNotEmpty) {
      for (final resume in resumes) {
        if (resume.id == normalizedPreferredId) {
          return resume;
        }
      }
    }

    for (final resume in resumes) {
      if (resolvePortfolioUrl(resume).isNotEmpty) {
        return resume;
      }
    }

    return resumes.first;
  }

  static String resolvePortfolioUrl(ResumeModel? resume) {
    return resolvePortfolioUrlState(resume).url;
  }

  static PortfolioUrlResolution resolvePortfolioUrlState(ResumeModel? resume) {
    if (resume == null) {
      return const PortfolioUrlResolution(url: '', hasAnyCandidate: false);
    }

    final candidates = <String>[
      resume.personalInfo.website?.trim() ?? '',
      resume.personalInfo.linkedIn?.trim() ?? '',
      resume.personalInfo.github?.trim() ?? '',
      _portfolioProjectUrl(resume),
      ...resume.projects.map((project) => project.url?.trim() ?? ''),
    ];

    final hasAnyCandidate = candidates.any((candidate) => candidate.isNotEmpty);

    for (final candidate in candidates) {
      final normalized = normalizeExternalUrl(candidate);
      if (normalized.isNotEmpty) {
        return PortfolioUrlResolution(
          url: normalized,
          hasAnyCandidate: true,
        );
      }
    }

    return PortfolioUrlResolution(url: '', hasAnyCandidate: hasAnyCandidate);
  }

  static bool isValidPortfolioUrl(String raw) {
    return normalizeExternalUrl(raw).isNotEmpty;
  }

  static String normalizeExternalUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
    final candidate = hasScheme ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(candidate);
    if (uri == null || uri.host.trim().isEmpty) {
      return '';
    }

    if (uri.userInfo.trim().isNotEmpty) {
      return '';
    }

    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return '';
    }

    final normalizedHost = uri.host.trim().toLowerCase();
    if (_disallowedPortfolioHosts.contains(normalizedHost)) {
      return '';
    }

    return uri.replace(fragment: null).toString();
  }

  static String _portfolioProjectUrl(ResumeModel resume) {
    for (final project in resume.projects) {
      final title = project.title.trim().toLowerCase();
      final description = project.description.trim().toLowerCase();
      final url = project.url?.trim() ?? '';
      if (url.isEmpty) {
        continue;
      }
      if (title.contains('portfolio') || description.contains('portfolio')) {
        return url;
      }
    }

    return '';
  }
}
