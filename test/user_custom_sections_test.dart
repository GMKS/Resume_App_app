import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/models/resume_model.dart';
import 'package:resume_builder/core/utils/user_custom_sections.dart';

void main() {
  group('orderedUserCustomSectionsFromList', () {
    test('returns only user custom sections in normalized order', () {
      final sections = orderedUserCustomSectionsFromList([
        CustomSection(id: 'startup_tools', title: 'Tools'),
        CustomSection(id: 'user_custom_b', title: 'Publications', order: 3),
        CustomSection(id: 'user_custom_a', title: 'Awards', order: 1),
        CustomSection(id: 'user_custom_c', title: 'Leadership', order: 1),
      ]);

      expect(sections.map((section) => section.id).toList(), [
        'user_custom_a',
        'user_custom_c',
        'user_custom_b',
      ]);
    });

    test('keeps legacy custom sections without the user prefix', () {
      final sections = orderedUserCustomSectionsFromList([
        CustomSection(id: 'startup_tools', title: 'Tools'),
        CustomSection(
            id: 'leadership_highlights',
            title: 'Leadership Highlights',
            order: 2),
        CustomSection(id: 'awards', title: 'Awards', order: 1),
      ]);

      expect(sections.map((section) => section.id).toList(), [
        'awards',
        'leadership_highlights',
      ]);
    });

    test('does not classify standard resume keys as user custom sections', () {
      expect(isUserCustomSectionId('personal'), isFalse);
      expect(isUserCustomSectionId('summary'), isFalse);
      expect(isUserCustomSectionId('experience'), isFalse);
    });
  });

  group('displayUserCustomSectionTitle', () {
    test('prefers configured titles for known optional sections', () {
      final section = CustomSection(id: 'startup_achievements');

      expect(
        displayUserCustomSectionTitle(section, templateId: 'startup'),
        'Achievements',
      );
    });

    test('humanizes legacy ids when the stored title is missing', () {
      final section = CustomSection(id: 'leadership_experience');

      expect(displayUserCustomSectionTitle(section), 'Leadership Experience');
    });

    test('avoids surfacing generated ids as section titles', () {
      final section = CustomSection(
        id: 'user_custom_123e4567-e89b-12d3-a456-426614174000',
      );

      expect(displayUserCustomSectionTitle(section), 'Section');
    });
  });

  group('mergeUserCustomSections', () {
    test('preserves non-user sections and rewrites user order indexes', () {
      final merged = mergeUserCustomSections(
        existingSections: [
          CustomSection(id: 'startup_tools', title: 'Tools'),
          CustomSection(id: 'user_custom_old', title: 'Old', order: 9),
        ],
        orderedUserSections: [
          CustomSection(id: 'user_custom_b', title: 'Awards', order: 9),
          CustomSection(id: 'user_custom_a', title: 'Publications', order: 4),
        ],
      );

      expect(merged.map((section) => section.id).toList(), [
        'startup_tools',
        'user_custom_b',
        'user_custom_a',
      ]);
      expect(merged[1].order, 0);
      expect(merged[2].order, 1);
    });
  });

  group('buildUserCustomSectionItem', () {
    test('promotes the first content line into the item title', () {
      final item = buildUserCustomSectionItem(
        id: 'item-1',
        content: 'Led QA guild\nBuilt release dashboards\nMentored analysts',
      );

      expect(item.id, 'item-1');
      expect(item.title, 'Led QA guild');
      expect(item.description, 'Built release dashboards\nMentored analysts');
    });
  });

  group('buildUserCustomSectionDisplayItem', () {
    test('moves the first description line into the heading only once', () {
      final item = CustomSectionItem(
        id: 'item-1',
        title: '',
        subtitle: 'Open Source',
        description:
            'Resume Builder\nImplemented template preview parity\nFixed custom section rendering',
      );

      final displayItem = buildUserCustomSectionDisplayItem(item);

      expect(displayItem.heading, 'Resume Builder');
      expect(displayItem.subtitle, 'Open Source');
      expect(displayItem.detailLines, [
        'Implemented template preview parity',
        'Fixed custom section rendering',
      ]);
    });

    test('preserves explicit titles and empty description safely', () {
      final item = CustomSectionItem(
        id: 'item-2',
        title: 'Awards',
        subtitle: 'Regional',
      );

      final displayItem = buildUserCustomSectionDisplayItem(item);

      expect(displayItem.heading, 'Awards');
      expect(displayItem.subtitle, 'Regional');
      expect(displayItem.detailLines, isEmpty);
      expect(displayItem.hasContent, isTrue);
    });
  });
}
