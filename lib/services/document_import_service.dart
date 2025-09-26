import 'dart:io';
import '../services/premium_service.dart';

/// Document import and AI processing service
/// Optimized for minimal dependencies and APK size
class DocumentImportService {
  static final DocumentImportService _instance =
      DocumentImportService._internal();
  factory DocumentImportService() => _instance;
  DocumentImportService._internal();

  /// Extract text content from various document formats
  static Future<String> extractTextFromDocument(File file) async {
    if (!PremiumService.hasDocumentImport) {
      throw Exception('Document import is a premium feature');
    }

    String extension = file.path.split('.').last.toLowerCase();

    switch (extension) {
      case 'txt':
        return await _extractFromText(file);
      case 'pdf':
        return await _extractFromPDF(file);
      case 'docx':
      case 'doc':
        return await _extractFromWord(file);
      default:
        throw Exception('Unsupported file format: $extension');
    }
  }

  /// Process document with AI to extract resume sections
  static Future<Map<String, dynamic>> processWithAI(String text) async {
    if (!PremiumService.hasAIFeatures) {
      throw Exception('AI processing is a premium feature');
    }

    try {
      // Mock AI processing - replace with actual AI service
      return await _mockAIProcessing(text);

      /* Uncomment when integrating with real AI service
      final response = await http.post(
        Uri.parse(_aiProcessingEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('AI processing failed: ${response.statusCode}');
      }
      */
    } catch (e) {
      throw Exception('Failed to process document: $e');
    }
  }

  /// Extract text from plain text file
  static Future<String> _extractFromText(File file) async {
    return await file.readAsString();
  }

  /// Extract text from PDF (simplified implementation)
  static Future<String> _extractFromPDF(File file) async {
    // For production, integrate with a PDF parsing library
    // For now, return placeholder to reduce APK size
    return "PDF content extraction requires additional integration";
  }

  /// Extract text from Word document (simplified implementation)
  static Future<String> _extractFromWord(File file) async {
    // For production, integrate with a Word document parser
    // For now, return placeholder to reduce APK size
    return "Word document extraction requires additional integration";
  }

  /// Mock AI processing for development/testing
  static Future<Map<String, dynamic>> _mockAIProcessing(String text) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock structured resume data extraction
    List<String> lines = text.split('\n');
    Map<String, dynamic> extractedData = {
      'personalInfo': {
        'name': _extractName(lines),
        'email': _extractEmail(text),
        'phone': _extractPhone(text),
        'address': _extractAddress(lines),
      },
      'summary': _extractSummary(lines),
      'experience': _extractExperience(lines),
      'education': _extractEducation(lines),
      'skills': _extractSkills(lines),
      'sections': _identifyCustomSections(lines),
    };

    return extractedData;
  }

  static String _extractName(List<String> lines) {
    // Simple name extraction logic
    for (String line in lines.take(5)) {
      line = line.trim();
      if (line.isNotEmpty &&
          !line.contains('@') &&
          !line.contains('http') &&
          line.split(' ').length >= 2 &&
          line.split(' ').length <= 4) {
        return line;
      }
    }
    return 'John Doe';
  }

  static String _extractEmail(String text) {
    RegExp emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
    );
    Match? match = emailRegex.firstMatch(text);
    return match?.group(0) ?? 'email@example.com';
  }

  static String _extractPhone(String text) {
    RegExp phoneRegex = RegExp(r'[\+]?[1-9]?[\d\s\-\(\)]{10,}');
    Match? match = phoneRegex.firstMatch(text);
    return match?.group(0)?.replaceAll(RegExp(r'[^\d\+]'), '') ?? '';
  }

  static String _extractAddress(List<String> lines) {
    // Simple address extraction
    for (String line in lines.take(10)) {
      if (line.contains(',') && line.length > 10) {
        return line.trim();
      }
    }
    return '';
  }

  static String _extractSummary(List<String> lines) {
    List<String> summaryKeywords = ['summary', 'objective', 'profile', 'about'];

    for (int i = 0; i < lines.length - 1; i++) {
      String line = lines[i].toLowerCase();
      if (summaryKeywords.any((keyword) => line.contains(keyword))) {
        // Return next few lines as summary
        List<String> summaryLines = [];
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          if (lines[j].trim().isNotEmpty && !_isHeaderLine(lines[j])) {
            summaryLines.add(lines[j].trim());
          } else if (summaryLines.isNotEmpty) {
            break;
          }
        }
        return summaryLines.join(' ');
      }
    }
    return 'Professional with extensive experience and skills.';
  }

  static List<Map<String, dynamic>> _extractExperience(List<String> lines) {
    List<Map<String, dynamic>> experiences = [];
    List<String> experienceKeywords = [
      'experience',
      'employment',
      'work history',
      'career',
    ];

    int startIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase();
      if (experienceKeywords.any((keyword) => line.contains(keyword))) {
        startIndex = i + 1;
        break;
      }
    }

    if (startIndex > 0) {
      // Mock experience extraction
      experiences.add({
        'title': 'Software Developer',
        'company': 'Tech Company',
        'duration': '2020 - Present',
        'description': 'Developed and maintained software applications.',
      });
    }

    return experiences;
  }

  static List<Map<String, dynamic>> _extractEducation(List<String> lines) {
    List<Map<String, dynamic>> education = [];
    List<String> educationKeywords = [
      'education',
      'academic',
      'qualification',
      'degree',
    ];

    for (String line in lines) {
      if (educationKeywords.any(
        (keyword) => line.toLowerCase().contains(keyword),
      )) {
        education.add({
          'degree': 'Bachelor of Science',
          'institution': 'University Name',
          'year': '2020',
        });
        break;
      }
    }

    return education;
  }

  static List<String> _extractSkills(List<String> lines) {
    List<String> skillKeywords = ['skills', 'technologies', 'competencies'];

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].toLowerCase();
      if (skillKeywords.any((keyword) => line.contains(keyword))) {
        // Extract skills from following lines
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          String skillLine = lines[j].trim();
          if (skillLine.isNotEmpty && !_isHeaderLine(skillLine)) {
            return skillLine.split(',').map((s) => s.trim()).toList();
          }
        }
      }
    }

    return ['Communication', 'Leadership', 'Problem Solving'];
  }

  static List<Map<String, String>> _identifyCustomSections(List<String> lines) {
    List<Map<String, String>> sections = [];

    // Identify potential section headers
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (_isHeaderLine(line) && line.length > 3) {
        String content = '';
        for (int j = i + 1; j < lines.length && j < i + 5; j++) {
          if (!_isHeaderLine(lines[j]) && lines[j].trim().isNotEmpty) {
            content += '${lines[j].trim()} ';
          } else if (content.isNotEmpty) {
            break;
          }
        }

        if (content.isNotEmpty) {
          sections.add({'title': line, 'content': content.trim()});
        }
      }
    }

    return sections;
  }

  static bool _isHeaderLine(String line) {
    // Simple heuristic for header detection
    return line.trim().toUpperCase() == line.trim() ||
        line.trim().endsWith(':') ||
        (line.trim().length < 30 && !line.contains(' ') == false);
  }

  /// Main import method that combines text extraction and AI processing
  Future<DocumentImportResult> importDocument(dynamic file) async {
    try {
      // Extract text from document
      final extractedText = await extractTextFromDocument(file);

      // Process with AI to structure the data
      final processedData = await processWithAI(extractedText);

      return DocumentImportResult(
        extractedText: extractedText,
        structuredData: processedData,
        success: true,
      );
    } catch (e) {
      return DocumentImportResult(
        extractedText: '',
        structuredData: {},
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Result class for document import operations
class DocumentImportResult {
  final String extractedText;
  final Map<String, dynamic> structuredData;
  final bool success;
  final String? error;

  DocumentImportResult({
    required this.extractedText,
    required this.structuredData,
    required this.success,
    this.error,
  });
}
