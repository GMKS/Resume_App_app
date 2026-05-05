import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';

import '../constants/app_info.dart';
import '../models/resume_model.dart';

class ResumeExportFile {
  final Uint8List bytes;
  final String filename;
  final String mimeType;

  const ResumeExportFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

class ResumeExportService {
  static ResumeExportFile buildTxtExport(ResumeModel resume) {
    final content = _buildPlainText(resume);
    return ResumeExportFile(
      bytes: Uint8List.fromList(utf8.encode(content)),
      filename: '${_fileStem(resume)}_Resume.txt',
      mimeType: 'text/plain',
    );
  }

  static ResumeExportFile buildDocxExport(ResumeModel resume) {
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          '[Content_Types].xml',
          _contentTypes.length,
          utf8.encode(_contentTypes),
        ),
      )
      ..addFile(
        ArchiveFile('_rels/.rels', _rootRels.length, utf8.encode(_rootRels)),
      )
      ..addFile(
        ArchiveFile(
          'docProps/core.xml',
          _coreProps(resume).length,
          utf8.encode(_coreProps(resume)),
        ),
      )
      ..addFile(
        ArchiveFile(
          'docProps/app.xml',
          _appProps.length,
          utf8.encode(_appProps),
        ),
      )
      ..addFile(
        ArchiveFile(
          'word/document.xml',
          _documentXml(resume).length,
          utf8.encode(_documentXml(resume)),
        ),
      )
      ..addFile(
        ArchiveFile(
          'word/_rels/document.xml.rels',
          _documentRels.length,
          utf8.encode(_documentRels),
        ),
      );

    final bytes = ZipEncoder().encode(archive) ?? <int>[];
    return ResumeExportFile(
      bytes: Uint8List.fromList(bytes),
      filename: '${_fileStem(resume)}_Resume.docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
  }

  static String _buildPlainText(ResumeModel resume) {
    final lines = <String>[];
    final personal = resume.personalInfo;

    void addSection(String title, List<String> values) {
      final filtered = values
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      if (filtered.isEmpty) return;
      if (lines.isNotEmpty) lines.add('');
      lines.add(title.toUpperCase());
      lines.addAll(filtered);
    }

    lines.add(personal.fullName.trim());
    if ((personal.jobTitle ?? '').trim().isNotEmpty) {
      lines.add((personal.jobTitle ?? '').trim());
    }

    addSection('Contact', [
      if (personal.email.trim().isNotEmpty) 'Email: ${personal.email.trim()}',
      if (personal.phone.trim().isNotEmpty) 'Phone: ${personal.phone.trim()}',
      if (personal.address.trim().isNotEmpty)
        'Address: ${personal.address.trim()}',
      if ((personal.linkedIn ?? '').trim().isNotEmpty)
        'LinkedIn: ${(personal.linkedIn ?? '').trim()}',
      if ((personal.github ?? '').trim().isNotEmpty)
        'GitHub: ${(personal.github ?? '').trim()}',
      if ((personal.website ?? '').trim().isNotEmpty)
        'Website: ${(personal.website ?? '').trim()}',
    ]);

    addSection('Professional Summary', [resume.objective ?? '']);

    addSection(
      'Experience',
      resume.experience.expand((experience) {
        final items = <String>[];
        items.add(
          '${experience.position.trim()} | ${experience.company.trim()}'.trim(),
        );
        final meta = [
          if ((experience.location ?? '').trim().isNotEmpty)
            (experience.location ?? '').trim(),
          _formatDateRange(
            experience.startDate,
            experience.endDate,
            isCurrent: experience.isCurrentlyWorking,
          ),
        ].where((value) => value.trim().isNotEmpty).join(' | ');
        if (meta.isNotEmpty) items.add(meta);
        if (experience.description.trim().isNotEmpty) {
          items.add(experience.description.trim());
        }
        for (final achievement in experience.achievements) {
          if (achievement.trim().isNotEmpty) {
            items.add('• ${achievement.trim()}');
          }
        }
        items.add('');
        return items;
      }).toList(),
    );

    addSection(
      'Education',
      resume.education.expand((education) {
        final items = <String>[];
        final titleParts = [
          education.degree.trim(),
          education.fieldOfStudy.trim(),
        ].where((value) => value.isNotEmpty).join(', ');
        if (titleParts.isNotEmpty) items.add(titleParts);
        if (education.institution.trim().isNotEmpty) {
          items.add(education.institution.trim());
        }
        final meta = [
          if ((education.location ?? '').trim().isNotEmpty)
            (education.location ?? '').trim(),
          _formatDateRange(
            education.startDate,
            education.endDate,
            isCurrent: education.isCurrentlyStudying,
          ),
        ].where((value) => value.trim().isNotEmpty).join(' | ');
        if (meta.isNotEmpty) items.add(meta);
        if ((education.grade ?? '').trim().isNotEmpty) {
          items.add('Grade: ${(education.grade ?? '').trim()}');
        }
        if ((education.description ?? '').trim().isNotEmpty) {
          items.add((education.description ?? '').trim());
        }
        items.add('');
        return items;
      }).toList(),
    );

    addSection(
      'Skills',
      resume.skills.map((skill) {
        final category = (skill.category ?? '').trim();
        final suffix = category.isEmpty ? '' : ' [$category]';
        return '• ${skill.name.trim()}$suffix';
      }).toList(),
    );

    addSection(
      'Projects',
      resume.projects.expand((project) {
        final items = <String>[];
        if (project.title.trim().isNotEmpty) items.add(project.title.trim());
        final meta = [
          if ((project.url ?? '').trim().isNotEmpty) (project.url ?? '').trim(),
          _formatOptionalDateRange(project.startDate, project.endDate),
        ].where((value) => value.trim().isNotEmpty).join(' | ');
        if (meta.isNotEmpty) items.add(meta);
        if (project.description.trim().isNotEmpty) {
          items.add(project.description.trim());
        }
        if (project.technologies.isNotEmpty) {
          items.add('Tech: ${project.technologies.join(', ')}');
        }
        items.add('');
        return items;
      }).toList(),
    );

    addSection(
      'Certifications',
      resume.certifications.expand((certification) {
        final items = <String>[];
        if (certification.name.trim().isNotEmpty) {
          items.add(certification.name.trim());
        }
        final meta = [
          if (certification.issuer.trim().isNotEmpty) certification.issuer.trim(),
          _formatOptionalDateRange(
            certification.issueDate,
            certification.expiryDate,
          ),
        ].where((value) => value.trim().isNotEmpty).join(' | ');
        if (meta.isNotEmpty) items.add(meta);
        if ((certification.credentialId ?? '').trim().isNotEmpty) {
          items.add('Credential ID: ${(certification.credentialId ?? '').trim()}');
        }
        if ((certification.credentialUrl ?? '').trim().isNotEmpty) {
          items.add('Credential URL: ${(certification.credentialUrl ?? '').trim()}');
        }
        items.add('');
        return items;
      }).toList(),
    );

    addSection(
      'Languages',
      resume.languages
          .map((language) => '• ${language.name.trim()} - ${language.proficiency.trim()}')
          .toList(),
    );

    addSection('Hobbies', resume.hobbies.map((hobby) => '• ${hobby.trim()}').toList());

    addSection(
      'References',
      resume.references.expand((reference) {
        final items = <String>[];
        if (reference.name.trim().isNotEmpty) items.add(reference.name.trim());
        final meta = [
          reference.position.trim(),
          reference.company.trim(),
        ].where((value) => value.isNotEmpty).join(' | ');
        if (meta.isNotEmpty) items.add(meta);
        final contact = [
          if (reference.email.trim().isNotEmpty) reference.email.trim(),
          if (reference.phone.trim().isNotEmpty) reference.phone.trim(),
        ].join(' | ');
        if (contact.isNotEmpty) items.add(contact);
        if ((reference.relationship ?? '').trim().isNotEmpty) {
          items.add('Relationship: ${(reference.relationship ?? '').trim()}');
        }
        items.add('');
        return items;
      }).toList(),
    );

    for (final customSection in resume.customSections) {
      addSection(
        customSection.title.trim().isEmpty
            ? 'Additional Information'
            : customSection.title.trim(),
        customSection.items.expand((item) {
          final values = <String>[];
          if (item.title.trim().isNotEmpty) values.add(item.title.trim());
          if ((item.subtitle ?? '').trim().isNotEmpty) {
            values.add((item.subtitle ?? '').trim());
          }
          if ((item.description ?? '').trim().isNotEmpty) {
            values.add((item.description ?? '').trim());
          }
          if (item.date != null) {
            values.add(DateFormat('MMM yyyy').format(item.date!));
          }
          values.add('');
          return values;
        }).toList(),
      );
    }

    return lines.join('\n').trim();
  }

  static String _documentXml(ResumeModel resume) {
    final lines = _buildPlainText(resume).split('\n');
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write(
        '<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" '
        'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
        'xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" '
        'xmlns:v="urn:schemas-microsoft-com:vml" '
        'xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
        'xmlns:w10="urn:schemas-microsoft-com:office:word" '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" '
        'xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" '
        'xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" '
        'xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" '
        'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" '
        'mc:Ignorable="w14 wp14">',
      )
      ..write('<w:body>');

    for (final line in lines) {
      final escaped = _escapeXml(line);
      final isHeading = line.isNotEmpty &&
          line == line.toUpperCase() &&
          !line.contains('@') &&
          !line.startsWith('• ');
      if (line.trim().isEmpty) {
        buffer.write('<w:p/>');
        continue;
      }
      if (isHeading) {
        buffer.write(
          '<w:p><w:r><w:rPr><w:b/><w:sz w:val="24"/></w:rPr><w:t>$escaped</w:t></w:r></w:p>',
        );
      } else {
        buffer.write(
          '<w:p><w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>',
        );
      }
    }

    buffer.write(
      '<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/></w:sectPr>',
    );
    buffer.write('</w:body></w:document>');
    return buffer.toString();
  }

  static String _coreProps(ResumeModel resume) {
    final now = DateTime.now().toUtc().toIso8601String();
    final title = _escapeXml('${resume.personalInfo.fullName} Resume');
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" '
        'xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:dcmitype="http://purl.org/dc/dcmitype/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        '<dc:title>$title</dc:title>'
        '<dc:creator>${AppInfo.appName}</dc:creator>'
        '<cp:lastModifiedBy>${AppInfo.appName}</cp:lastModifiedBy>'
        '<dcterms:created xsi:type="dcterms:W3CDTF">$now</dcterms:created>'
        '<dcterms:modified xsi:type="dcterms:W3CDTF">$now</dcterms:modified>'
        '</cp:coreProperties>';
  }

  static String _fileStem(ResumeModel resume) {
    final raw = resume.personalInfo.fullName.trim().isEmpty
        ? resume.title.trim()
        : resume.personalInfo.fullName.trim();
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');
  }

  static String _formatDateRange(DateTime start, DateTime? end, {required bool isCurrent}) {
    final formatter = DateFormat('MMM yyyy');
    final endLabel = isCurrent ? 'Present' : (end != null ? formatter.format(end) : '');
    if (endLabel.isEmpty) return formatter.format(start);
    return '${formatter.format(start)} - $endLabel';
  }

  static String _formatOptionalDateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return '';
    final formatter = DateFormat('MMM yyyy');
    final startLabel = start != null ? formatter.format(start) : '';
    final endLabel = end != null ? formatter.format(end) : 'Present';
    if (startLabel.isEmpty) return endLabel;
    return '$startLabel - $endLabel';
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static const String _contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
      '<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
      '</Types>';

  static const String _rootRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
      '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
      '</Relationships>';

  static const String _documentRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>';

  static const String _appProps =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
      'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
      '<Application>${AppInfo.appName}</Application>'
      '</Properties>';
}