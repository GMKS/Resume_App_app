import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class SkillsService {
  SkillsService._();
  static final SkillsService instance = SkillsService._();

  List<String>? _cache;

  Future<List<String>> getAllSkills() async {
    if (_cache != null) return _cache!;
    try {
      final raw = await rootBundle.loadString('assets/data/skills.json');
      final List<dynamic> parsed = jsonDecode(raw);
      _cache = parsed.map((e) => e.toString()).toSet().toList()..sort();
      return _cache!;
    } catch (_) {
      // Fallback curated list
      _cache = [
        // Technology
        'Flutter',
        'Dart',
        'JavaScript',
        'TypeScript',
        'React',
        'Angular',
        'Vue',
        'Node.js',
        'Express',
        'Python',
        'Django',
        'Flask',
        'Java',
        'Spring',
        'Kotlin',
        'Swift',
        'Objective-C',
        'C#',
        '.NET',
        'C++',
        'Go',
        'Rust',
        'SQL',
        'NoSQL',
        'MongoDB',
        'PostgreSQL',
        'MySQL',
        'Firebase',
        'AWS',
        'Azure',
        'GCP',
        'Docker',
        'Kubernetes',
        'CI/CD',
        'Git',
        'Terraform',
        'Ansible',
        'Linux',
        'Bash',
        // Data / AI
        'Machine Learning',
        'Deep Learning',
        'NLP',
        'Computer Vision',
        'Pandas',
        'NumPy',
        'TensorFlow',
        'PyTorch',
        'Scikit-learn',
        'Data Analysis',
        'Data Visualization',
        'Power BI',
        'Tableau',
        'Big Data',
        'Hadoop',
        'Spark',
        // Design / Product
        'UI/UX',
        'Figma',
        'Adobe XD',
        'Sketch',
        'Wireframing',
        'Prototyping',
        'Design Systems',
        'User Research',
        'Usability Testing',
        'Product Management',
        'Agile',
        'Scrum',
        'Kanban',
        'JIRA',
        // DevOps / Security
        'DevOps',
        'SRE',
        'Observability',
        'Prometheus',
        'Grafana',
        'ELK',
        'Security',
        'Penetration Testing',
        'OWASP',
        'IAM',
        'SSO',
        // Finance / Business
        'Financial Analysis',
        'Accounting',
        'Budgeting',
        'Forecasting',
        'Excel',
        'PowerPoint',
        'SQL Reporting',
        'Risk Management',
        'Auditing',
        'Compliance',
        // Marketing / Sales
        'SEO',
        'SEM',
        'Content Marketing',
        'Social Media',
        'Email Marketing',
        'Google Analytics',
        'CRM',
        'Lead Generation',
        'Copywriting',
        'Branding',
        // Healthcare
        'HIPAA',
        'Clinical Research',
        'EMR',
        'EHR',
        'Medical Coding',
        'Pharmacology',
        'Patient Care',
        'Public Health',
        // Education
        'Curriculum Design',
        'Instructional Design',
        'Classroom Management',
        'Assessment',
        'EdTech',
        // Other soft skills
        'Leadership',
        'Communication',
        'Problem Solving',
        'Teamwork',
        'Time Management',
        'Critical Thinking',
        'Project Management',
      ];
      return _cache!;
    }
  }
}
