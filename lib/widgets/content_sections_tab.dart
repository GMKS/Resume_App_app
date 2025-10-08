import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';
import '../widgets/personal_info_section.dart';
import '../widgets/experience_section.dart';
import '../widgets/education_section.dart';
import '../widgets/skills_section.dart';
import '../widgets/projects_section.dart';
import '../widgets/certifications_section.dart';
import '../widgets/languages_section.dart';
import '../widgets/achievements_section.dart';
import '../widgets/references_section.dart';

class ContentSectionsTab extends StatefulWidget {
  final CustomResumeData resumeData;
  final Function(CustomResumeData) onResumeDataChanged;

  const ContentSectionsTab({
    Key? key,
    required this.resumeData,
    required this.onResumeDataChanged,
  }) : super(key: key);

  @override
  _ContentSectionsTabState createState() => _ContentSectionsTabState();
}

class _ContentSectionsTabState extends State<ContentSectionsTab> {
  final Map<String, bool> _sectionExpanded = {
    'personal': true,
    'experience': false,
    'education': false,
    'skills': false,
    'projects': false,
    'certifications': false,
    'languages': false,
    'achievements': false,
    'references': false,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Content Sections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your resume content by filling out the sections below. You can expand or collapse each section as needed.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Personal Information Section
          _buildExpandableSection(
            key: 'personal',
            title: 'Personal Information',
            icon: Icons.person,
            isRequired: true,
            child: PersonalInfoSection(
              resumeData: widget.resumeData,
              onResumeDataChanged: widget.onResumeDataChanged,
            ),
          ),

          // Experience Section
          _buildExpandableSection(
            key: 'experience',
            title: 'Work Experience',
            icon: Icons.work,
            isRequired: true,
            child: ExperienceSection(
              experiences: widget.resumeData.experience,
              onExperiencesChanged: (experiences) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(experience: experiences),
                );
              },
            ),
          ),

          // Education Section
          _buildExpandableSection(
            key: 'education',
            title: 'Education',
            icon: Icons.school,
            isRequired: true,
            child: EducationSection(
              educations: widget.resumeData.education,
              onEducationsChanged: (educations) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(education: educations),
                );
              },
            ),
          ),

          // Skills Section
          _buildExpandableSection(
            key: 'skills',
            title: 'Skills',
            icon: Icons.psychology,
            isRequired: true,
            child: SkillsSection(
              skills: widget.resumeData.skills,
              onSkillsChanged: (skills) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(skills: skills),
                );
              },
            ),
          ),

          // Projects Section
          _buildExpandableSection(
            key: 'projects',
            title: 'Projects',
            icon: Icons.folder_open,
            isRequired: false,
            child: ProjectsSection(
              projects: widget.resumeData.projects,
              onProjectsChanged: (projects) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(projects: projects),
                );
              },
            ),
          ),

          // Certifications Section
          _buildExpandableSection(
            key: 'certifications',
            title: 'Certifications',
            icon: Icons.verified,
            isRequired: false,
            child: CertificationsSection(
              certifications: widget.resumeData.certifications,
              onCertificationsChanged: (certifications) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(certifications: certifications),
                );
              },
            ),
          ),

          // Languages Section
          _buildExpandableSection(
            key: 'languages',
            title: 'Languages',
            icon: Icons.language,
            isRequired: false,
            child: LanguagesSection(
              languages: widget.resumeData.languages,
              onLanguagesChanged: (languages) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(languages: languages),
                );
              },
            ),
          ),

          // Achievements Section
          _buildExpandableSection(
            key: 'achievements',
            title: 'Achievements & Awards',
            icon: Icons.emoji_events,
            isRequired: false,
            child: AchievementsSection(
              achievements: widget.resumeData.achievements,
              onAchievementsChanged: (achievements) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(achievements: achievements),
                );
              },
            ),
          ),

          // References Section
          _buildExpandableSection(
            key: 'references',
            title: 'References',
            icon: Icons.contacts,
            isRequired: false,
            child: ReferencesSection(
              references: widget.resumeData.references,
              showReferences: widget.resumeData.showReferences,
              onReferencesChanged: (references) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(references: references),
                );
              },
              onShowReferencesChanged: (showReferences) {
                widget.onResumeDataChanged(
                  widget.resumeData.copyWith(showReferences: showReferences),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String key,
    required String title,
    required IconData icon,
    required bool isRequired,
    required Widget child,
  }) {
    final isExpanded = _sectionExpanded[key] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _sectionExpanded[key] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: Colors.indigo, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isRequired) ...[
                              const SizedBox(width: 4),
                              const Text(
                                '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isRequired)
                          Text(
                            'Required section',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}
