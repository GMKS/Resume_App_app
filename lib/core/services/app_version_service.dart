import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
  });

  final String version;
  final String buildNumber;

  String get shortLabel => '$version (Build $buildNumber)';
  String get displayLabel => 'Version $shortLabel';
}

class AppVersionService {
  static const AppVersionInfo unavailable = AppVersionInfo(
    version: 'Unavailable',
    buildNumber: 'Unavailable',
  );

  static Future<AppVersionInfo> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final buildNumber = info.buildNumber.trim();

      if (version.isEmpty || buildNumber.isEmpty) {
        return unavailable;
      }

      return AppVersionInfo(
        version: version,
        buildNumber: buildNumber,
      );
    } catch (_) {
      return unavailable;
    }
  }
}
