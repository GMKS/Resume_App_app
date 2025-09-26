/// Pre-written content and guided resume creation service
/// Optimized for minimal APK size with embedded content
class PrewrittenContentService {
  static final PrewrittenContentService _instance =
      PrewrittenContentService._internal();
  factory PrewrittenContentService() => _instance;
  PrewrittenContentService._internal();

  /// Professional summary templates by industry
  static Map<String, List<String>> get summaryTemplates => {
    'Technology': [
      'Experienced software developer with [X] years of expertise in [Technologies]. Proven track record of delivering scalable applications and leading development teams.',
      'Full-stack developer specializing in [Technologies] with strong problem-solving skills and passion for clean, efficient code.',
      'Senior developer with expertise in [Technologies]. Successfully managed projects from conception to deployment with focus on user experience.',
    ],
    'Healthcare': [
      'Dedicated healthcare professional with [X] years of experience providing compassionate patient care and clinical expertise.',
      'Licensed [Profession] committed to improving patient outcomes through evidence-based practice and collaborative care.',
      'Healthcare specialist with proven ability to work effectively in fast-paced environments while maintaining high standards of care.',
    ],
    'Finance': [
      'Financial analyst with [X] years of experience in financial modeling, risk assessment, and investment analysis.',
      'CPA with expertise in financial reporting, tax planning, and compliance. Strong analytical skills with attention to detail.',
      'Finance professional specializing in [Area] with proven track record of improving financial performance and reducing costs.',
    ],
    'Marketing': [
      'Creative marketing professional with [X] years of experience developing successful campaigns that drive brand awareness and sales.',
      'Digital marketing specialist with expertise in SEO, social media, and content marketing. Data-driven approach to strategy.',
      'Marketing manager with proven ability to lead cross-functional teams and deliver results-oriented marketing initiatives.',
    ],
    'Education': [
      'Passionate educator with [X] years of experience creating engaging learning environments and improving student outcomes.',
      'Certified teacher specializing in [Subject] with strong classroom management skills and commitment to student success.',
      'Educational professional dedicated to fostering critical thinking and lifelong learning in diverse student populations.',
    ],
  };

  /// Action verbs by category for achievements
  static Map<String, List<String>> get actionVerbs => {
    'Leadership': [
      'Led',
      'Managed',
      'Supervised',
      'Directed',
      'Coordinated',
      'Mentored',
      'Guided',
      'Facilitated',
      'Spearheaded',
      'Orchestrated',
    ],
    'Achievement': [
      'Achieved',
      'Accomplished',
      'Exceeded',
      'Delivered',
      'Completed',
      'Attained',
      'Realized',
      'Secured',
      'Earned',
      'Won',
    ],
    'Improvement': [
      'Improved',
      'Enhanced',
      'Optimized',
      'Streamlined',
      'Upgraded',
      'Modernized',
      'Refined',
      'Strengthened',
      'Boosted',
      'Increased',
    ],
    'Creation': [
      'Developed',
      'Created',
      'Designed',
      'Built',
      'Established',
      'Launched',
      'Implemented',
      'Initiated',
      'Founded',
      'Pioneered',
    ],
    'Analysis': [
      'Analyzed',
      'Evaluated',
      'Assessed',
      'Researched',
      'Investigated',
      'Examined',
      'Reviewed',
      'Studied',
      'Measured',
      'Monitored',
    ],
  };

  /// Skills by industry and level
  static Map<String, Map<String, List<String>>> get skillsDatabase => {
    'Technology': {
      'Programming': [
        'Python',
        'Java',
        'JavaScript',
        'C++',
        'React',
        'Node.js',
        'Angular',
      ],
      'Databases': ['MySQL', 'PostgreSQL', 'MongoDB', 'Redis', 'Elasticsearch'],
      'Cloud': ['AWS', 'Azure', 'Google Cloud', 'Docker', 'Kubernetes'],
      'Tools': ['Git', 'Jenkins', 'JIRA', 'Agile', 'Scrum'],
    },
    'Healthcare': {
      'Clinical': [
        'Patient Care',
        'Medical Records',
        'Clinical Assessment',
        'Treatment Planning',
      ],
      'Technical': [
        'EMR Systems',
        'Medical Equipment',
        'Laboratory Procedures',
      ],
      'Soft Skills': [
        'Communication',
        'Empathy',
        'Critical Thinking',
        'Team Collaboration',
      ],
    },
    'Finance': {
      'Analysis': [
        'Financial Modeling',
        'Risk Analysis',
        'Investment Analysis',
        'Budgeting',
      ],
      'Software': [
        'Excel',
        'QuickBooks',
        'SAP',
        'Bloomberg Terminal',
        'Tableau',
      ],
      'Compliance': ['GAAP', 'SOX', 'Risk Management', 'Audit Procedures'],
    },
    'Marketing': {
      'Digital': [
        'SEO',
        'Google Analytics',
        'Social Media',
        'Content Marketing',
        'Email Marketing',
      ],
      'Creative': [
        'Adobe Creative Suite',
        'Copywriting',
        'Brand Management',
        'Graphic Design',
      ],
      'Strategy': [
        'Market Research',
        'Campaign Development',
        'A/B Testing',
        'ROI Analysis',
      ],
    },
  };

  /// Achievement templates with placeholders
  static List<String> get achievementTemplates => [
    'Increased [metric] by [percentage]% through [action/method]',
    'Reduced [cost/time] by [amount/percentage] by implementing [solution]',
    'Led team of [number] professionals to deliver [project/outcome]',
    'Managed budget of \$[amount] for [project/department]',
    'Improved [process/system] resulting in [quantifiable benefit]',
    'Developed [solution/product] that generated \$[revenue/savings]',
    'Trained [number] employees in [skill/system]',
    'Exceeded [target/goal] by [percentage]% for [time period]',
    'Streamlined [process] reducing [metric] by [percentage]%',
    'Collaborated with [stakeholders] to achieve [outcome]',
  ];

  /// Job responsibility templates by level
  static Map<String, List<String>> get responsibilityTemplates => {
    'Entry Level': [
      'Assisted with [task/project] under supervision of senior staff',
      'Supported daily operations by [specific activities]',
      'Participated in [meetings/training] to develop [skills]',
      'Maintained [systems/records] with high accuracy',
      'Contributed to team goals by [specific contributions]',
    ],
    'Mid Level': [
      'Managed [projects/processes] from initiation to completion',
      'Collaborated with cross-functional teams to [achieve goals]',
      'Analyzed [data/metrics] to identify improvement opportunities',
      'Mentored junior staff in [areas of expertise]',
      'Implemented [solutions/processes] to enhance [outcomes]',
    ],
    'Senior Level': [
      'Directed strategic initiatives across [departments/functions]',
      'Established policies and procedures for [area of responsibility]',
      'Built relationships with key stakeholders to [achieve objectives]',
      'Oversaw budget of \$[amount] for [department/projects]',
      'Led organizational change initiatives resulting in [outcomes]',
    ],
  };

  /// Industry-specific keywords for ATS optimization
  static Map<String, List<String>> get industryKeywords => {
    'Technology': [
      'Software Development',
      'Agile',
      'Scrum',
      'DevOps',
      'API',
      'Database',
      'Mobile Development',
      'Web Development',
      'Cloud Computing',
      'Machine Learning',
    ],
    'Healthcare': [
      'Patient Care',
      'Clinical',
      'Healthcare',
      'Medical',
      'Treatment',
      'Diagnosis',
      'Healthcare Technology',
      'Compliance',
      'Safety',
      'Quality',
    ],
    'Finance': [
      'Financial Analysis',
      'Investment',
      'Portfolio',
      'Risk Management',
      'Compliance',
      'Audit',
      'Budgeting',
      'Forecasting',
      'Financial Reporting',
    ],
    'Marketing': [
      'Digital Marketing',
      'Brand Management',
      'Campaign',
      'ROI',
      'Analytics',
      'Social Media',
      'Content Marketing',
      'Lead Generation',
      'Market Research',
    ],
  };

  /// Get personalized suggestions based on user input
  static List<String> getSummarysuggestions(String industry, int experience) {
    List<String> templates =
        summaryTemplates[industry] ?? summaryTemplates['Technology']!;
    return templates
        .map((template) => template.replaceAll('[X]', experience.toString()))
        .toList();
  }

  /// Get relevant skills for industry
  static List<String> getSkillSuggestions(String industry) {
    Map<String, List<String>>? industrySkills = skillsDatabase[industry];
    if (industrySkills == null) return [];

    List<String> allSkills = [];
    for (var skillList in industrySkills.values) {
      allSkills.addAll(skillList);
    }
    return allSkills;
  }

  /// Get achievement templates with context
  static List<String> getAchievementSuggestions(String jobLevel) {
    List<String> baseTemplates = achievementTemplates;
    List<String> responsibilities = responsibilityTemplates[jobLevel] ?? [];

    return [...baseTemplates, ...responsibilities];
  }

  /// Get summary templates for industry and experience level
  List<String> getSummaryTemplates(String industry, String experienceLevel) {
    List<String> templates =
        summaryTemplates[industry] ?? summaryTemplates['Technology']!;

    // Customize based on experience level
    return templates.map((template) {
      String experience = experienceLevel == 'Entry-Level'
          ? '2-3'
          : experienceLevel == 'Mid-Level'
          ? '5-7'
          : experienceLevel == 'Senior-Level'
          ? '8-12'
          : '15+';
      return template.replaceAll('[X]', experience);
    }).toList();
  }

  /// Get skills database for industry
  Map<String, List<String>> getSkillsDatabase(String industry) {
    return skillsDatabase[industry] ?? skillsDatabase['Technology']!;
  }

  /// Get achievement templates
  List<String> getAchievementTemplates(String industry) {
    // Return all achievement templates - can be customized by industry in future
    return achievementTemplates;
  }

  /// Get action verbs for specific context
  static List<String> getActionVerbs(String context) {
    return actionVerbs[context] ?? actionVerbs['Achievement']!;
  }

  /// Get ATS-friendly keywords
  static List<String> getATSKeywords(String industry) {
    return industryKeywords[industry] ?? [];
  }

  /// Content guidance by section
  static Map<String, String> get sectionGuidance => {
    'Personal Info':
        'Include your full name, professional email, phone number, and city/state. LinkedIn profile is recommended.',
    'Summary':
        'Write 2-3 sentences highlighting your key qualifications and career goals. Focus on what makes you unique.',
    'Experience':
        'List in reverse chronological order. Use action verbs and quantify achievements with numbers, percentages, or dollar amounts.',
    'Education':
        'Include degree, institution, graduation year. Add GPA if 3.5 or higher. Include relevant coursework for recent graduates.',
    'Skills':
        'Mix of hard and soft skills relevant to your target role. Prioritize skills mentioned in job descriptions.',
    'Projects':
        'Showcase relevant projects with brief descriptions of your role, technologies used, and outcomes achieved.',
    'Certifications':
        'List current, relevant certifications with issuing organization and date. Include renewal dates if applicable.',
  };

  /// Resume tips by section
  static Map<String, List<String>> get resumeTips => {
    'General': [
      'Keep it to 1-2 pages maximum',
      'Use consistent formatting throughout',
      'Proofread carefully for spelling and grammar',
      'Tailor your resume for each job application',
      'Use professional fonts (Arial, Calibri, Times New Roman)',
    ],
    'Experience': [
      'Start each bullet point with an action verb',
      'Quantify achievements with specific numbers',
      'Focus on results, not just responsibilities',
      'Use past tense for previous roles, present for current',
      'Include 3-5 bullet points per role',
    ],
    'Skills': [
      'Group similar skills together',
      'List most relevant skills first',
      'Be honest about your skill level',
      'Include both technical and soft skills',
      'Match skills to job requirements',
    ],
  };
}
