import 'dart:convert';

/// Model for customizable resume design settings
class CustomizeSettings {
  // Design Settings
  final String templateStyle;
  final String layoutType;
  final String colorTheme;
  final String fontFamily;
  final double fontSize;
  final double lineSpacing;
  final double sectionSpacing;
  final String backgroundStyle;
  final String? profilePhotoPath;
  final String? customLogoPath;

  // Smart Features
  final bool aiSuggestions;
  final bool keywordOptimizer;
  final bool grammarCheck;
  final String? jobDescription;

  // Export & Sharing
  final String exportFormat;
  final String language;
  final bool shareLink;
  final bool qrCode;

  const CustomizeSettings({
    this.templateStyle = 'Modern',
    this.layoutType = 'Two Column',
    this.colorTheme = '#3F51B5', // Indigo
    this.fontFamily = 'Roboto',
    this.fontSize = 12.0,
    this.lineSpacing = 1.2,
    this.sectionSpacing = 16.0,
    this.backgroundStyle = 'Plain',
    this.profilePhotoPath,
    this.customLogoPath,
    this.aiSuggestions = true,
    this.keywordOptimizer = false,
    this.grammarCheck = true,
    this.jobDescription,
    this.exportFormat = 'PDF',
    this.language = 'English',
    this.shareLink = false,
    this.qrCode = false,
  });

  CustomizeSettings copyWith({
    String? templateStyle,
    String? layoutType,
    String? colorTheme,
    String? fontFamily,
    double? fontSize,
    double? lineSpacing,
    double? sectionSpacing,
    String? backgroundStyle,
    String? profilePhotoPath,
    String? customLogoPath,
    bool? aiSuggestions,
    bool? keywordOptimizer,
    bool? grammarCheck,
    String? jobDescription,
    String? exportFormat,
    String? language,
    bool? shareLink,
    bool? qrCode,
  }) {
    return CustomizeSettings(
      templateStyle: templateStyle ?? this.templateStyle,
      layoutType: layoutType ?? this.layoutType,
      colorTheme: colorTheme ?? this.colorTheme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      backgroundStyle: backgroundStyle ?? this.backgroundStyle,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      customLogoPath: customLogoPath ?? this.customLogoPath,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
      keywordOptimizer: keywordOptimizer ?? this.keywordOptimizer,
      grammarCheck: grammarCheck ?? this.grammarCheck,
      jobDescription: jobDescription ?? this.jobDescription,
      exportFormat: exportFormat ?? this.exportFormat,
      language: language ?? this.language,
      shareLink: shareLink ?? this.shareLink,
      qrCode: qrCode ?? this.qrCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templateStyle': templateStyle,
      'layoutType': layoutType,
      'colorTheme': colorTheme,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'lineSpacing': lineSpacing,
      'sectionSpacing': sectionSpacing,
      'backgroundStyle': backgroundStyle,
      'profilePhotoPath': profilePhotoPath,
      'customLogoPath': customLogoPath,
      'aiSuggestions': aiSuggestions,
      'keywordOptimizer': keywordOptimizer,
      'grammarCheck': grammarCheck,
      'jobDescription': jobDescription,
      'exportFormat': exportFormat,
      'language': language,
      'shareLink': shareLink,
      'qrCode': qrCode,
    };
  }

  factory CustomizeSettings.fromJson(Map<String, dynamic> json) {
    return CustomizeSettings(
      templateStyle: json['templateStyle'] ?? 'Modern',
      layoutType: json['layoutType'] ?? 'Two Column',
      colorTheme: json['colorTheme'] ?? '#3F51B5',
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: (json['fontSize'] ?? 12.0).toDouble(),
      lineSpacing: (json['lineSpacing'] ?? 1.2).toDouble(),
      sectionSpacing: (json['sectionSpacing'] ?? 16.0).toDouble(),
      backgroundStyle: json['backgroundStyle'] ?? 'Plain',
      profilePhotoPath: json['profilePhotoPath'],
      customLogoPath: json['customLogoPath'],
      aiSuggestions: json['aiSuggestions'] ?? true,
      keywordOptimizer: json['keywordOptimizer'] ?? false,
      grammarCheck: json['grammarCheck'] ?? true,
      jobDescription: json['jobDescription'],
      exportFormat: json['exportFormat'] ?? 'PDF',
      language: json['language'] ?? 'English',
      shareLink: json['shareLink'] ?? false,
      qrCode: json['qrCode'] ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory CustomizeSettings.fromJsonString(String jsonString) {
    return CustomizeSettings.fromJson(jsonDecode(jsonString));
  }
}

/// Available template styles
class TemplateStyles {
  static const List<String> values = [
    'Modern',
    'Minimalist',
    'Creative',
    'ATS-Friendly',
  ];
}

/// Available layout types
class LayoutTypes {
  static const List<String> values = ['Single Column', 'Two Column', 'Grid'];
}

/// Available background styles
class BackgroundStyles {
  static const List<String> values = ['Plain', 'Gradient', 'Image', 'Texture'];
}

/// Available font families
class FontFamilies {
  static const List<String> values = [
    'Roboto',
    'Lato',
    'Open Sans',
    'Montserrat',
    'Poppins',
    'Inter',
    'Source Sans Pro',
  ];
}

/// Available export formats
class ExportFormats {
  static const List<String> values = ['PDF', 'PNG', 'DOCX'];
}

/// Available languages
class Languages {
  static const List<String> values = [
    'English',
    'Hindi',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];
}

/// Predefined color themes
class ColorThemes {
  static const Map<String, String> themes = {
    'Indigo': '#3F51B5',
    'Blue': '#2196F3',
    'Teal': '#009688',
    'Green': '#4CAF50',
    'Orange': '#FF9800',
    'Red': '#F44336',
    'Purple': '#9C27B0',
    'Deep Orange': '#FF5722',
    'Brown': '#795548',
    'Blue Grey': '#607D8B',
  };
}
