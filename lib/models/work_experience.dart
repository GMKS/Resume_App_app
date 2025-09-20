class WorkExperience {
  final String company, position, startDate, endDate, description;
  WorkExperience({
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.description,
  });
  String toJson() => '$company|$position|$startDate|$endDate|$description';
  static WorkExperience fromJson(String json) {
    final parts = json.split('|');
    return WorkExperience(
      company: parts[0],
      position: parts[1],
      startDate: parts[2],
      endDate: parts[3],
      description: parts[4],
    );
  }
}
