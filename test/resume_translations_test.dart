import 'package:flutter_test/flutter_test.dart';

import 'package:resume_builder/core/utils/resume_translations.dart';

void main() {
  test('Spanish preview labels cover about and certification metadata', () {
    expect(ResumeTranslations.translate('ABOUT ME', 'Spanish'), 'SOBRE MI');
    expect(ResumeTranslations.translate('Issued', 'Spanish'), 'Emitido');
    expect(
      ResumeTranslations.translate('Credential ID', 'Spanish'),
      'ID de credencial',
    );
  });

  test('Spanish preview uses Spanish intl locale for dates', () {
    expect(ResumeTranslations.dateLocale('Spanish'), 'es');
    expect(ResumeTranslations.present('Spanish'), 'Actualidad');
  });
}