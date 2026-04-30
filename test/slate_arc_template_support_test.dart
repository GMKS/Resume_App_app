import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/slate_arc_template_support.dart';

void main() {
  test('factory returns the dedicated slate arc pdf template', () {
    final template = PdfTemplateFactory.getTemplate('slate_arc');
    expect(template, isA<SlateArcResumePdfTemplate>());
  });

  test('slate arc contact items keep address plus compact social links', () {
    final items = SlateArcTemplateSupport.contactItems(
      PersonalInfo(
        address: 'San Francisco, CA',
        phone: '(555) 123-4567',
        email: 'john.smith@email.com',
        linkedIn: 'https://linkedin.com/in/johnsmith/',
        github: 'https://github.com/johnsmith',
        website: 'https://johnsmith.dev/',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      items.map((item) => item.kind),
      equals([
        SlateArcContactKind.address,
        SlateArcContactKind.phone,
        SlateArcContactKind.email,
        SlateArcContactKind.linkedin,
        SlateArcContactKind.github,
        SlateArcContactKind.website,
      ]),
    );
    expect(
      items.map((item) => item.label),
      equals([
        'San Francisco, CA',
        '(555) 123-4567',
        'john.smith@email.com',
        'linkedin.com/in/johnsmith',
        'github.com/johnsmith',
        'johnsmith.dev',
      ]),
    );
  });

  test('slate arc project entries keep the title, summary text, and links', () {
    final entries = SlateArcTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Portfolio Website',
          description:
              'Built a portfolio with case studies. https://example.com/portfolio',
          url: 'https://example.com/portfolio',
          technologies: const ['Flutter', 'Firebase'],
        ),
      ],
      maxDetailLines: 1,
      compactLinks: true,
    );

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Portfolio Website');
    expect(
      entries.single.detailLines,
      equals(['Built a portfolio with case studies.']),
    );
    expect(entries.single.links, equals(['example.com/portfolio']));
  });

  test('slate arc experience entries can include all summary lines', () {
    final entries = SlateArcTemplateSupport.experienceEntries(
      [
        Experience(
          id: 'experience-1',
          position: 'Senior Developer',
          company: 'TechCorp',
          startDate: DateTime(2021, 1, 1),
          endDate: DateTime(2024, 1, 1),
          description: 'Built release automation.\nImproved test coverage.',
          achievements: const ['Reduced incident volume by 40%.'],
        ),
      ],
      maxDetailLines: null,
    );

    expect(entries, hasLength(1));
    expect(
      entries.single.detailLines,
      equals([
        'Built release automation.',
        'Improved test coverage.',
        'Reduced incident volume by 40%.',
      ]),
    );
  });

  test('slate arc summary lines keep every normalized profile point', () {
    final lines = SlateArcTemplateSupport.summaryLines(
      'Delivered cloud migrations. Improved release quality. Partnered with stakeholders.',
      maxItems: null,
    );

    expect(
      lines,
      equals([
        'Delivered cloud migrations.',
        'Improved release quality.',
        'Partnered with stakeholders.',
      ]),
    );
  });

  test('slate arc summary lines split newline and sentence-delimited points', () {
    final lines = SlateArcTemplateSupport.summaryLines(
      'Built cloud releases.\nImproved observability. Partnered with product stakeholders.',
      maxItems: null,
    );

    expect(
      lines,
      equals([
        'Built cloud releases.',
        'Improved observability.',
        'Partnered with product stakeholders.',
      ]),
    );
  });
}