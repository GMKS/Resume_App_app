enum JobApplicationStatus {
  saved,
  applied,
  interview,
  offer,
  rejected,
}

extension JobApplicationStatusX on JobApplicationStatus {
  String get label {
    switch (this) {
      case JobApplicationStatus.saved:
        return 'Saved';
      case JobApplicationStatus.applied:
        return 'Applied';
      case JobApplicationStatus.interview:
        return 'Interview';
      case JobApplicationStatus.offer:
        return 'Offer';
      case JobApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  bool get countsAsApplied => this != JobApplicationStatus.saved;

  static JobApplicationStatus fromName(String value) {
    return JobApplicationStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => JobApplicationStatus.saved,
    );
  }
}

class JobActivityItem {
  const JobActivityItem({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String message;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory JobActivityItem.fromMap(Map<String, dynamic> map) {
    return JobActivityItem(
      id: map['id']?.toString() ?? '',
      type: map['type']?.toString() ?? 'update',
      message: map['message']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class JobDescriptionInsights {
  const JobDescriptionInsights({
    required this.role,
    required this.skills,
    required this.keywords,
  });

  final String role;
  final List<String> skills;
  final List<String> keywords;
}

class JobReminderItem {
  const JobReminderItem({
    required this.jobId,
    required this.company,
    required this.role,
    required this.kind,
    required this.date,
    required this.status,
  });

  final String jobId;
  final String company;
  final String role;
  final String kind;
  final DateTime date;
  final JobApplicationStatus status;
}

class JobTrackerAnalytics {
  const JobTrackerAnalytics({
    required this.totalJobs,
    required this.totalApplications,
    required this.interviewsCount,
    required this.offersCount,
    required this.rejectionsCount,
    required this.savedCount,
    required this.conversionRate,
    required this.upcomingReminders,
  });

  final int totalJobs;
  final int totalApplications;
  final int interviewsCount;
  final int offersCount;
  final int rejectionsCount;
  final int savedCount;
  final double conversionRate;
  final List<JobReminderItem> upcomingReminders;
}

class JobApplicationRecord {
  const JobApplicationRecord({
    required this.jobId,
    required this.userId,
    required this.company,
    required this.role,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.appliedDate,
    this.resumeId,
    this.jobLink,
    this.salary,
    this.notes = '',
    this.jobDescription = '',
    this.parsedSkills = const <String>[],
    this.parsedKeywords = const <String>[],
    this.followUpDate,
    this.interviewDate,
    this.activities = const <JobActivityItem>[],
  });

  final String jobId;
  final String userId;
  final String company;
  final String role;
  final String location;
  final JobApplicationStatus status;
  final DateTime? appliedDate;
  final String? resumeId;
  final String? jobLink;
  final String? salary;
  final String notes;
  final String jobDescription;
  final List<String> parsedSkills;
  final List<String> parsedKeywords;
  final DateTime? followUpDate;
  final DateTime? interviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<JobActivityItem> activities;

  String get normalizedCompany => company.trim().toLowerCase();

  String get normalizedRole => role.trim().toLowerCase();

  bool get hasResumeLinked => resumeId != null && resumeId!.trim().isNotEmpty;

  JobApplicationRecord copyWith({
    String? jobId,
    String? userId,
    String? company,
    String? role,
    String? location,
    JobApplicationStatus? status,
    DateTime? appliedDate,
    bool clearAppliedDate = false,
    String? resumeId,
    bool clearResumeId = false,
    String? jobLink,
    bool clearJobLink = false,
    String? salary,
    bool clearSalary = false,
    String? notes,
    String? jobDescription,
    List<String>? parsedSkills,
    List<String>? parsedKeywords,
    DateTime? followUpDate,
    bool clearFollowUpDate = false,
    DateTime? interviewDate,
    bool clearInterviewDate = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<JobActivityItem>? activities,
  }) {
    return JobApplicationRecord(
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      company: company ?? this.company,
      role: role ?? this.role,
      location: location ?? this.location,
      status: status ?? this.status,
      appliedDate: clearAppliedDate ? null : (appliedDate ?? this.appliedDate),
      resumeId: clearResumeId ? null : (resumeId ?? this.resumeId),
      jobLink: clearJobLink ? null : (jobLink ?? this.jobLink),
      salary: clearSalary ? null : (salary ?? this.salary),
      notes: notes ?? this.notes,
      jobDescription: jobDescription ?? this.jobDescription,
      parsedSkills: parsedSkills ?? this.parsedSkills,
      parsedKeywords: parsedKeywords ?? this.parsedKeywords,
      followUpDate: clearFollowUpDate
          ? null
          : (followUpDate ?? this.followUpDate),
      interviewDate: clearInterviewDate
          ? null
          : (interviewDate ?? this.interviewDate),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      activities: activities ?? this.activities,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'job_id': jobId,
      'user_id': userId,
      'company': company,
      'role': role,
      'location': location,
      'status': status.name,
      'applied_date': appliedDate?.toIso8601String(),
      'resume_id': resumeId,
      'job_link': jobLink,
      'salary': salary,
      'notes': notes,
      'job_description': jobDescription,
      'parsed_skills': parsedSkills,
      'parsed_keywords': parsedKeywords,
      'follow_up_date': followUpDate?.toIso8601String(),
      'interview_date': interviewDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'activities': activities.map((item) => item.toMap()).toList(growable: false),
    };
  }

  factory JobApplicationRecord.fromMap(Map<String, dynamic> map) {
    final rawActivities = map['activities'];
    final activityList = rawActivities is List
        ? rawActivities
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
            .map(JobActivityItem.fromMap)
            .toList(growable: false)
        : const <JobActivityItem>[];

    return JobApplicationRecord(
      jobId: map['job_id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      status: JobApplicationStatusX.fromName(map['status']?.toString() ?? ''),
      appliedDate: DateTime.tryParse(map['applied_date']?.toString() ?? ''),
      resumeId: map['resume_id']?.toString(),
      jobLink: map['job_link']?.toString(),
      salary: map['salary']?.toString(),
      notes: map['notes']?.toString() ?? '',
      jobDescription: map['job_description']?.toString() ?? '',
      parsedSkills: (map['parsed_skills'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      parsedKeywords: (map['parsed_keywords'] as List? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      followUpDate: DateTime.tryParse(map['follow_up_date']?.toString() ?? ''),
      interviewDate: DateTime.tryParse(map['interview_date']?.toString() ?? ''),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
      activities: activityList,
    );
  }
}