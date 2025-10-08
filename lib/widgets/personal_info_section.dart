import 'package:flutter/material.dart';
import '../models/custom_resume_data.dart';

class PersonalInfoSection extends StatelessWidget {
  final CustomResumeData resumeData;
  final Function(CustomResumeData) onResumeDataChanged;

  const PersonalInfoSection({
    Key? key,
    required this.resumeData,
    required this.onResumeDataChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Full Name
        TextFormField(
          initialValue: resumeData.fullName,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          onChanged: (value) {
            onResumeDataChanged(resumeData.copyWith(fullName: value));
          },
        ),
        const SizedBox(height: 16),

        // Job Title
        TextFormField(
          initialValue: resumeData.jobTitle,
          decoration: const InputDecoration(
            labelText: 'Job Title / Professional Title *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.work),
          ),
          onChanged: (value) {
            onResumeDataChanged(resumeData.copyWith(jobTitle: value));
          },
        ),
        const SizedBox(height: 16),

        // Professional Summary
        TextFormField(
          initialValue: resumeData.summary,
          decoration: const InputDecoration(
            labelText: 'Professional Summary',
            hintText:
                'Write a brief summary of your professional background and key strengths...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 4,
          onChanged: (value) {
            onResumeDataChanged(resumeData.copyWith(summary: value));
          },
        ),
        const SizedBox(height: 24),

        // Contact Information Header
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 16),

        // Email
        TextFormField(
          initialValue: resumeData.contactInfo.email,
          decoration: const InputDecoration(
            labelText: 'Email Address *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) {
            onResumeDataChanged(
              resumeData.copyWith(
                contactInfo: resumeData.contactInfo.copyWith(email: value),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Phone
        TextFormField(
          initialValue: resumeData.contactInfo.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) {
            onResumeDataChanged(
              resumeData.copyWith(
                contactInfo: resumeData.contactInfo.copyWith(phone: value),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Location
        TextFormField(
          initialValue: resumeData.contactInfo.location,
          decoration: const InputDecoration(
            labelText: 'Location (City, Country)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          onChanged: (value) {
            onResumeDataChanged(
              resumeData.copyWith(
                contactInfo: resumeData.contactInfo.copyWith(location: value),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // LinkedIn
        TextFormField(
          initialValue: resumeData.contactInfo.linkedin,
          decoration: const InputDecoration(
            labelText: 'LinkedIn Profile',
            hintText: 'https://linkedin.com/in/yourprofile',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) {
            onResumeDataChanged(
              resumeData.copyWith(
                contactInfo: resumeData.contactInfo.copyWith(linkedin: value),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Website/Portfolio
        TextFormField(
          initialValue: resumeData.contactInfo.website,
          decoration: const InputDecoration(
            labelText: 'Website / Portfolio',
            hintText: 'https://yourwebsite.com',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.language),
          ),
          keyboardType: TextInputType.url,
          onChanged: (value) {
            onResumeDataChanged(
              resumeData.copyWith(
                contactInfo: resumeData.contactInfo.copyWith(website: value),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Required fields note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fields marked with * are required for all resume templates.',
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
