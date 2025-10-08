import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class LanguagesSection extends StatefulWidget {
  final List<Language> languages;
  final Function(List<Language>) onLanguagesChanged;

  const LanguagesSection({
    Key? key,
    required this.languages,
    required this.onLanguagesChanged,
  }) : super(key: key);

  @override
  _LanguagesSectionState createState() => _LanguagesSectionState();
}

class _LanguagesSectionState extends State<LanguagesSection> {
  final TextEditingController _languageController = TextEditingController();
  String _selectedProficiency = 'Intermediate';

  void _addLanguage() {
    if (_languageController.text.trim().isEmpty) return;

    final newLanguage = Language(
      name: _languageController.text.trim(),
      proficiency: _selectedProficiency,
    );

    final updatedLanguages = List<Language>.from(widget.languages)
      ..add(newLanguage);
    widget.onLanguagesChanged(updatedLanguages);

    _languageController.clear();
  }

  void _removeLanguage(int index) {
    final updatedLanguages = List<Language>.from(widget.languages)
      ..removeAt(index);
    widget.onLanguagesChanged(updatedLanguages);
  }

  void _updateLanguage(int index, Language language) {
    final updatedLanguages = List<Language>.from(widget.languages);
    updatedLanguages[index] = language;
    widget.onLanguagesChanged(updatedLanguages);
  }

  Color _getProficiencyColor(String proficiency) {
    switch (proficiency) {
      case 'Beginner':
        return Colors.red;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.blue;
      case 'Native':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getProficiencyIcon(String proficiency) {
    switch (proficiency) {
      case 'Beginner':
        return Icons.star_border;
      case 'Intermediate':
        return Icons.star_half;
      case 'Advanced':
        return Icons.star;
      case 'Native':
        return Icons.stars;
      default:
        return Icons.star_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Add Language Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Language',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _languageController,
                        decoration: const InputDecoration(
                          labelText: 'Language',
                          hintText: 'e.g., English, Spanish, French',
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addLanguage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedProficiency,
                          isExpanded: true,
                          underline: Container(),
                          hint: const Text('Proficiency'),
                          items: LanguageProficiency.levels.map((proficiency) {
                            return DropdownMenuItem(
                              value: proficiency,
                              child: Row(
                                children: [
                                  Icon(
                                    _getProficiencyIcon(proficiency),
                                    color: _getProficiencyColor(proficiency),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(proficiency),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedProficiency = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addLanguage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Languages List
        if (widget.languages.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.language_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No languages added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add languages you speak to showcase your communication skills',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...widget.languages.asMap().entries.map((entry) {
            final index = entry.key;
            final language = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Language Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.language,
                        color: Colors.indigo,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Language Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _getProficiencyIcon(language.proficiency),
                                color: _getProficiencyColor(
                                  language.proficiency,
                                ),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                language.proficiency,
                                style: TextStyle(
                                  color: _getProficiencyColor(
                                    language.proficiency,
                                  ),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Proficiency Dropdown
                    DropdownButton<String>(
                      value: language.proficiency,
                      underline: Container(),
                      items: LanguageProficiency.levels.map((proficiency) {
                        return DropdownMenuItem(
                          value: proficiency,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getProficiencyIcon(proficiency),
                                color: _getProficiencyColor(proficiency),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                proficiency,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _updateLanguage(
                            index,
                            language.copyWith(proficiency: value),
                          );
                        }
                      },
                    ),

                    // Delete Button
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => _removeLanguage(index),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

        const SizedBox(height: 16),

        // Quick Add Popular Languages
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Add Popular Languages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      [
                        'English',
                        'Spanish',
                        'French',
                        'German',
                        'Chinese',
                        'Japanese',
                        'Arabic',
                        'Portuguese',
                        'Russian',
                        'Italian',
                      ].map((language) {
                        final alreadyAdded = widget.languages.any(
                          (l) => l.name == language,
                        );
                        return ActionChip(
                          label: Text(language),
                          onPressed: alreadyAdded
                              ? null
                              : () {
                                  final newLanguage = Language(
                                    name: language,
                                    proficiency: 'Intermediate',
                                  );
                                  final updatedLanguages = List<Language>.from(
                                    widget.languages,
                                  )..add(newLanguage);
                                  widget.onLanguagesChanged(updatedLanguages);
                                },
                          backgroundColor: alreadyAdded
                              ? Colors.grey.shade200
                              : Colors.indigo.shade50,
                          labelStyle: TextStyle(
                            color: alreadyAdded
                                ? Colors.grey.shade500
                                : Colors.indigo,
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _languageController.dispose();
    super.dispose();
  }
}
