import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/templates/screens/template_selection_screen.dart';

const _templateLimit = int.fromEnvironment('TEMPLATE_LIMIT', defaultValue: 0);

class _TemplateThumbnailSpec {
  const _TemplateThumbnailSpec({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.hasPhoto,
  });

  final String id;
  final String name;
  final Color primaryColor;
  final bool hasPhoto;
}

const _templateSpecs = <_TemplateThumbnailSpec>[
  _TemplateThumbnailSpec(
    id: 'modern',
    name: 'Modern Nova',
    primaryColor: Color(0xFF6366F1),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'classic',
    name: 'Classic',
    primaryColor: Color(0xFF0F172A),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'creative',
    name: 'Creative',
    primaryColor: Color(0xFFF59E0B),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'minimal',
    name: 'Minimal',
    primaryColor: Color(0xFF64748B),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'developer',
    name: 'Developer',
    primaryColor: Color(0xFF8B5CF6),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'two_column',
    name: 'Two Column',
    primaryColor: Color(0xFF14B8A6),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'elegant_pink',
    name: 'Pink Rose Modern',
    primaryColor: Color(0xFFD87093),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'blue_gray',
    name: 'FlexColor Sidebar',
    primaryColor: Color(0xFF343D4D),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'professional',
    name: 'Professional',
    primaryColor: Color(0xFF5A607D),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'executive',
    name: 'Business Management Resume',
    primaryColor: Color(0xFF1E293B),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'startup',
    name: 'Startup',
    primaryColor: Color(0xFFEF4444),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'academic',
    name: 'Academic',
    primaryColor: Color(0xFF3730A3),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'sales',
    name: 'Sales & Marketing',
    primaryColor: Color(0xFFD946EF),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'modern_aesthetic',
    name: 'SharpLine Resume',
    primaryColor: Color(0xFFC3A97E),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'classic2',
    name: 'Classic Plus',
    primaryColor: Color(0xFF272727),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'education_resume',
    name: 'Education Resume',
    primaryColor: Color(0xFF333C4D),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'modern_resume',
    name: 'Elite Resume',
    primaryColor: Color(0xFF35354A),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'professional_accountant',
    name: 'Prof Accountant',
    primaryColor: Color(0xFF242527),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'one_page_resume',
    name: 'One Page Resume',
    primaryColor: Color(0xFF94A5CB),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'classic_temp',
    name: 'Classic Temp',
    primaryColor: Color(0xFF6189BF),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'emerald_executive',
    name: 'Emerald Executive',
    primaryColor: Color(0xFF10B981),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'cool_blue',
    name: 'VividPro',
    primaryColor: Color(0xFF0EA5E9),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'multicolor',
    name: 'MultiColor',
    primaryColor: Color(0xFFEC4899),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'entry_level',
    name: 'Entry Level',
    primaryColor: Color(0xFF2E7D6B),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'ats_optimized_clean',
    name: 'ATS Optimized Clean',
    primaryColor: Color(0xFF1F2937),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'ats_standard_format',
    name: 'ATS Standard Format',
    primaryColor: Color(0xFF374151),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'ats_friendly_modern',
    name: 'ATS Friendly Modern',
    primaryColor: Color(0xFF2D3748),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'executive_classic',
    name: 'Executive Classic',
    primaryColor: Color(0xFF1B3A5C),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'classic_ats',
    name: 'Classic ATS Optimized',
    primaryColor: Color(0xFF1A1A2E),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'infographic',
    name: 'Infographic',
    primaryColor: Color(0xFF7DAFC0),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'vertical_timeline',
    name: 'Vertical Timeline',
    primaryColor: Color(0xFF2A6B7C),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'corporate_template',
    name: 'Corporate Template',
    primaryColor: Color(0xFF334155),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'mono_nova',
    name: 'Black and White',
    primaryColor: Color(0xFF57534E),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'slate_arc',
    name: 'Slate Arc',
    primaryColor: Color(0xFF7A818C),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'editorial_frame',
    name: 'Editorial Frame',
    primaryColor: Color(0xFFB08863),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'graphite_column',
    name: 'Graphite Column',
    primaryColor: Color(0xFF55565A),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'rosewood_panel',
    name: 'Rosewood Panel',
    primaryColor: Color(0xFFC7A09B),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'designer_profile',
    name: 'Design Creative Resume',
    primaryColor: Color(0xFF35569C),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'modern_edge',
    name: 'Persona Pro CV',
    primaryColor: Color(0xFF6CB38E),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'minimal_clean',
    name: 'Minimal Clean',
    primaryColor: Color(0xFF8FB0D6),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'minimal_clean_ats',
    name: 'Minimal Clean ATS',
    primaryColor: Color(0xFF7D2E2C),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'professional_tone',
    name: 'HealthCare Resume',
    primaryColor: Color(0xFF516785),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'elegant_design',
    name: 'Elegant Design',
    primaryColor: Color(0xFFC9935B),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'creative_professional',
    name: 'Creative Professional',
    primaryColor: Color(0xFF2D8C87),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'bluewave_tech',
    name: 'Bluewave Tech',
    primaryColor: Color(0xFF2F66B0),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'balanced_two_column_layout',
    name: 'Balanced Two Column Layout',
    primaryColor: Color(0xFFB28B5C),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'elegant_gold_layout',
    name: 'Human Resources Resume',
    primaryColor: Color(0xFFC29A55),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'corporate_navy',
    name: 'Corporate Navy',
    primaryColor: Color(0xFF2F4F75),
    hasPhoto: true,
  ),
  _TemplateThumbnailSpec(
    id: 'forest_edge',
    name: 'Forest Edge',
    primaryColor: Color(0xFF9AA7B4),
    hasPhoto: false,
  ),
  _TemplateThumbnailSpec(
    id: 'forest_edge_classic',
    name: 'Forest Edge Classic',
    primaryColor: Color(0xFFAEB8C2),
    hasPhoto: false,
  ),
];

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _TemplateThumbnailCatalogApp());
}

class _TemplateThumbnailCatalogApp extends StatelessWidget {
  const _TemplateThumbnailCatalogApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _TemplateThumbnailCatalogScreen(),
    );
  }
}

class _TemplateThumbnailCatalogScreen extends StatelessWidget {
  const _TemplateThumbnailCatalogScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = _templateLimit > 0
        ? _templateSpecs.take(_templateLimit).toList(growable: false)
        : _templateSpecs;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Template Catalog',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${templates.length} marketing-ready previews rendered from the in-app template widgets.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth >= 1500
                        ? 5
                        : constraints.maxWidth >= 1180
                            ? 4
                            : constraints.maxWidth >= 860
                                ? 3
                                : 2;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: templates.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 22,
                        mainAxisSpacing: 22,
                        childAspectRatio: 0.76,
                      ),
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        final resume = _buildMarketingResume(
                          template.id,
                          profileImageBase64: '',
                          colorScheme: _nearestColorScheme(template.primaryColor),
                        );

                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0x140F172A),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Center(
                                    child: TemplatePreviewThumbnail(
                                      templateId: template.id,
                                      accentColor: template.primaryColor,
                                      width: 170,
                                      showShadow: false,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(18),
                                      ),
                                      resume: resume,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  template.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: template.primaryColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    template.hasPhoto ? 'With Photo' : 'Without Photo',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: template.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ResumeModel _buildMarketingResume(
  String templateId, {
  required String profileImageBase64,
  required int colorScheme,
}) {
  final now = DateTime(2026, 5, 18);
  return ResumeModel(
    id: 'marketing-preview-$templateId',
    title: 'Marketing Thumbnail Resume',
    personalInfo: PersonalInfo(
      fullName: 'Avery Morgan',
      email: 'avery.morgan@example.com',
      phone: '+1 415 555 0137',
      address: 'San Francisco, CA',
      linkedIn: 'linkedin.com/in/averymorgan',
      github: 'github.com/averymorgan',
      website: 'averymorgan.design',
      jobTitle: 'Senior Product Designer',
      profileImage: profileImageBase64,
    ),
    objective:
        'Senior product designer blending hiring strategy, visual storytelling, and structured content systems to create resumes that feel polished, credible, and conversion-ready.',
    education: <Education>[
      Education(
        id: 'edu-$templateId',
        institution: 'California College of the Arts',
        degree: 'B.Des.',
        fieldOfStudy: 'Interaction Design',
        startDate: DateTime(2014, 8, 1),
        endDate: DateTime(2018, 5, 1),
        grade: '3.9 GPA',
        description:
            'Focused on editorial systems, product UX, and digital portfolio strategy.',
      ),
    ],
    experience: <Experience>[
      Experience(
        id: 'exp-1-$templateId',
        company: 'Northstar Labs',
        position: 'Senior Product Designer',
        location: 'Remote',
        startDate: DateTime(2022, 2, 1),
        isCurrentlyWorking: true,
        description:
            'Leads resume workflow design, template systems, and acquisition-focused user journeys for mobile and web.',
        achievements: const <String>[
          'Increased completed resume exports by 38% after redesigning the editor flow.',
          'Shipped a premium template catalog used in marketing campaigns and product launches.',
        ],
      ),
      Experience(
        id: 'exp-2-$templateId',
        company: 'BrightHire Studio',
        position: 'Product Designer',
        location: 'San Jose, CA',
        startDate: DateTime(2019, 6, 1),
        endDate: DateTime(2022, 1, 1),
        description:
            'Designed recruiting dashboards, onboarding flows, and mobile-first professional profile experiences.',
        achievements: const <String>[
          'Reduced profile-completion drop-off by 24% with a clearer onboarding structure.',
        ],
      ),
    ],
    skills: <Skill>[
      Skill(id: 'skill-1', name: 'Product Strategy'),
      Skill(id: 'skill-2', name: 'Visual Design'),
      Skill(id: 'skill-3', name: 'Design Systems'),
      Skill(id: 'skill-4', name: 'Figma'),
      Skill(id: 'skill-5', name: 'Storytelling'),
      Skill(id: 'skill-6', name: 'User Research'),
    ],
    projects: <Project>[
      Project(
        id: 'project-$templateId',
        title: 'Resume Studio Redesign',
        description:
            'Redesigned a resume editor with modular sections, instant previews, and one-tap export.',
        technologies: const <String>['Flutter', 'Firebase', 'Figma'],
        url: 'https://example.com/resume-studio',
      ),
      Project(
        id: 'project-2-$templateId',
        title: 'AI Cover Letter Assistant',
        description:
            'Created a guided AI flow for generating tailored cover letters from resume data.',
        technologies: const <String>['Prompt Design', 'Analytics'],
        url: 'https://example.com/cover-letter-assistant',
      ),
    ],
    certifications: <Certification>[
      Certification(
        id: 'cert-$templateId',
        name: 'Google UX Design Certificate',
        issuer: 'Google',
        issueDate: DateTime(2021, 10, 1),
      ),
    ],
    languages: <Language>[
      Language(id: 'lang-1', name: 'English', proficiency: 'Native'),
      Language(id: 'lang-2', name: 'Spanish', proficiency: 'Professional'),
    ],
    hobbies: const <String>['Mentoring', 'Photography', 'Travel'],
    customSections: <CustomSection>[
      CustomSection(
        id: 'leadership_highlights',
        title: 'Leadership Highlights',
        items: <CustomSectionItem>[
          CustomSectionItem(
            id: 'leadership-1',
            title: 'Cross-Functional Delivery',
            description:
                'Directed design, content, and growth teams through launches tied to conversion targets.',
          ),
          CustomSectionItem(
            id: 'leadership-2',
            title: 'Visual Systems',
            description:
                'Built reusable template patterns that kept marketing and product visuals aligned.',
          ),
        ],
      ),
    ],
    templateId: templateId,
    createdAt: now,
    updatedAt: now,
    colorScheme: colorScheme,
  );
}

Future<String> _buildMarketingProfileImageBase64() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(600, 760);
  final rect = Offset.zero & size;

  final backgroundPaint = Paint()
    ..shader = const LinearGradient(
      colors: <Color>[
        Color(0xFF152238),
        Color(0xFF294B70),
        Color(0xFFD9A57A),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(rect);

  canvas.drawRect(rect, backgroundPaint);

  final haloPaint = Paint()..color = const Color(0x33FFFFFF);
  canvas.drawCircle(const Offset(450, 180), 180, haloPaint);

  final shoulderPaint = Paint()..color = const Color(0xFFE7B58E);
  final jacketPaint = Paint()..color = const Color(0xFF1D2C45);
  final shirtPaint = Paint()..color = const Color(0xFFF5F0E8);
  final hairPaint = Paint()..color = const Color(0xFF23160F);

  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(42)),
    Paint()..color = const Color(0x14000000),
  );

  canvas.drawOval(
    Rect.fromCenter(center: const Offset(300, 265), width: 210, height: 260),
    shoulderPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(300, 205), width: 228, height: 245),
    hairPaint,
  );
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(300, 530), width: 360, height: 280),
    jacketPaint,
  );
  canvas.drawPath(
    Path()
      ..moveTo(240, 410)
      ..lineTo(360, 410)
      ..lineTo(300, 565)
      ..close(),
    shirtPaint,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return base64Encode(byteData!.buffer.asUint8List());
}

String _slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

int _nearestColorScheme(Color color) {
  const palette = <Color>[
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFF64748B),
  ];

  var bestIndex = 0;
  var bestDistance = double.infinity;

  for (var index = 0; index < palette.length; index++) {
    final candidate = palette[index];
    final distance = _colorDistance(color, candidate);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = index;
    }
  }

  return bestIndex;
}

double _colorDistance(Color left, Color right) {
  final red = left.r - right.r;
  final green = left.g - right.g;
  final blue = left.b - right.b;
  return (red * red) + (green * green) + (blue * blue);
}