class ResumeTemplate {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final bool isPremium;
  final String category; // 'minimal' or 'creative'

  const ResumeTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    this.isPremium = false,
    required this.category,
  });

  static List<ResumeTemplate> getMinimalTemplates() {
    return [
      const ResumeTemplate(
        id: 'minimal_1',
        name: 'Clean Minimal',
        description: 'A clean and simple design perfect for any profession',
        imagePath: 'assets/images/templates/Template_1.PNG',
        category: 'minimal',
      ),
      const ResumeTemplate(
        id: 'minimal_2',
        name: 'Modern Minimal',
        description: 'Modern layout with subtle styling',
        imagePath: 'assets/images/templates/Template_2.PNG',
        category: 'minimal',
      ),
      const ResumeTemplate(
        id: 'minimal_3',
        name: 'Professional Minimal',
        description: 'Professional appearance with minimal design',
        imagePath: 'assets/images/templates/Template_3.PNG',
        category: 'minimal',
      ),
      const ResumeTemplate(
        id: 'minimal_4',
        name: 'Elegant Minimal',
        description: 'Elegant and sophisticated minimal design',
        imagePath: 'assets/images/templates/Template_4.PNG',
        category: 'minimal',
      ),
      const ResumeTemplate(
        id: 'minimal_5',
        name: 'Corporate Minimal',
        description: 'Corporate-friendly minimal template',
        imagePath: 'assets/images/templates/Template_5.PNG',
        category: 'minimal',
      ),
    ];
  }

  static List<ResumeTemplate> getCreativeTemplates() {
    return [
      const ResumeTemplate(
        id: 'creative_1',
        name: 'Bold Creative',
        description: 'Eye-catching design for creative professionals',
        imagePath: 'assets/images/templates/Template_6.PNG',
        category: 'creative',
      ),
      const ResumeTemplate(
        id: 'creative_2',
        name: 'Artistic Creative',
        description: 'Artistic layout perfect for designers',
        imagePath: 'assets/images/templates/Template_7.PNG',
        category: 'creative',
      ),
      const ResumeTemplate(
        id: 'creative_3',
        name: 'Dynamic Creative',
        description: 'Dynamic design with creative elements',
        imagePath: 'assets/images/templates/Template_8.PNG',
        category: 'creative',
      ),
      const ResumeTemplate(
        id: 'creative_4',
        name: 'Innovative Creative',
        description: 'Innovative layout for forward-thinking professionals',
        imagePath: 'assets/images/templates/Template_10.PNG',
        category: 'creative',
      ),
      const ResumeTemplate(
        id: 'creative_5',
        name: 'Expressive Creative',
        description: 'Expressive design for creative storytelling',
        imagePath: 'assets/images/templates/Template_1.PNG',
        category: 'creative',
        isPremium: true,
      ),
    ];
  }

  static List<ResumeTemplate> getAllTemplates() {
    return [...getMinimalTemplates(), ...getCreativeTemplates()];
  }
}
