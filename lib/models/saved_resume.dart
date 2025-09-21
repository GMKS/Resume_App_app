class SavedResume {
  final String id;
  final String title;
  final String template;
  final DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> data;

  SavedResume({
    required this.id,
    required this.title,
    required this.template,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
  });

  factory SavedResume.fromJson(Map<String, dynamic> json) => SavedResume(
    id: json['id'] as String,
    title: json['title'] as String,
    template: json['template'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    data: (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'template': template,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'data': data,
  };

  SavedResume copyWith({
    String? title,
    String? template,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
  }) => SavedResume(
    id: id,
    title: title ?? this.title,
    template: template ?? this.template,
    createdAt: createdAt,
    updatedAt: updatedAt ?? DateTime.now(),
    data: data ?? this.data,
  );
}

class CompanyApplication {
  final String id;
  String companyName, position, status, notes;
  DateTime appliedDate;

  CompanyApplication({
    required this.id,
    required this.companyName,
    required this.position,
    required this.appliedDate,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'position': position,
    'appliedDate': appliedDate.toIso8601String(),
    'status': status,
    'notes': notes,
  };

  factory CompanyApplication.fromJson(Map<String, dynamic> json) =>
      CompanyApplication(
        id: json['id'],
        companyName: json['companyName'],
        position: json['position'],
        appliedDate: DateTime.parse(json['appliedDate']),
        status: json['status'],
        notes: json['notes'],
      );
}
