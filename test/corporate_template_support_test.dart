import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/features/preview/widgets/pdf_templates.dart';
import 'package:resume_builder/features/templates/corporate_template_support.dart';

void main() {
  test('factory returns the dedicated corporate pdf template', () {
    final template = PdfTemplateFactory.getTemplate('corporate_template');
    expect(template, isA<CorporateResumePdfTemplate>());
  });

  test('keeps github and website contact links in template order', () {
    final items = CorporateTemplateSupport.contactItems(
      PersonalInfo(
        email: 'seenai007@gmail.com',
        phone: '+91 9885623465',
        address: 'Hyderabad, India',
        linkedIn: 'https://linkedin.com/in/seenai/',
        github: 'https://github.com/gmk',
        website: 'https://www.seenaigmk.com/',
      ),
      compactLinks: true,
      includeAddress: true,
    );

    expect(
      items.map((item) => item.kind),
      equals([
        CorporateContactKind.email,
        CorporateContactKind.phone,
        CorporateContactKind.location,
        CorporateContactKind.linkedin,
        CorporateContactKind.github,
        CorporateContactKind.website,
      ]),
    );
    expect(
      items.map((item) => item.label),
      equals([
        'seenai007@gmail.com',
        '+91 9885623465',
        'Hyderabad, India',
        'linkedin.com/in/seenai',
        'github.com/gmk',
        'seenaigmk.com',
      ]),
    );
  });

  test('keeps project summaries, project links, and certification metadata', () {
    final projects = CorporateTemplateSupport.projectEntries(
      [
        Project(
          id: 'project-1',
          title: 'Finance Reporting Hub',
          description: 'Delivered dashboard rollout.\n'
              'Docs: https://docs.example.com/guide.\n'
              'Demo: https://example.com/reporting-hub',
          url: 'https://example.com/reporting-hub/',
        ),
      ],
      maxDetailLines: 4,
      compactLinks: true,
    );

    expect(projects, hasLength(1));
    expect(projects.single.detailLines, equals(['Delivered dashboard rollout.']));
    expect(
      projects.single.links,
      equals(['example.com/reporting-hub', 'docs.example.com/guide']),
    );

    final certifications = CorporateTemplateSupport.certificationEntries(
      [
        Certification(
          id: 'cert-1',
          name: 'AWS Certified Developer',
          issuer: 'Amazon',
          issueDate: DateTime(2024, 1, 1),
          expiryDate: DateTime(2027, 1, 1),
          credentialId: 'AWS-123456',
          credentialUrl: 'https://example.com/cert/aws-123456',
        ),
      ],
      compactLinks: true,
    );

    expect(certifications, hasLength(1));
    expect(certifications.single.name, 'AWS Certified Developer');
    final details = certifications.single.detailLines.join(' | ');
    expect(details, contains('Amazon'));
    expect(details, contains('Issued Jan 2024'));
    expect(details, contains('Expires Jan 2027'));
    expect(details, contains('Credential ID: AWS-123456'));
    expect(
      certifications.single.links,
      equals(['example.com/cert/aws-123456']),
    );
  });
}