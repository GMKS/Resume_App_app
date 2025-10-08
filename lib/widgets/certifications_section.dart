import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class CertificationsSection extends StatefulWidget {
  final List<Certification> certifications;
  final Function(List<Certification>) onCertificationsChanged;

  const CertificationsSection({
    Key? key,
    required this.certifications,
    required this.onCertificationsChanged,
  }) : super(key: key);

  @override
  _CertificationsSectionState createState() => _CertificationsSectionState();
}

class _CertificationsSectionState extends State<CertificationsSection> {
  void _addCertification() {
    final newCertification = Certification(name: '', issuer: '');

    final updatedCertifications = List<Certification>.from(
      widget.certifications,
    )..add(newCertification);

    widget.onCertificationsChanged(updatedCertifications);
  }

  void _removeCertification(int index) {
    final updatedCertifications = List<Certification>.from(
      widget.certifications,
    )..removeAt(index);

    widget.onCertificationsChanged(updatedCertifications);
  }

  void _updateCertification(int index, Certification certification) {
    final updatedCertifications = List<Certification>.from(
      widget.certifications,
    );
    updatedCertifications[index] = certification;

    widget.onCertificationsChanged(updatedCertifications);
  }

  Future<DateTime?> _selectDate(
    BuildContext context,
    DateTime? initialDate,
  ) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        if (widget.certifications.isEmpty)
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
                  Icons.verified_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'No certifications added yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add your professional certifications and achievements',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ...widget.certifications.asMap().entries.map((entry) {
          final index = entry.key;
          final certification = entry.value;

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
                          certification.name.isEmpty
                              ? 'New Certification ${index + 1}'
                              : certification.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeCertification(index),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Certification Name
                  TextFormField(
                    initialValue: certification.name,
                    decoration: const InputDecoration(
                      labelText: 'Certification Name *',
                      hintText: 'e.g., AWS Certified Solutions Architect',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateCertification(
                        index,
                        certification.copyWith(name: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Issuing Organization
                  TextFormField(
                    initialValue: certification.issuer,
                    decoration: const InputDecoration(
                      labelText: 'Issuing Organization *',
                      hintText: 'e.g., Amazon Web Services',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateCertification(
                        index,
                        certification.copyWith(issuer: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await _selectDate(
                              context,
                              certification.issueDate,
                            );
                            if (date != null) {
                              _updateCertification(
                                index,
                                certification.copyWith(issueDate: date),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Issue Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              certification.issueDate != null
                                  ? '${certification.issueDate!.month}/${certification.issueDate!.year}'
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await _selectDate(
                              context,
                              certification.expiryDate,
                            );
                            if (date != null) {
                              _updateCertification(
                                index,
                                certification.copyWith(expiryDate: date),
                              );
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date (Optional)',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              certification.expiryDate != null
                                  ? '${certification.expiryDate!.month}/${certification.expiryDate!.year}'
                                  : 'No expiry / Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Credential ID
                  TextFormField(
                    initialValue: certification.credentialId,
                    decoration: const InputDecoration(
                      labelText: 'Credential ID (Optional)',
                      hintText: 'e.g., AWS-SAA-123456',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _updateCertification(
                        index,
                        certification.copyWith(credentialId: value),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Credential URL
                  TextFormField(
                    initialValue: certification.credentialUrl,
                    decoration: const InputDecoration(
                      labelText: 'Credential URL (Optional)',
                      hintText: 'https://credentials.provider.com/verify',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (value) {
                      _updateCertification(
                        index,
                        certification.copyWith(credentialUrl: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),

        const SizedBox(height: 16),

        // Add Certification Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addCertification,
            icon: const Icon(Icons.add),
            label: const Text('Add Certification'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.indigo,
              side: const BorderSide(color: Colors.indigo),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Popular Certifications Quick Add
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Popular Certifications',
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
                        'AWS Solutions Architect',
                        'Google Cloud Professional',
                        'Microsoft Azure Fundamentals',
                        'Certified Scrum Master',
                        'PMP',
                        'CISSP',
                        'CompTIA Security+',
                        'Salesforce Certified',
                      ].map((cert) {
                        final alreadyAdded = widget.certifications.any(
                          (c) => c.name.contains(cert),
                        );
                        return ActionChip(
                          label: Text(cert),
                          onPressed: alreadyAdded
                              ? null
                              : () {
                                  final newCertification = Certification(
                                    name: cert,
                                    issuer: _getIssuerForCert(cert),
                                    issueDate: DateTime.now(),
                                  );
                                  final updatedCertifications =
                                      List<Certification>.from(
                                        widget.certifications,
                                      )..add(newCertification);
                                  widget.onCertificationsChanged(
                                    updatedCertifications,
                                  );
                                },
                          backgroundColor: alreadyAdded
                              ? Colors.grey.shade200
                              : Colors.indigo.shade50,
                          labelStyle: TextStyle(
                            color: alreadyAdded
                                ? Colors.grey.shade500
                                : Colors.indigo,
                            fontSize: 12,
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

  String _getIssuerForCert(String cert) {
    switch (cert) {
      case 'AWS Solutions Architect':
        return 'Amazon Web Services';
      case 'Google Cloud Professional':
        return 'Google Cloud';
      case 'Microsoft Azure Fundamentals':
        return 'Microsoft';
      case 'Certified Scrum Master':
        return 'Scrum Alliance';
      case 'PMP':
        return 'Project Management Institute';
      case 'CISSP':
        return '(ISC)²';
      case 'CompTIA Security+':
        return 'CompTIA';
      case 'Salesforce Certified':
        return 'Salesforce';
      default:
        return '';
    }
  }
}
