import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataExportService {
  static Future<String> exportData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      data[key] = prefs.get(key);
    }
    final json = jsonEncode(data);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/resume_data_export.json');
    await file.writeAsString(json);
    return file.path;
  }
}
