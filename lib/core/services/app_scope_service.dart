import 'package:flutter/foundation.dart';

import 'app_config_service.dart';

class AppScopeService {
  AppScopeService._();

  static bool _initialized = false;
  static late String _scopeId;
  static late String _namespace;
  static late String _prefPrefix;

  static void initialize() {
    if (_initialized) {
      return;
    }

    final configuredNamespace = _normalizeNamespace(
      AppConfigService.read('APP_DATA_NAMESPACE'),
    );
    final signingHash = _normalizeSigningHash(
      AppConfigService.read('PACKAGE_SHA256'),
    );

    _namespace = configuredNamespace.isNotEmpty
        ? configuredNamespace
        : (kReleaseMode ? 'production' : 'debug');

    final signerSuffix = signingHash.isNotEmpty
        ? signingHash.substring(0, signingHash.length >= 12 ? 12 : signingHash.length)
        : 'unsigned';

    _scopeId = '$_namespace-$signerSuffix';
    _prefPrefix = 'scope.$_scopeId.';
    _initialized = true;
  }

  static String get namespace {
    initialize();
    return _namespace;
  }

  static String get scopeId {
    initialize();
    return _scopeId;
  }

  static String get prefPrefix {
    initialize();
    return _prefPrefix;
  }

  static String boxName(String baseName) {
    initialize();
    return '${_normalizeKey(baseName)}_$scopeId';
  }

  static String prefKey(String key) {
    initialize();
    return '$_prefPrefix${_normalizeKey(key)}';
  }

  static String cloudNamespaceKey(String key) {
    initialize();
    return '${_normalizeKey(scopeId)}:${_normalizeKey(key)}';
  }

  static String _normalizeNamespace(String value) {
    return _normalizeKey(value);
  }

  static String _normalizeSigningHash(String value) {
    return value.replaceAll(RegExp(r'[^A-Fa-f0-9]'), '').toLowerCase();
  }

  static String _normalizeKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}