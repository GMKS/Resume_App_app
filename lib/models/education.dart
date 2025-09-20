class Education {
  final String degree, institution, year;
  Education({
    required this.degree,
    required this.institution,
    required this.year,
  });
  String toJson() => '$degree|$institution|$year';
  static Education fromJson(String json) {
    final parts = json.split('|');
    return Education(degree: parts[0], institution: parts[1], year: parts[2]);
  }
}
