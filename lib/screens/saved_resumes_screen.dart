import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/resume_storage_service.dart';
import '../models/saved_resume.dart';
import '../models/custom_resume_data.dart';
import '../services/premium_service.dart';
import '../services/share_export_service.dart';
import 'modern_resume_preview.dart';
import 'classic_resume_preview.dart';
import 'modern_resume_form_screen.dart';
import 'classic_resume_form_screen.dart';
import 'minimal_resume_form_screen.dart';
import 'professional_resume_form_screen.dart';
import 'professional_resume_preview.dart';
import 'creative_resume_form_screen.dart';
import 'one_page_resume_form_screen.dart';
import 'one_page_resume_preview.dart';
import 'creative_resume_preview.dart';
import 'customize_screen.dart';

class SavedResumesScreen extends StatelessWidget {
  const SavedResumesScreen({super.key});

  // Helper method to navigate to appropriate edit screen
  void _navigateToEditScreen(BuildContext context, SavedResume resume) {
    Widget screen;
    final template = resume.template.toLowerCase();

    switch (template) {
      case 'modern':
        screen = ModernResumeFormScreen(existingResume: resume);
        break;
      case 'classic':
        screen = ClassicResumeFormScreen(existing: resume);
        break;
      case 'minimal':
        screen = MinimalResumeFormScreen(existing: resume);
        break;
      case 'professional':
        screen = ProfessionalResumeFormScreen(existing: resume);
        break;
      case 'creative':
        screen = CreativeResumeFormScreen(existing: resume);
        break;
      case 'one page':
        screen = OnePageResumeFormScreen(existing: resume);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template ${resume.template} not supported yet'),
          ),
        );
        return;
    }

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  // Helper method to navigate to appropriate preview screen
  void _navigateToPreviewScreen(BuildContext context, SavedResume resume) {
    Widget screen;
    final template = resume.template.toLowerCase();

    switch (template) {
      case 'modern':
        screen = ModernResumePreview(resume: resume);
        break;
      case 'classic':
        screen = ClassicResumePreview(resume: resume);
        break;
      case 'professional':
        screen = ProfessionalResumePreview(resume: resume);
        break;
      case 'creative':
        screen = CreativeResumePreview(resume: resume);
        break;
      case 'one page':
        screen = OnePageResumePreview(resume: resume);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preview not available for ${resume.template} yet'),
          ),
        );
        return;
    }

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<SavedResume>>(
        valueListenable: ResumeStorageService.instance.resumes,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No resumes yet. Save one to see it here.'),
            );
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = list[index];
              return ListTile(
                leading: const Icon(Icons.description),
                title: Text(r.title),
                subtitle: Text(
                  '${r.template} • Updated ${_formatTime(r.updatedAt)}',
                ),
                onTap: () => _navigateToEditScreen(context, r),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        _navigateToEditScreen(context, r);
                        break;
                      case 'save':
                        // Force update timestamp
                        final updated = r.copyWith(updatedAt: DateTime.now());
                        await ResumeStorageService.instance.saveOrUpdate(
                          updated,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved')),
                          );
                        }
                        break;
                      case 'export_pdf':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Export');
                          return;
                        }
                        await ShareExportService(context).exportAndOpenPdf(r);
                        break;
                      case 'export_docx':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Export');
                          return;
                        }
                        await ShareExportService(context).exportAndOpenDocx(r);
                        break;
                      case 'preview':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Preview');
                          return;
                        }
                        _navigateToPreviewScreen(context, r);
                        break;
                      case 'share_email':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Sharing');
                          return;
                        }
                        await ShareExportService(context).shareViaEmail(r);
                        break;
                      case 'print':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Print');
                          return;
                        }
                        await ShareExportService(context).printResume(r);
                        break;
                      case 'customize':
                        if (context.mounted) {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomizeScreen(
                                initialResumeData: _convertToCustomResumeData(
                                  r,
                                ),
                                originalResume: r,
                              ),
                            ),
                          );

                          // If customizations were saved, refresh the list
                          if (result == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Resume customizations saved!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                        break;
                      case 'delete':
                        await ResumeStorageService.instance.deleteResume(r.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Deleted')),
                          );
                        }
                        break;
                      case 'share_whatsapp':
                        if (!PremiumService.isPremium) {
                          PremiumService.showUpgradeDialog(context, 'Sharing');
                          return;
                        }
                        await ShareExportService(context).shareViaWhatsApp(r);
                        break;
                    }
                  },
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<String>>[
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'save',
                        child: ListTile(
                          leading: Icon(Icons.save_outlined),
                          title: Text('Save'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'customize',
                        child: ListTile(
                          leading: Icon(Icons.palette),
                          title: Text('Customize'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ];

                    if (PremiumService.isPremium) {
                      items.addAll(const [
                        PopupMenuItem(
                          value: 'export_pdf',
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf),
                            title: Text('Export PDF'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'export_docx',
                          child: ListTile(
                            leading: Icon(Icons.description),
                            title: Text('Export DOCX'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share_whatsapp',
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text('Share via WhatsApp'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'preview',
                          child: ListTile(
                            leading: Icon(Icons.visibility_outlined),
                            title: Text('Preview'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'share_email',
                          child: ListTile(
                            leading: Icon(Icons.email_outlined),
                            title: Text('Share via Email'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: ListTile(
                            leading: Icon(Icons.print_outlined),
                            title: Text('Print'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ]);
                    }

                    items.add(
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    );

                    return items;
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  CustomResumeData _convertToCustomResumeData(SavedResume resume) {
    final data = resume.data;
    final personalInfo = data['personalInfo'] as Map<String, dynamic>? ?? {};

    return CustomResumeData(
      fullName: personalInfo['fullName'] ?? personalInfo['name'] ?? '',
      jobTitle: personalInfo['jobTitle'] ?? personalInfo['title'] ?? '',
      contactInfo: ContactInfo(
        email: personalInfo['email'] ?? '',
        phone: personalInfo['phone'] ?? '',
        linkedin: personalInfo['linkedin'] ?? personalInfo['linkedIn'] ?? '',
        website: personalInfo['website'] ?? personalInfo['portfolio'] ?? '',
        location: personalInfo['location'] ?? personalInfo['address'] ?? '',
      ),
      summary: data['summary'] ?? data['profile'] ?? '',
      skills: _convertSkills(data),
      experience: _convertExperience(data),
      education: _convertEducation(data),
      certifications: _convertCertifications(data),
      projects: _convertProjects(data),
      languages: _convertLanguages(data),
      hobbies: _convertHobbies(data),
      achievements: _convertAchievements(data),
      references: _convertReferences(data),
      showReferences: data['showReferences'] ?? false,
    );
  }

  List<Skill> _convertSkills(Map<String, dynamic> data) {
    final skillsList = <Skill>[];

    // Handle different skill formats
    if (data['skills'] != null) {
      final skills = data['skills'];
      if (skills is List) {
        for (final skill in skills) {
          if (skill is String) {
            skillsList.add(Skill(name: skill));
          } else if (skill is Map) {
            skillsList.add(
              Skill(
                name: skill['name'] ?? skill['skill'] ?? '',
                proficiency: _parseSkillProficiency(skill['level']),
                category: skill['category'] ?? 'General',
              ),
            );
          }
        }
      } else if (skills is String) {
        // Handle CSV format like "Java,Python,Flutter"
        final skillNames = skills
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        for (final name in skillNames) {
          skillsList.add(Skill(name: name));
        }
      }
    }

    // Handle coreSkills from One Page template
    if (data['coreSkills'] != null && data['coreSkills'] is String) {
      final coreSkills = (data['coreSkills'] as String)
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final name in coreSkills) {
        if (!skillsList.any((s) => s.name == name)) {
          skillsList.add(Skill(name: name, proficiency: 0.8));
        }
      }
    }

    return skillsList;
  }

  double? _parseSkillProficiency(dynamic level) {
    if (level == null) return null;
    final levelStr = level.toString().toLowerCase();
    switch (levelStr) {
      case 'beginner':
      case 'basic':
        return 0.3;
      case 'intermediate':
      case 'medium':
        return 0.6;
      case 'advanced':
      case 'expert':
        return 0.9;
      default:
        return null;
    }
  }

  List<Experience> _convertExperience(Map<String, dynamic> data) {
    final experienceList = <Experience>[];

    // Handle workExperience
    if (data['workExperience'] != null && data['workExperience'] is List) {
      for (final exp in data['workExperience'] as List) {
        if (exp is Map) {
          experienceList.add(
            Experience(
              jobTitle:
                  exp['jobTitle'] ?? exp['position'] ?? exp['title'] ?? '',
              companyName: exp['company'] ?? exp['employer'] ?? '',
              location: exp['location'] ?? '',
              startDate: _parseDate(exp['startDate']),
              endDate: _parseDate(exp['endDate']),
              isCurrentJob:
                  exp['endDate'] == null ||
                  exp['endDate'] == '' ||
                  exp['endDate'].toString().toLowerCase().contains('present'),
              description: exp['description'] ?? '',
            ),
          );
        }
      }
    }

    // Handle One Page template workExperiencesJson
    if (data['workExperiencesJson'] != null &&
        data['workExperiencesJson'] is String) {
      try {
        final workExps = jsonDecode(data['workExperiencesJson']) as List;
        for (final exp in workExps) {
          if (exp is Map) {
            experienceList.add(
              Experience(
                jobTitle: exp['jobTitle'] ?? '',
                companyName: exp['company'] ?? '',
                location: exp['location'] ?? '',
                startDate: _parseDate(exp['startDate']),
                endDate: _parseDate(exp['endDate']),
                isCurrentJob:
                    exp['endDate'] == null ||
                    exp['endDate'] == '' ||
                    exp['endDate'].toString().toLowerCase().contains('present'),
                description: exp['description'] ?? '',
              ),
            );
          }
        }
      } catch (e) {
        // Handle JSON parsing error
      }
    }

    return experienceList;
  }

  DateTime? _parseDate(dynamic dateStr) {
    if (dateStr == null || dateStr == '') return null;
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return null;
    }
  }

  List<Education> _convertEducation(Map<String, dynamic> data) {
    final educationList = <Education>[];

    // Handle education array
    if (data['education'] != null && data['education'] is List) {
      for (final edu in data['education'] as List) {
        if (edu is Map) {
          educationList.add(
            Education(
              degree: edu['degree'] ?? edu['qualification'] ?? '',
              institution:
                  edu['institution'] ??
                  edu['university'] ??
                  edu['school'] ??
                  '',
              startDate: _parseDate(edu['startDate']),
              endDate: _parseDate(edu['endDate']),
              description: edu['description'] ?? '',
            ),
          );
        }
      }
    }

    // Handle One Page template educationsJson
    if (data['educationsJson'] != null && data['educationsJson'] is String) {
      try {
        final educations = jsonDecode(data['educationsJson']) as List;
        for (final edu in educations) {
          if (edu is Map) {
            educationList.add(
              Education(
                degree: edu['degree'] ?? '',
                institution:
                    edu['institution'] ??
                    edu['university'] ??
                    edu['school'] ??
                    '',
                startDate: _parseDate(edu['startDate']),
                endDate: _parseDate(edu['endDate']),
                description: edu['description'] ?? '',
              ),
            );
          }
        }
      } catch (e) {
        // Handle JSON parsing error
      }
    }

    return educationList;
  }

  List<Certification> _convertCertifications(Map<String, dynamic> data) {
    final certificationList = <Certification>[];

    if (data['certifications'] != null && data['certifications'] is List) {
      for (final cert in data['certifications'] as List) {
        if (cert is Map) {
          certificationList.add(
            Certification(
              name: cert['name'] ?? cert['title'] ?? '',
              issuer: cert['issuer'] ?? cert['organization'] ?? '',
              issueDate: _parseDate(cert['date'] ?? cert['issueDate']),
              expiryDate: _parseDate(cert['expiryDate']),
              credentialId: cert['credentialId'] ?? cert['id'] ?? '',
            ),
          );
        }
      }
    }

    return certificationList;
  }

  List<Project> _convertProjects(Map<String, dynamic> data) {
    final projectList = <Project>[];

    if (data['projects'] != null && data['projects'] is List) {
      for (final proj in data['projects'] as List) {
        if (proj is Map) {
          projectList.add(
            Project(
              title: proj['name'] ?? proj['title'] ?? '',
              description: proj['description'] ?? '',
              technologies: _parseStringList(proj['technologies']),
              startDate: _parseDate(proj['startDate']),
              endDate: _parseDate(proj['endDate']),
              projectUrl: proj['url'] ?? proj['link'] ?? '',
            ),
          );
        }
      }
    }

    return projectList;
  }

  List<Language> _convertLanguages(Map<String, dynamic> data) {
    final languageList = <Language>[];

    if (data['languages'] != null && data['languages'] is List) {
      for (final lang in data['languages'] as List) {
        if (lang is Map) {
          languageList.add(
            Language(
              name: lang['name'] ?? lang['language'] ?? '',
              proficiency:
                  lang['proficiency'] ?? lang['level'] ?? 'Intermediate',
            ),
          );
        } else if (lang is String) {
          languageList.add(Language(name: lang, proficiency: 'Intermediate'));
        }
      }
    }

    return languageList;
  }

  List<String> _convertHobbies(Map<String, dynamic> data) {
    if (data['hobbies'] != null) {
      return _parseStringList(data['hobbies']);
    }
    return [];
  }

  List<Achievement> _convertAchievements(Map<String, dynamic> data) {
    final achievementList = <Achievement>[];

    if (data['awards'] != null && data['awards'] is List) {
      for (final award in data['awards'] as List) {
        if (award is Map) {
          achievementList.add(
            Achievement(
              title: award['title'] ?? award['name'] ?? '',
              description: award['description'] ?? '',
              date: _parseDate(award['date']),
            ),
          );
        } else if (award is String) {
          achievementList.add(Achievement(title: award, description: ''));
        }
      }
    }

    if (data['achievements'] != null && data['achievements'] is List) {
      for (final achievement in data['achievements'] as List) {
        if (achievement is Map) {
          achievementList.add(
            Achievement(
              title: achievement['title'] ?? achievement['name'] ?? '',
              description: achievement['description'] ?? '',
              date: _parseDate(achievement['date']),
            ),
          );
        } else if (achievement is String) {
          achievementList.add(Achievement(title: achievement, description: ''));
        }
      }
    }

    return achievementList;
  }

  List<Reference> _convertReferences(Map<String, dynamic> data) {
    final referenceList = <Reference>[];

    if (data['references'] != null && data['references'] is List) {
      for (final ref in data['references'] as List) {
        if (ref is Map) {
          referenceList.add(
            Reference(
              name: ref['name'] ?? '',
              title: ref['title'] ?? ref['position'] ?? '',
              company: ref['company'] ?? ref['organization'] ?? '',
              email: ref['email'] ?? '',
              phone: ref['phone'] ?? '',
            ),
          );
        }
      }
    }

    return referenceList;
  }

  List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    } else if (value is String) {
      return value
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}
