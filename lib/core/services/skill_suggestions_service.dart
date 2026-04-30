/// Smart skill suggestions grouped by job role / industry.
/// Used by AI Resume Generator, Skill Suggestions feature, and Skills screen.
class SkillSuggestionsService {
  // ── Role → skills map ──────────────────────────────────────────────────────
  static const Map<String, List<String>> _roleSkills = {
    'Software Engineer': [
      'Dart', 'Flutter', 'Python', 'Java', 'Kotlin', 'Swift', 'TypeScript',
      'JavaScript', 'React', 'Node.js', 'REST APIs', 'GraphQL', 'SQL', 'Git',
      'Docker', 'Kubernetes', 'AWS', 'CI/CD', 'Agile', 'Unit Testing',
    ],
    'Frontend Developer': [
      'HTML', 'CSS', 'JavaScript', 'TypeScript', 'React', 'Vue.js', 'Angular',
      'Tailwind CSS', 'SASS', 'Webpack', 'Figma', 'Responsive Design',
      'Web Accessibility', 'Performance Optimization', 'Git', 'REST APIs',
    ],
    'Backend Developer': [
      'Python', 'Java', 'Node.js', 'Go', 'Rust', 'PHP', 'SQL', 'PostgreSQL',
      'MongoDB', 'Redis', 'Docker', 'Kubernetes', 'AWS', 'REST APIs', 'GraphQL',
      'Microservices', 'CI/CD', 'Linux', 'Nginx', 'Security Best Practices',
    ],
    'Mobile Developer': [
      'Flutter', 'Dart', 'Swift', 'Kotlin', 'React Native', 'iOS', 'Android',
      'Firebase', 'REST APIs', 'SQLite', 'Push Notifications', 'App Store',
      'Google Play', 'UI/UX Design', 'Git', 'Agile',
    ],
    'Data Scientist': [
      'Python', 'R', 'Machine Learning', 'Deep Learning', 'TensorFlow', 'PyTorch',
      'Scikit-learn', 'Pandas', 'NumPy', 'SQL', 'Data Visualization', 'Tableau',
      'Statistics', 'NLP', 'Computer Vision', 'Big Data', 'Spark', 'Jupyter',
    ],
    'Data Analyst': [
      'Excel', 'SQL', 'Python', 'R', 'Tableau', 'Power BI', 'Data Visualization',
      'Statistical Analysis', 'Google Analytics', 'Data Cleaning', 'Reporting',
      'Business Intelligence', 'A/B Testing', 'ETL', 'Data Modeling',
    ],
    'UI/UX Designer': [
      'Figma', 'Adobe XD', 'Sketch', 'InVision', 'Prototyping', 'Wireframing',
      'User Research', 'Usability Testing', 'Design Systems', 'Typography',
      'Color Theory', 'Accessibility', 'HTML/CSS', 'Motion Design', 'Adobe Suite',
    ],
    'Product Manager': [
      'Product Strategy', 'Roadmapping', 'Agile', 'Scrum', 'JIRA', 'User Stories',
      'Market Research', 'Competitive Analysis', 'Stakeholder Management',
      'Data Analysis', 'A/B Testing', 'OKRs', 'Wireframing', 'SQL', 'Tableau',
    ],
    'DevOps Engineer': [
      'Docker', 'Kubernetes', 'Terraform', 'Ansible', 'Jenkins', 'CI/CD',
      'AWS', 'Azure', 'GCP', 'Linux', 'Bash', 'Python', 'Monitoring',
      'Prometheus', 'Grafana', 'Security', 'Networking', 'Git',
    ],
    'Full Stack Developer': [
      'JavaScript', 'TypeScript', 'React', 'Node.js', 'Python', 'SQL',
      'MongoDB', 'REST APIs', 'GraphQL', 'Docker', 'Git', 'AWS',
      'HTML/CSS', 'Redis', 'Agile', 'Testing', 'CI/CD',
    ],
    'QA Engineer': [
      'Manual Testing', 'Automation Testing', 'Selenium', 'Appium', 'Postman',
      'JIRA', 'Test Planning', 'Test Cases', 'Bug Reporting', 'API Testing',
      'Performance Testing', 'Regression Testing', 'Agile', 'SQL', 'Python',
    ],
    'Cybersecurity Analyst': [
      'Network Security', 'Penetration Testing', 'SIEM', 'Incident Response',
      'Vulnerability Assessment', 'Firewall', 'IDS/IPS', 'Python', 'Linux',
      'OWASP', 'Risk Assessment', 'Compliance', 'Cryptography', 'SOC',
    ],
    'Marketing Manager': [
      'Digital Marketing', 'SEO', 'SEM', 'Google Ads', 'Facebook Ads',
      'Content Marketing', 'Email Marketing', 'CRM', 'HubSpot', 'Analytics',
      'Brand Strategy', 'Social Media', 'Copywriting', 'Campaign Management',
    ],
    'Project Manager': [
      'Project Planning', 'Agile', 'Scrum', 'PMP', 'PRINCE2', 'JIRA',
      'Risk Management', 'Budgeting', 'Stakeholder Management', 'MS Project',
      'Communication', 'Leadership', 'Change Management', 'Reporting',
    ],
    'Business Analyst': [
      'Requirements Analysis', 'Process Mapping', 'SQL', 'Excel', 'Power BI',
      'JIRA', 'Stakeholder Management', 'UML', 'Business Process Modeling',
      'Agile', 'Data Analysis', 'SWOT Analysis', 'Functional Specifications',
    ],
    'HR Manager': [
      'Recruitment', 'Talent Acquisition', 'HRIS', 'Performance Management',
      'Employee Relations', 'Onboarding', 'Training & Development', 'Payroll',
      'Compliance', 'Labor Law', 'Succession Planning', 'Compensation Benefits',
    ],
    'Finance Analyst': [
      'Financial Modeling', 'Excel', 'SQL', 'Power BI', 'Tableau', 'Budgeting',
      'Forecasting', 'Accounting', 'SAP', 'Bloomberg', 'Valuation',
      'Risk Analysis', 'DCF Analysis', 'Financial Reporting', 'CFA',
    ],
    'Sales Manager': [
      'B2B Sales', 'CRM', 'Salesforce', 'Negotiation', 'Lead Generation',
      'Account Management', 'Sales Strategy', 'Cold Calling', 'Forecasting',
      'Presentation Skills', 'Customer Retention', 'Pipeline Management',
    ],
    'Teacher': [
      'Curriculum Development', 'Lesson Planning', 'Classroom Management',
      'Assessment Design', 'Differentiated Instruction', 'E-learning',
      'Google Classroom', 'Microsoft Teams', 'Student Engagement',
      'Communication', 'Mentoring', 'Special Education',
    ],
    'Graphic Designer': [
      'Adobe Photoshop', 'Adobe Illustrator', 'InDesign', 'Figma', 'Corel Draw',
      'Typography', 'Branding', 'Print Design', 'Logo Design', 'Color Theory',
      'Motion Graphics', 'After Effects', 'Video Editing',
    ],
    'Content Writer': [
      'Copywriting', 'SEO Writing', 'Blog Writing', 'Technical Writing',
      'Content Strategy', 'WordPress', 'Research', 'Editing', 'Proofreading',
      'Social Media Writing', 'Email Marketing', 'Brand Voice',
    ],
    'Cloud Architect': [
      'AWS', 'Azure', 'GCP', 'Kubernetes', 'Terraform', 'Microservices',
      'Serverless', 'Networking', 'Security', 'Cost Optimization',
      'High Availability', 'Disaster Recovery', 'Docker', 'CI/CD',
    ],
  };

  // ── Common soft skills always shown ───────────────────────────────────────
  static const List<String> softSkills = [
    'Communication', 'Leadership', 'Problem Solving', 'Teamwork',
    'Time Management', 'Adaptability', 'Critical Thinking', 'Creativity',
    'Attention to Detail', 'Project Management', 'Conflict Resolution',
  ];

  // ── All roles (for dropdown/picker) ───────────────────────────────────────
  static List<String> get allRoles => _roleSkills.keys.toList()..sort();

  /// Returns skill suggestions for a given job role/title.
  /// Falls back to a general tech list if role not found.
  static List<String> getSkillsForRole(String role) {
    // Exact match
    if (_roleSkills.containsKey(role)) return _roleSkills[role]!;

    // Partial match
    final lower = role.toLowerCase();
    for (final key in _roleSkills.keys) {
      if (key.toLowerCase().contains(lower) || lower.contains(key.toLowerCase())) {
        return _roleSkills[key]!;
      }
    }

    // Default general skills
    return [
      'Microsoft Office', 'Google Workspace', 'Communication', 'Data Analysis',
      'Project Management', 'Problem Solving', 'Research', 'Presentation Skills',
      'Excel', 'PowerPoint', 'CRM', 'Customer Service', 'Teamwork',
    ];
  }

  /// Returns skills grouped by category for the suggestions panel.
  static Map<String, List<String>> getCategorizedSkills(String role) {
    return {
      'Role-Specific': getSkillsForRole(role),
      'Soft Skills': softSkills,
    };
  }
}
