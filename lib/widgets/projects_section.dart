import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class ProjectsSection extends StatefulWidget {
  final List<Project> projects;
  final Function(List<Project>) onProjectsChanged;

  const ProjectsSection({
    Key? key,
    required this.projects,
    required this.onProjectsChanged,
  }) : super(key: key);

  @override
  _ProjectsSectionState createState() => _ProjectsSectionState();
}

class _ProjectsSectionState extends State<ProjectsSection> {
  void _addProject() {
    final newProject = Project(title: '');

    final updatedProjects = List<Project>.from(widget.projects)
      ..add(newProject);

    widget.onProjectsChanged(updatedProjects);
  }

  void _removeProject(int index) {
    final updatedProjects = List<Project>.from(widget.projects)
      ..removeAt(index);

    widget.onProjectsChanged(updatedProjects);
  }

  void _updateProject(int index, Project project) {
    final updatedProjects = List<Project>.from(widget.projects);
    updatedProjects[index] = project;

    widget.onProjectsChanged(updatedProjects);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        if (widget.projects.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No projects added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Showcase your projects and portfolio work',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ...widget.projects.asMap().entries.map((entry) {
          final index = entry.key;
          final project = entry.value;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with delete button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          project.title.isEmpty
                              ? 'New Project ${index + 1}'
                              : project.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeProject(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Project Title
                  TextFormField(
                    initialValue: project.title,
                    decoration: const InputDecoration(
                      labelText: 'Project Title *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateProject(index, project.copyWith(title: value));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    initialValue: project.description,
                    decoration: const InputDecoration(
                      labelText: 'Project Description',
                      hintText:
                          'Describe what the project does, your role, and key achievements...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    onChanged: (value) {
                      _updateProject(
                        index,
                        project.copyWith(description: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Technologies
                  _TechnologiesInput(
                    technologies: project.technologies,
                    onTechnologiesChanged: (technologies) {
                      _updateProject(
                        index,
                        project.copyWith(technologies: technologies),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // URLs Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: project.projectUrl,
                          decoration: const InputDecoration(
                            labelText: 'Project URL',
                            hintText: 'https://project-demo.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            _updateProject(
                              index,
                              project.copyWith(projectUrl: value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: project.githubUrl,
                          decoration: const InputDecoration(
                            labelText: 'GitHub URL',
                            hintText: 'https://github.com/user/repo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.code),
                          ),
                          keyboardType: TextInputType.url,
                          onChanged: (value) {
                            _updateProject(
                              index,
                              project.copyWith(githubUrl: value),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 16),

        // Add Project Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addProject,
            icon: const Icon(Icons.add),
            label: const Text('Add Project'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _TechnologiesInput extends StatefulWidget {
  final List<String> technologies;
  final Function(List<String>) onTechnologiesChanged;

  const _TechnologiesInput({
    required this.technologies,
    required this.onTechnologiesChanged,
  });

  @override
  _TechnologiesInputState createState() => _TechnologiesInputState();
}

class _TechnologiesInputState extends State<_TechnologiesInput> {
  final TextEditingController _techController = TextEditingController();

  void _addTechnology() {
    final tech = _techController.text.trim();
    if (tech.isNotEmpty && !widget.technologies.contains(tech)) {
      final updatedTechnologies = List<String>.from(widget.technologies)
        ..add(tech);
      widget.onTechnologiesChanged(updatedTechnologies);
      _techController.clear();
    }
  }

  void _removeTechnology(String tech) {
    final updatedTechnologies = List<String>.from(widget.technologies)
      ..remove(tech);
    widget.onTechnologiesChanged(updatedTechnologies);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _techController,
                decoration: const InputDecoration(
                  labelText: 'Technologies Used',
                  hintText: 'e.g., Flutter, React, Python',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addTechnology(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addTechnology,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.technologies.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.technologies.map((tech) {
              return Chip(
                label: Text(tech),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTechnology(tech),
                backgroundColor: Colors.indigo.shade50,
                labelStyle: TextStyle(color: Colors.indigo.shade700),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _techController.dispose();
    super.dispose();
  }
}
