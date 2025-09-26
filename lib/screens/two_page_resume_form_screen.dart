import 'package:flutter/material.dart';
import '../widgets/base_resume_form.dart';
import '../services/document_import_service.dart';
import '../services/premium_service.dart';
import '../services/drag_drop_service.dart';

class TwoPageResumeFormScreen extends StatefulWidget {
  const TwoPageResumeFormScreen({super.key});

  @override
  State<TwoPageResumeFormScreen> createState() =>
      _TwoPageResumeFormScreenState();
}

class _TwoPageResumeFormScreenState extends State<TwoPageResumeFormScreen> {
  final _documentImportService = DocumentImportService();

  bool _isImporting = false;
  String? _importedContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Two Page Resume'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (PremiumService.hasDocumentImport)
            IconButton(
              icon: const Icon(Icons.attach_file),
              tooltip: 'Import Document',
              onPressed: _showImportDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Document Import Section
          if (PremiumService.hasDocumentImport) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy, color: Colors.deepPurple),
                      SizedBox(width: 8),
                      Text(
                        'AI Document Import',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Import your existing resume (Word/PDF) and let AI convert it to our Two Page format',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  if (_isImporting)
                    const CircularProgressIndicator()
                  else
                    DragDropZone(
                      onFileDropped: _handleDocumentImport,
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.deepPurple.shade300,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                color: Colors.deepPurple,
                              ),
                              Text(
                                'Drag & Drop or Click to Upload',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          // Resume Form
          Expanded(
            child: BaseResumeForm(
              template: 'TwoPage',
              templateType: 'TwoPage',
              initialData: _importedContent != null
                  ? _parseImportedContent(_importedContent!)
                  : null,
              customSections: _buildTwoPageSections(),
              onDataChanged: (data) {
                // Handle data changes
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Two Page Resume Form',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Use the builder method to create form fields
                    Builder(
                      builder: (context) {
                        final formState = BaseResumeForm.of(context);
                        return Column(
                          children: [
                            formState?.buildTextField(
                                  'name',
                                  'Full Name',
                                  required: true,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            formState?.buildTextField(
                                  'email',
                                  'Email Address',
                                  required: true,
                                  keyboard: TextInputType.emailAddress,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            formState?.buildTextField(
                                  'phone',
                                  'Phone Number',
                                  keyboard: TextInputType.phone,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            formState?.buildTextField(
                                  'summary',
                                  'Professional Summary',
                                  maxLines: 4,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            formState?.buildTextField(
                                  'experience',
                                  'Work Experience',
                                  maxLines: 6,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            formState?.buildTextField(
                                  'education',
                                  'Education',
                                  maxLines: 3,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            formState?.buildTextField(
                                  'skills',
                                  'Skills',
                                  maxLines: 3,
                                  enableDragDrop: true,
                                ) ??
                                const SizedBox(),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => formState?.saveResume(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                              child: const Text('Save Two Page Resume'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Document'),
        content: const Text(
          'Select a Word (.docx) or PDF (.pdf) document to import. '
          'Our AI will analyze the content and convert it to the Two Page format.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleFilePickerImport();
            },
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFilePickerImport() async {
    try {
      final file = await DragDropService.pickFile(
        allowedExtensions: ['pdf', 'docx', 'doc'],
      );

      if (file != null) {
        await _handleDocumentImport(file);
      }
    } catch (e) {
      _showErrorMessage('Failed to select file: $e');
    }
  }

  Future<void> _handleDocumentImport(dynamic file) async {
    if (!PremiumService.hasDocumentImport) {
      PremiumService.showUpgradeDialog(context, 'Document Import Feature');
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await _documentImportService.importDocument(file);

      setState(() {
        _importedContent = result.extractedText;
        _isImporting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document imported successfully! AI processing complete.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      _showErrorMessage('Import failed: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Map<String, dynamic>? _parseImportedContent(String content) {
    // Parse the imported content and return structured data
    // This would typically use the DocumentImportService parsing
    return {
      'personalInfo': {
        'name': 'Imported Resume',
        'email': 'extracted@email.com',
        'phone': 'Extracted Phone',
      },
      'summary': content.length > 500
          ? '${content.substring(0, 500)}...'
          : content,
      'experience': [],
      'education': [],
      'skills': [],
    };
  }

  List<Widget> _buildTwoPageSections() {
    return [
      // Page 1 Indicator
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.article, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text(
              'Page 1: Core Information',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),

      // Page 1 Break Indicator
      const Divider(height: 32, thickness: 2, indent: 16, endIndent: 16),

      // Page 2 Indicator
      Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.article_outlined, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Page 2: Additional Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
