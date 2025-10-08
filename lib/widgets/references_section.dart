import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class ReferencesSection extends StatefulWidget {
  final List<Reference> references;
  final bool showReferences;
  final Function(List<Reference>) onReferencesChanged;
  final Function(bool) onShowReferencesChanged;

  const ReferencesSection({
    Key? key,
    required this.references,
    required this.showReferences,
    required this.onReferencesChanged,
    required this.onShowReferencesChanged,
  }) : super(key: key);

  @override
  _ReferencesSectionState createState() => _ReferencesSectionState();
}

class _ReferencesSectionState extends State<ReferencesSection> {
  void _addReference() {
    final newReference = Reference(name: '');

    final updatedReferences = List<Reference>.from(widget.references)
      ..add(newReference);

    widget.onReferencesChanged(updatedReferences);
  }

  void _removeReference(int index) {
    final updatedReferences = List<Reference>.from(widget.references)
      ..removeAt(index);

    widget.onReferencesChanged(updatedReferences);
  }

  void _updateReference(int index, Reference reference) {
    final updatedReferences = List<Reference>.from(widget.references);
    updatedReferences[index] = reference;

    widget.onReferencesChanged(updatedReferences);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Show References Toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text(
                    'Include References in Resume',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Toggle whether to show references in your exported resume',
                  ),
                  value: widget.showReferences,
                  onChanged: widget.onShowReferencesChanged,
                  activeColor: Colors.indigo,
                  contentPadding: EdgeInsets.zero,
                ),
                if (!widget.showReferences)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.amber.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'References will be saved but not included in exported resumes. You can provide them separately when requested.',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        if (widget.references.isEmpty)
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
                  Icons.contacts_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No references added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add professional references who can vouch for your work and character',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ...widget.references.asMap().entries.map((entry) {
          final index = entry.key;
          final reference = entry.value;

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
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.indigo,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reference.name.isEmpty
                              ? 'New Reference ${index + 1}'
                              : reference.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeReference(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name
                  TextFormField(
                    initialValue: reference.name,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateReference(index, reference.copyWith(name: value));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Job Title
                  TextFormField(
                    initialValue: reference.title,
                    decoration: const InputDecoration(
                      labelText: 'Job Title',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateReference(index, reference.copyWith(title: value));
                    },
                  ),
                  const SizedBox(height: 12),

                  // Company
                  TextFormField(
                    initialValue: reference.company,
                    decoration: const InputDecoration(
                      labelText: 'Company/Organization',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateReference(
                        index,
                        reference.copyWith(company: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Relationship
                  TextFormField(
                    initialValue: reference.relationship,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'e.g., Former Manager, Colleague, Client',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateReference(
                        index,
                        reference.copyWith(relationship: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Contact Information Row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: reference.email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            _updateReference(
                              index,
                              reference.copyWith(email: value),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: reference.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            _updateReference(
                              index,
                              reference.copyWith(phone: value),
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

        // Add Reference Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addReference,
            icon: const Icon(Icons.add),
            label: const Text('Add Reference'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Reference Guidelines
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Reference Guidelines',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...const [
                      '• Always ask permission before listing someone as a reference',
                      '• Provide your references with your current resume and job description',
                      '• Choose references who can speak to different aspects of your work',
                      '• Include a mix of supervisors, colleagues, and clients if possible',
                      '• Keep your references updated on your job search progress',
                      '• Consider 3-5 references as the optimal number',
                    ]
                    .map(
                      (guideline) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          guideline,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
