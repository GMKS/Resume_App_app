import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/saved_resume.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

bool isPremiumUser = false; // Or import from your subscription service

void exportResume(
  BuildContext context,
  SavedResume resume, {
  bool asWord = false,
}) {
  if (asWord && !isPremiumUser) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upgrade to premium for Word export!')),
    );
    return;
  }

  if (asWord) {
    // TODO: Generate Word document
  } else {
    // TODO: Generate PDF document
  }
}

void shareResume(SavedResume resume) {
  final filePath = generateResumeFile(resume); // Generate PDF or Word file
  Share.shareXFiles([XFile(filePath)], text: 'Check out my resume!');
}

Future<String> getResumeTips(String resumeContent) async {
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/completions'),
    headers: {'Authorization': 'Bearer YOUR_API_KEY'},
    body: jsonEncode({
      'model': 'text-davinci-003',
      'prompt': 'Provide tips for improving this resume: $resumeContent',
      'max_tokens': 100,
    }),
  );
  return jsonDecode(response.body)['choices'][0]['text'];
}

String generateResumeFile(SavedResume resume) {
  // Logic to generate a file path for the resume
  return '/path/to/generated/file.pdf';
}
