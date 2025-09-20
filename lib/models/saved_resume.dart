class SavedResume {
  final String id;
  String title, template;
  Map<String, String> data;
  List<CompanyApplication> applications;
  DateTime createdAt, updatedAt;

  SavedResume({
    required this.id,
    required this.title,
    required this.template,
    required this.data,
    required this.applications,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'template': template,
    'data': data,
    'applications': applications.map((app) => app.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedResume.fromJson(Map<String, dynamic> json) => SavedResume(
    id: json['id'],
    title: json['title'],
    template: json['template'],
    data: Map<String, String>.from(json['data']),
    applications: (json['applications'] as List)
        .map((app) => CompanyApplication.fromJson(app))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
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
