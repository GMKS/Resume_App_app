class BrandingTheme {
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final String fontFamily;
  final double headerFontSize;
  final double bodyFontSize;
  final String? logoBase64;
  final bool showLogo;
  final String logoPosition; // 'top-left', 'top-right', 'center'

  const BrandingTheme({
    this.primaryColor = '#2196F3',
    this.secondaryColor = '#757575',
    this.accentColor = '#FF5722',
    this.fontFamily = 'Roboto',
    this.headerFontSize = 18.0,
    this.bodyFontSize = 14.0,
    this.logoBase64,
    this.showLogo = false,
    this.logoPosition = 'top-right',
  });

  Map<String, dynamic> toJson() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'headerFontSize': headerFontSize,
      'bodyFontSize': bodyFontSize,
      'logoBase64': logoBase64,
      'showLogo': showLogo,
      'logoPosition': logoPosition,
    };
  }

  factory BrandingTheme.fromJson(Map<String, dynamic> json) {
    return BrandingTheme(
      primaryColor: json['primaryColor'] ?? '#2196F3',
      secondaryColor: json['secondaryColor'] ?? '#757575',
      accentColor: json['accentColor'] ?? '#FF5722',
      fontFamily: json['fontFamily'] ?? 'Roboto',
      headerFontSize: (json['headerFontSize'] ?? 18.0).toDouble(),
      bodyFontSize: (json['bodyFontSize'] ?? 14.0).toDouble(),
      logoBase64: json['logoBase64'],
      showLogo: json['showLogo'] ?? false,
      logoPosition: json['logoPosition'] ?? 'top-right',
    );
  }

  BrandingTheme copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? fontFamily,
    double? headerFontSize,
    double? bodyFontSize,
    String? logoBase64,
    bool? showLogo,
    String? logoPosition,
  }) {
    return BrandingTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      fontFamily: fontFamily ?? this.fontFamily,
      headerFontSize: headerFontSize ?? this.headerFontSize,
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      logoBase64: logoBase64 ?? this.logoBase64,
      showLogo: showLogo ?? this.showLogo,
      logoPosition: logoPosition ?? this.logoPosition,
    );
  }

  // Predefined themes
  static const BrandingTheme professional = BrandingTheme(
    primaryColor: '#1A365D',
    secondaryColor: '#4A5568',
    accentColor: '#2B6CB0',
    fontFamily: 'Georgia',
    headerFontSize: 20.0,
    bodyFontSize: 14.0,
  );

  static const BrandingTheme creative = BrandingTheme(
    primaryColor: '#7C3AED',
    secondaryColor: '#A78BFA',
    accentColor: '#F59E0B',
    fontFamily: 'Montserrat',
    headerFontSize: 22.0,
    bodyFontSize: 15.0,
  );

  static const BrandingTheme modern = BrandingTheme(
    primaryColor: '#111827',
    secondaryColor: '#6B7280',
    accentColor: '#10B981',
    fontFamily: 'Inter',
    headerFontSize: 18.0,
    bodyFontSize: 14.0,
  );

  static const BrandingTheme minimalist = BrandingTheme(
    primaryColor: '#374151',
    secondaryColor: '#9CA3AF',
    accentColor: '#F97316',
    fontFamily: 'Inter',
    headerFontSize: 16.0,
    bodyFontSize: 13.0,
  );

  static const BrandingTheme classic = BrandingTheme(
    primaryColor: '#1F2937',
    secondaryColor: '#6B7280',
    accentColor: '#DC2626',
    fontFamily: 'Times New Roman',
    headerFontSize: 19.0,
    bodyFontSize: 14.0,
  );

  static const BrandingTheme tech = BrandingTheme(
    primaryColor: '#1E293B',
    secondaryColor: '#64748B',
    accentColor: '#0EA5E9',
    fontFamily: 'Roboto Mono',
    headerFontSize: 17.0,
    bodyFontSize: 13.0,
  );
}
