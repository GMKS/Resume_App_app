import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/resume_model.dart';
import '../../../core/services/free_plan_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/startup_profile_sections.dart';
import '../../../core/utils/professional_role_sections.dart';
import '../../../core/utils/user_custom_sections.dart';
import '../widgets/academic_resume_template_preview.dart';
import '../widgets/ats_friendly_modern_resume_template_preview.dart';
import '../widgets/ats_optimized_clean_resume_template_preview.dart';
import '../widgets/ats_standard_format_resume_template_preview.dart';
import '../widgets/balanced_two_column_layout_template_preview.dart';
import '../widgets/bluewave_tech_resume_template_preview.dart';
import '../widgets/business_management_resume_template_preview.dart';
import '../widgets/classic_ats_resume_template_preview.dart';
import '../widgets/classic_resume_template_preview.dart';
import '../widgets/classic_temp_resume_template_preview.dart';
import '../widgets/corporate_resume_template_preview.dart';
import '../widgets/corporate_navy_template_preview.dart';
import '../widgets/vertical_timeline_template_preview.dart';
import '../widgets/creative_professional_resume_template_preview.dart';
import '../widgets/creative_resume_template_preview.dart';
import '../widgets/developer_resume_template_preview.dart';
import '../widgets/designer_profile_resume_template_preview.dart';
import '../widgets/education_resume_template_preview.dart';
import '../widgets/elegant_gold_layout_template_preview.dart';
import '../widgets/elegant_design_resume_template_preview.dart';
import '../widgets/emerald_executive_resume_template_preview.dart';
import '../widgets/entry_level_resume_template_preview.dart';
import '../widgets/elite_resume_template_preview.dart';
import '../widgets/executive_classic_resume_template_preview.dart';
import '../widgets/forest_edge_classic_resume_template_preview.dart';
import '../widgets/flexcolor_sidebar_template_preview.dart';
import '../widgets/forest_edge_resume_template_preview.dart';
import '../widgets/graphite_column_resume_template_preview.dart';
import '../widgets/healthcare_resume_template_preview.dart';
import '../widgets/infographic_resume_template_preview.dart';
import '../widgets/minimal_resume_template_preview.dart';
import '../widgets/minimal_clean_resume_template_preview.dart';
import '../widgets/minimal_clean_ats_resume_template_preview.dart';
import '../widgets/mono_nova_template_preview.dart';
import '../widgets/modern_edge_resume_template_preview.dart';
import '../widgets/modern_nova_template_preview.dart';
import '../widgets/multicolor_resume_template_preview.dart';
import '../widgets/one_page_resume_template_preview.dart';
import '../widgets/pink_rose_modern_template_preview.dart';
import '../widgets/professional_accountant_resume_template_preview.dart';
import '../widgets/professional_resume_template_preview.dart';
import '../widgets/rosewood_panel_resume_template_preview.dart';
import '../widgets/editorial_frame_resume_template_preview.dart';
import '../widgets/sales_and_marketing_resume_template_preview.dart';
import '../widgets/slate_arc_resume_template_preview.dart';
import '../widgets/two_column_resume_template_preview.dart';
import '../widgets/vividpro_resume_template_preview.dart';

enum _TemplateFilter { all, withoutPhoto, withPhoto }

class TemplateSelectionScreen extends ConsumerStatefulWidget {
  final String resumeId;
  final bool isNewResume;

  const TemplateSelectionScreen({
    super.key,
    required this.resumeId,
    this.isNewResume = false,
  });

  @override
  ConsumerState<TemplateSelectionScreen> createState() =>
      _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState
    extends ConsumerState<TemplateSelectionScreen> {
  String? _selectedTemplate;
  int _selectedColor = 0;
  _TemplateFilter _templateFilter = _TemplateFilter.all;
  final ScrollController _templateScrollController =
      ScrollController(keepScrollOffset: false);
  final ScrollController _templateGridScrollController = ScrollController();

  ResumeModel _previewResumeForTemplate(String templateId) {
    final previewResume = _templatePreviewSampleResume.copyWith(
      templateId: templateId,
    );
    final storedResume = StorageService.getResume(widget.resumeId);
    if (storedResume == null) {
      return previewResume;
    }

    if (templateId == 'modern_edge' || templateId == 'modern_aesthetic') {
      return previewResume.copyWith(
        customSections: storedResume.customSections,
      );
    }

    return previewResume;
  }

  final List<TemplateInfo> _templates = [
    TemplateInfo(
      id: 'modern',
      name: 'Modern Nova',
      description:
          'Clean modern resume with bold header and balanced single-column hierarchy',
      icon: Iconsax.flash,
      primaryColor: AppColors.primary,
      features: ['Modern header', 'Clean hierarchy', 'Versatile'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'classic',
      name: 'Classic',
      description:
          'Traditional professional resume with straightforward structure and timeless styling',
      icon: Iconsax.document,
      primaryColor: AppColors.secondary,
      features: ['Traditional', 'Professional', 'Timeless'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'creative',
      name: 'Creative',
      description:
          'Bold creative variation for visually expressive resumes with modern energy',
      icon: Iconsax.magic_star,
      primaryColor: const Color(0xFFF59E0B),
      features: ['Creative style', 'Bold accent', 'Modern energy'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'minimal',
      name: 'Minimal',
      description:
          'Minimalist resume focused on simplicity, whitespace, and readability',
      icon: Iconsax.minus_cirlce,
      primaryColor: const Color(0xFF64748B),
      features: ['Minimalist', 'Whitespace', 'Readable'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'developer',
      name: 'Developer',
      description:
          'Developer-focused resume layout for technical profiles and project-heavy content',
      icon: Iconsax.code_1,
      primaryColor: const Color(0xFF8B5CF6),
      features: ['Technical profile', 'Project-ready', 'Developer focus'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'two_column',
      name: 'Two Column',
      description: 'Sidebar layout for maximum content density',
      icon: Iconsax.grid_1,
      primaryColor: const Color(0xFF14B8A6),
      features: ['Space-efficient', 'Dual sections', 'Organized layout'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'elegant_pink',
      name: 'Pink Ros├⌐ Modern',
      description:
          'Quiet-luxury ros├⌐ resume with restrained spacing and ATS-friendly structure',
      icon: Iconsax.heart,
      primaryColor: const Color(0xFFD87093),
      features: [
        'Quiet luxury',
        'ATS-friendly hierarchy',
        'Minimal ros├⌐ accent'
      ],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'blue_gray',
      name: 'FlexColor Sidebar',
      description:
          'Accent-rail resume with floating masthead, modular info cards, and a flexible sidebar system',
      icon: Iconsax.layer,
      primaryColor: const Color(0xFF343D4D),
      features: ['Accent rail', 'Modular cards', 'Floating masthead'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'professional',
      name: 'Professional',
      description:
          'Metropolitan resume with centered header, accent top bar, square bullets, and dashed separators',
      icon: Iconsax.briefcase,
      primaryColor: const Color(0xFF5A607D),
      features: ['Centered header', 'Square bullets', 'Dashed separators'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'executive',
      name: 'Business Management Resume',
      description:
          'Refined resume for management and business leadership roles with strong hierarchical organization',
      icon: Iconsax.crown,
      primaryColor: const Color(0xFF1E293B),
      features: ['Leadership focus', 'Strategic layout', 'Management-ready'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'startup',
      name: 'Startup',
      description:
          'Fast-paced modern style for startup, product, and growth-oriented profiles',
      icon: Iconsax.flash_1,
      primaryColor: const Color(0xFFEF4444),
      features: ['Startup feel', 'Energetic', 'Modern'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'academic',
      name: 'Academic',
      description:
          'Clean scholarly layout ideal for freshers, graduates, and early-career professionals',
      icon: Iconsax.teacher,
      primaryColor: const Color(0xFF3730A3),
      features: ['Fresher-friendly', 'Education-first', 'Clean layout'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'sales',
      name: 'Sales & Marketing',
      description:
          'High-impact resume variant for sales, business development, and marketing roles',
      icon: Iconsax.chart_success,
      primaryColor: const Color(0xFFD946EF),
      features: ['High-impact', 'Business facing', 'Results oriented'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'modern_aesthetic',
      name: 'SharpLine Resume',
      description:
          'White and gold aesthetic with centered header and elegant dividers',
      icon: Iconsax.star,
      primaryColor: const Color(0xFFC3A97E),
      features: ['Gold accents', 'Centered header', 'Three-col skills'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'classic2',
      name: 'Classic Plus',
      description:
          'Black and white minimalist with bold uppercase name and pill skills',
      icon: Iconsax.edit_2,
      primaryColor: const Color(0xFF272727),
      features: ['Minimalist B&W', 'Uppercase name', 'Pill skills'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'education_resume',
      name: 'Education Resume',
      description:
          'Dark navy header with warm cream accents, ideal for academic profiles',
      icon: Iconsax.book_1,
      primaryColor: const Color(0xFF333C4D),
      features: ['Navy header', 'Cream accents', 'Education-first'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'modern_resume',
      name: 'Elite Resume',
      description:
          'Dark slate header with clean single-column layout and pill skills',
      icon: Iconsax.element_4,
      primaryColor: const Color(0xFF35354A),
      features: ['Slate header', 'Pill skills', 'Clean layout'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'professional_accountant',
      name: 'Prof. Accountant',
      description:
          'Near-black header, white body, two-column skills grid for finance roles',
      icon: Iconsax.chart_square,
      primaryColor: const Color(0xFF242527),
      features: ['Near-black header', 'Two-col grid', 'Finance-ready'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'one_page_resume',
      name: 'One Page Resume',
      description:
          'Blue-gray header, single-column white body with pill skills',
      icon: Iconsax.document_1,
      primaryColor: const Color(0xFF94A5CB),
      features: ['Blue header', 'Clean body', 'Pill skills'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'classic_temp',
      name: 'Classic Temp',
      description:
          'Minimalist white design, centered name, blue section headers',
      icon: Iconsax.note_text,
      primaryColor: const Color(0xFF6189BF),
      features: ['Minimalist', 'Blue accents', 'Centered header'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'emerald_executive',
      name: 'Emerald Executive',
      description: 'Professional emerald green design with executive styling',
      icon: Iconsax.briefcase,
      primaryColor: const Color(0xFF10B981),
      features: ['Emerald accent', 'Executive style', 'Professional layout'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'cool_blue',
      name: 'VividPro',
      description:
          'Clean and modern design with vivid accents and full detail sections',
      icon: Iconsax.layer,
      primaryColor: const Color(0xFF0EA5E9),
      features: ['Vivid accents', 'Modern design', 'Full detail layout'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'multicolor',
      name: 'MultiColor',
      description:
          'Vibrant multi-color design for creative and dynamic profiles',
      icon: Iconsax.color_swatch,
      primaryColor: const Color(0xFFEC4899),
      features: ['Colorful accents', 'Dynamic design', 'Creative style'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'entry_level',
      name: 'Entry Level',
      description:
          'Centered name, colored band sections, two-column skills for early-career professionals',
      icon: Iconsax.user_octagon,
      primaryColor: const Color(0xFF2E7D6B),
      features: ['Teal accents', 'Pill skills', 'Left accent bars'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'ats_optimized_clean',
      name: 'ATS Optimized Clean',
      description:
          'Minimalist ATS-friendly design with plain formatting and no scanner-confusing graphics',
      icon: Iconsax.tick_square,
      primaryColor: const Color(0xFF1F2937),
      features: ['ATS-optimized', 'Plain text friendly', 'Scanner-safe'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'ats_standard_format',
      name: 'ATS Standard Format',
      description:
          'Traditional ATS-compatible layout with clear sections, standard fonts, and proper spacing',
      icon: Iconsax.document_copy,
      primaryColor: const Color(0xFF374151),
      features: ['ATS-compatible', 'Standard format', 'Easy parsing'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'ats_friendly_modern',
      name: 'ATS Friendly Modern',
      description:
          'Modern yet ATS-friendly design with clean typography and structured hierarchy',
      icon: Iconsax.document_normal,
      primaryColor: const Color(0xFF2D3748),
      features: ['ATS-friendly', 'Scannable layout', 'Modern look'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'executive_classic',
      name: 'Executive Classic',
      description:
          'Authoritative two-tone header with bold left-bar section dividers for senior professionals',
      icon: Iconsax.briefcase,
      primaryColor: const Color(0xFF1B3A5C),
      features: ['Bold header', 'Left-bar sections', 'Executive style'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'classic_ats',
      name: 'Classic ATS Optimized',
      description:
          'Bold header band with accent contact bar, left-border sections, and clean ATS-optimized layout',
      icon: Iconsax.clipboard_text,
      primaryColor: const Color(0xFF1A1A2E),
      features: ['ATS-safe', 'Header band', 'Left-border sections'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'infographic',
      name: 'Infographic',
      description:
          'Light signal-map resume with pastel panels, journey cards, and infographic-style highlights',
      icon: Iconsax.chart_21,
      primaryColor: const Color(0xFF7DAFC0),
      features: ['Pastel panels', 'Journey map', 'Signal board'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'vertical_timeline',
      name: 'Vertical Timeline',
      description:
          'Photo card header with left sidebar timeline dots and a modern two-column layout',
      icon: Iconsax.clock,
      primaryColor: const Color(0xFF2A6B7C),
      features: ['Sidebar layout', 'Timeline dots', 'Photo header'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'corporate_template',
      name: 'Corporate Template',
      description:
          'Bold name block with diagonal accent strip, left skills panel and structured body',
      icon: Iconsax.buildings_2,
      primaryColor: const Color(0xFF334155),
      features: ['Diagonal accent', 'Left panel', 'Corporate style'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'mono_nova',
      name: 'Black and White',
      description:
          'Editorial monochrome layout with strong contrast and a refined modern tone',
      icon: Iconsax.colorfilter,
      primaryColor: const Color(0xFF57534E),
      features: ['Monochrome', 'Editorial', 'High contrast'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'slate_arc',
      name: 'Slate Arc',
      description:
          'Slate-toned photo template with curved detailing and structured content bands',
      icon: Iconsax.path_square,
      primaryColor: const Color(0xFF7A818C),
      features: ['Photo layout', 'Slate tones', 'Curved accents'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'editorial_frame',
      name: 'Editorial Frame',
      description:
          'Warm framed photo resume with magazine-inspired spacing and hierarchy',
      icon: Iconsax.picture_frame,
      primaryColor: const Color(0xFFB08863),
      features: ['Photo layout', 'Editorial frame', 'Warm neutral'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'graphite_column',
      name: 'Graphite Column',
      description:
          'Dark graphite column layout with sharp professional contrast and photo support',
      icon: Iconsax.sidebar_right,
      primaryColor: const Color(0xFF55565A),
      features: ['Photo layout', 'Dark column', 'Sharp contrast'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'rosewood_panel',
      name: 'Rosewood Panel',
      description:
          'Soft rosewood photo template with a warm side panel and elegant balance',
      icon: Iconsax.reserve,
      primaryColor: const Color(0xFFC7A09B),
      features: ['Photo layout', 'Warm panel', 'Soft premium feel'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'designer_profile',
      name: 'Design/Creative Resume',
      description:
          'Portfolio-style resume with photo-forward presentation ideal for creative and design professionals',
      icon: Iconsax.profile_2user,
      primaryColor: const Color(0xFF35569C),
      features: ['Portfolio feel', 'Creative showcase', 'Visual-first'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'modern_edge',
      name: 'Persona Pro CV',
      description:
          'Green-accented modern profile with bold side panel and clean hierarchy',
      icon: Iconsax.flash_1,
      primaryColor: const Color(0xFF6CB38E),
      features: ['Photo layout', 'Green accent', 'Modern panel'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'minimal_clean',
      name: 'Minimal Clean',
      description:
          'Soft blue photo resume with light structure and minimal presentation',
      icon: Iconsax.document_text,
      primaryColor: const Color(0xFF8FB0D6),
      features: ['Photo layout', 'Minimal style', 'Soft blue'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'minimal_clean_ats',
      name: 'Minimal Clean ATS',
      description:
          'Clean photo template tuned for straightforward ATS-friendly export',
      icon: Iconsax.shield_tick,
      primaryColor: const Color(0xFF7D2E2C),
      features: ['Photo layout', 'ATS-friendly', 'Minimal structure'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'professional_tone',
      name: 'HealthCare Resume',
      description:
          'Balanced blue-gray template with polished corporate feel, ideal for healthcare and medical professionals',
      icon: Iconsax.personalcard,
      primaryColor: const Color(0xFF516785),
      features: ['Professional polish', 'Medical-ready', 'Trusted design'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'elegant_design',
      name: 'Elegant design',
      description: 'Warm refined photo layout with soft premium detailing',
      icon: Iconsax.crown_1,
      primaryColor: const Color(0xFFC9935B),
      features: ['Photo layout', 'Elegant detailing', 'Premium feel'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'creative_professional',
      name: 'Creative professional',
      description:
          'Teal and cream photo resume with a polished creative studio feel',
      icon: Iconsax.brush_2,
      primaryColor: const Color(0xFF2D8C87),
      features: ['Photo layout', 'Creative polish', 'Teal and cream'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'bluewave_tech',
      name: 'Bluewave Tech',
      description:
          'Bold blue photo layout with a modern tech-forward information hierarchy',
      icon: Iconsax.monitor_mobbile,
      primaryColor: const Color(0xFF2F66B0),
      features: ['Photo layout', 'Tech-forward', 'Bold blue'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'balanced_two_column_layout',
      name: 'Balanced two-column layout',
      description:
          'Warm balanced two-column photo resume with soft gold editorial accents',
      icon: Iconsax.sidebar_left,
      primaryColor: const Color(0xFFB28B5C),
      features: ['Photo layout', 'Balanced columns', 'Warm editorial'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'elegant_gold_layout',
      name: 'Human Resources Resume',
      description:
          'Navy and gold photo design combining professionalism with human-centered elegance for HR roles',
      icon: Iconsax.medal_star,
      primaryColor: const Color(0xFFC29A55),
      features: ['HR-focused', 'Navy and gold', 'Professional elegance'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'corporate_navy',
      name: 'Corporate Navy',
      description:
          'Structured navy photo resume with a polished corporate hierarchy and clean section cards',
      icon: Iconsax.building_4,
      primaryColor: const Color(0xFF2F4F75),
      features: ['Photo layout', 'Corporate navy', 'Structured hierarchy'],
      hasPhoto: true,
    ),
    TemplateInfo(
      id: 'forest_edge',
      name: 'Forest Edge',
      description:
          'Rounded soft-gray editorial resume with stacked cards and a polished without-photo layout',
      icon: Iconsax.sidebar_left,
      primaryColor: const Color(0xFF9AA7B4),
      features: ['Without photo', 'Rounded cards', 'Editorial header'],
      hasPhoto: false,
    ),
    TemplateInfo(
      id: 'forest_edge_classic',
      name: 'Forest Edge Classic',
      description:
          'Original soft-gray without-photo layout with rounded cards and a lighter classic editorial header',
      icon: Iconsax.sidebar_right,
      primaryColor: const Color(0xFFAEB8C2),
      features: ['Without photo', 'Classic card style', 'Soft editorial'],
      hasPhoto: false,
    ),
  ];

  final List<Color> _colorOptions = [
    AppColors.primary,
    const Color(0xFF10B981),
    const Color(0xFF0EA5E9),
    const Color(0xFF8B5CF6),
    const Color(0xFFF59E0B),
    const Color(0xFFEC4899),
    const Color(0xFFEF4444),
    const Color(0xFF64748B),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentTemplate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_templateScrollController.hasClients) {
        _templateScrollController.jumpTo(0);
      }
      if (_templateGridScrollController.hasClients) {
        _templateGridScrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _templateScrollController.dispose();
    _templateGridScrollController.dispose();
    super.dispose();
  }

  void _setTemplateFilter(_TemplateFilter filter) {
    if (_templateFilter == filter) return;
    setState(() => _templateFilter = filter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_templateScrollController.hasClients) {
        _templateScrollController.jumpTo(0);
      }
      if (_templateGridScrollController.hasClients) {
        _templateGridScrollController.jumpTo(0);
      }
    });
  }

  void _scrollTemplateCarouselBy(double delta) {
    if (!_templateScrollController.hasClients) return;
    final position = _templateScrollController.position;
    final targetOffset = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((targetOffset - position.pixels).abs() < 0.1) return;
    _templateScrollController.jumpTo(targetOffset);
  }

  void _handleTemplateCarouselPointerSignal(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent) return;
    final delta = signal.scrollDelta.dx.abs() > 0.0
        ? signal.scrollDelta.dx
        : signal.scrollDelta.dy;
    if (delta.abs() < 0.1) return;
    _scrollTemplateCarouselBy(delta);
  }

  Future<void> _scrollTemplatePage(int direction) async {
    if (!_templateScrollController.hasClients) return;
    final position = _templateScrollController.position;
    const pageWidth = 172.0 * 4; // 4 cards (160) + spacing
    final targetOffset = (position.pixels + (direction * pageWidth))
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((targetOffset - position.pixels).abs() < 0.1) return;
    await _templateScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  void _selectTemplate(TemplateInfo template) {
    setState(() {
      if (_selectedTemplate != template.id) {
        if (template.id == 'elegant_pink') {
          _selectedColor = 5;
        } else {
          _selectedColor = 0;
        }
      }
      _selectedTemplate = template.id;
    });
  }

  Widget _buildTemplateCard(
    TemplateInfo template, {
    required int index,
    required int totalCount,
  }) {
    return SizedBox.expand(
      child: RepaintBoundary(
        child: _TemplateCard(
          template: template,
          isSelected: _selectedTemplate == template.id,
          isLocked: FreePlanService.isTemplateLocked(template.id),
          accentColor: _colorOptions[_selectedColor],
          onTap: () => _selectTemplate(template),
          onPreview: () => _showTemplatePreview(template),
          index: index,
          totalCount: totalCount,
        ),
      ),
    );
  }

  void _loadCurrentTemplate() {
    final resume = StorageService.getResume(widget.resumeId);
    if (resume != null) {
      setState(() {
        _selectedTemplate = resume.templateId;
        _templateFilter = _TemplateFilter.all;
        if (resume.templateId == 'elegant_pink') {
          _selectedColor = 5;
        } else {
          _selectedColor = resume.colorScheme;
        }
      });
    }
  }

  bool _usesFixedPalette(String? templateId) => const {
        'elegant_pink',
        'classic_ats',
        'mono_nova',
        'slate_arc',
        'editorial_frame',
        'graphite_column',
        'rosewood_panel',
        'designer_profile',
        'modern_edge',
        'minimal_clean',
        'minimal_clean_ats',
        'professional_tone',
        'elegant_design',
        'creative_professional',
        'bluewave_tech',
        'balanced_two_column_layout',
        'elegant_gold_layout',
        'corporate_navy',
        'forest_edge_classic',
        'forest_edge',
      }.contains(templateId);

  Color get _selectedTemplatePrimaryColor {
    if (_selectedTemplate == null) return _colorOptions[_selectedColor];
    if (_usesFixedPalette(_selectedTemplate)) {
      try {
        return _templates
            .firstWhere((t) => t.id == _selectedTemplate)
            .primaryColor;
      } catch (_) {
        return _colorOptions[_selectedColor];
      }
    }
    return _colorOptions[_selectedColor];
  }

  List<TemplateInfo> get _photoTemplates =>
      _templates.where((template) => template.hasPhoto).toList();

  List<TemplateInfo> get _nonPhotoTemplates =>
      _templates.where((template) => !template.hasPhoto).toList();

  List<TemplateInfo> get _visibleTemplates {
    switch (_templateFilter) {
      case _TemplateFilter.withPhoto:
        return _photoTemplates;
      case _TemplateFilter.withoutPhoto:
        return _nonPhotoTemplates;
      case _TemplateFilter.all:
        return _templates;
    }
  }

  void _showTemplatePreview(TemplateInfo template) {
    final previewResume = _previewResumeForTemplate(template.id);
    showDialog(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.of(context).size;
        final maxDialogHeight = screenSize.height - 80;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 760,
                maxHeight: maxDialogHeight,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // ΓöÇΓöÇ Title bar ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  template.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(template.icon,
                                size: 18, color: template.primaryColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(template.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                Text(template.description,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    // ΓöÇΓöÇ Preview canvas ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 0.707,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: IgnorePointer(
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: 180,
                                      height: 254,
                                      child: _TemplatePreview(
                                        templateId: template.id,
                                        accentColor:
                                            _colorOptions[_selectedColor],
                                        templateColor: template.primaryColor,
                                        resume: previewResume,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ΓöÇΓöÇ Feature chips ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: template.features
                            .map((f) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: template.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(f,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: template.primaryColor,
                                          fontWeight: FontWeight.w500)),
                                ))
                            .toList(),
                      ),
                    ),
                    // ΓöÇΓöÇ Select button ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _selectedTemplate = template.id);
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            FreePlanService.isTemplateLocked(template.id)
                                ? Iconsax.crown_1
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            FreePlanService.isTemplateLocked(template.id)
                                ? 'Preview Premium Template'
                                : 'Select This Template',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveTemplate() async {
    final resume = StorageService.getResume(widget.resumeId);
    if (resume != null && _selectedTemplate != null) {
      final updatedResume = resume.copyWith(
        templateId: _selectedTemplate!,
        colorScheme: _usesFixedPalette(_selectedTemplate) ? 0 : _selectedColor,
        updatedAt: DateTime.now(),
      );
      final normalizedResume = _selectedTemplate == 'startup'
          ? updatedResume.copyWith(
              customSections: ensureStartupProfileSections(updatedResume),
            )
          : [
              'executive',
              'designer_profile',
              'professional_tone',
              'elegant_gold_layout'
            ].contains(_selectedTemplate)
              ? updatedResume.copyWith(
                  customSections: ensureProfessionalRoleSections(updatedResume),
                )
              : updatedResume;
      await StorageService.saveResume(normalizedResume);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Template applied!')
            ]),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (widget.isNewResume) {
          // For new resumes, go directly to the editor after selecting template
          context.go('/editor/${widget.resumeId}');
        } else {
          context.pop();
        }
      }
    } else if (_selectedTemplate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a template first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (widget.isNewResume) {
              context.go('/editor/${widget.resumeId}');
            } else {
              context.pop();
            }
          },
          icon: const Icon(Iconsax.arrow_left),
        ),
        title: Text(widget.isNewResume ? 'Choose Template' : 'Change Template'),
        actions: [
          TextButton(onPressed: _saveTemplate, child: const Text('Apply')),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useTemplateGrid = constraints.maxWidth >= 1200;
          final previewHeight =
              (constraints.maxHeight * (useTemplateGrid ? 0.28 : 0.42))
                  .clamp(useTemplateGrid ? 180.0 : 220.0,
                      useTemplateGrid ? 260.0 : 360.0)
                  .toDouble();

          Widget buildNewResumeBanner() => Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: AppColors.primary.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Step 1 of 2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Pick a template, then fill in your details',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );

          Widget buildAccentPicker() => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accent Color',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _colorOptions
                            .asMap()
                            .entries
                            .map(
                              (e) => GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = e.key),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: e.value,
                                    shape: BoxShape.circle,
                                    border: _selectedColor == e.key
                                        ? Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          )
                                        : null,
                                    boxShadow: _selectedColor == e.key
                                        ? [
                                            BoxShadow(
                                              color: e.value
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: _selectedColor == e.key
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 20)
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );

          Widget buildSelectedPreview() => SizedBox(
                key: const ValueKey('selected-template-preview'),
                height: previewHeight,
                child: _selectedTemplate != null
                    ? Container(
                        color: Colors.grey.shade100,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 0.707,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: IgnorePointer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    alignment: Alignment.topCenter,
                                    child: SizedBox(
                                      width: 180,
                                      height: 254,
                                      child: _TemplatePreview(
                                        templateId: _selectedTemplate!,
                                        accentColor:
                                            _colorOptions[_selectedColor],
                                        templateColor:
                                            _selectedTemplatePrimaryColor,
                                        resume: _previewResumeForTemplate(
                                          _selectedTemplate!,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Iconsax.document,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Select a template below',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
              );

          Widget buildFilterChips() => Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TemplateCategoryChip(
                        label: 'All Templates',
                        count: _templates.length,
                        selected: _templateFilter == _TemplateFilter.all,
                        onTap: () => _setTemplateFilter(_TemplateFilter.all),
                      ),
                      _TemplateCategoryChip(
                        label: 'Without Photo',
                        count: _nonPhotoTemplates.length,
                        selected:
                            _templateFilter == _TemplateFilter.withoutPhoto,
                        onTap: () =>
                            _setTemplateFilter(_TemplateFilter.withoutPhoto),
                      ),
                      _TemplateCategoryChip(
                        label: 'With Photo',
                        count: _photoTemplates.length,
                        selected: _templateFilter == _TemplateFilter.withPhoto,
                        onTap: () =>
                            _setTemplateFilter(_TemplateFilter.withPhoto),
                      ),
                    ],
                  ),
                ),
              );

          Widget buildTemplateGrid() => Align(
                alignment: Alignment.topLeft,
                child: Container(
                  key: const ValueKey('template-grid'),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(
                      _visibleTemplates.length,
                      (index) {
                        final template = _visibleTemplates[index];
                        return SizedBox(
                          width: 160,
                          height: 258,
                          child: _buildTemplateCard(
                            template,
                            index: index,
                            totalCount: _visibleTemplates.length,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );

          Widget buildTemplateCarousel() => Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          tooltip: 'Previous templates',
                          onPressed: () => _scrollTemplatePage(-1),
                          icon: const Icon(Iconsax.arrow_left_2),
                        ),
                        IconButton(
                          tooltip: 'Next templates',
                          onPressed: () => _scrollTemplatePage(1),
                          icon: const Icon(Iconsax.arrow_right_3),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 258,
                      child: Listener(
                        onPointerSignal: _handleTemplateCarouselPointerSignal,
                        child: Scrollbar(
                          controller: _templateScrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                                PointerDeviceKind.trackpad,
                              },
                            ),
                            child: ListView.builder(
                              key: const ValueKey('template-carousel'),
                              controller: _templateScrollController,
                              scrollDirection: Axis.horizontal,
                              dragStartBehavior: DragStartBehavior.down,
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 0, vertical: 8),
                              itemCount: _visibleTemplates.length,
                              itemBuilder: (context, index) {
                                final template = _visibleTemplates[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index == _visibleTemplates.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: SizedBox(
                                    width: 160,
                                    child: _buildTemplateCard(
                                      template,
                                      index: index,
                                      totalCount: _visibleTemplates.length,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );

          if (useTemplateGrid) {
            return Column(
              children: [
                if (widget.isNewResume) buildNewResumeBanner(),
                if (!_usesFixedPalette(_selectedTemplate))
                  buildAccentPicker().animate().fadeIn(duration: 400.ms),
                buildSelectedPreview(),
                buildFilterChips(),
                Expanded(
                  child: Scrollbar(
                    controller: _templateGridScrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                          PointerDeviceKind.trackpad,
                        },
                      ),
                      child: SingleChildScrollView(
                        key: const ValueKey('template-grid-scroll'),
                        controller: _templateGridScrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: buildTemplateGrid(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  if (widget.isNewResume) buildNewResumeBanner(),
                  if (!_usesFixedPalette(_selectedTemplate))
                    buildAccentPicker().animate().fadeIn(duration: 400.ms),
                  buildSelectedPreview(),
                  buildFilterChips(),
                  buildTemplateCarousel(),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.isNewResume
                    ? () => context.go('/editor/${widget.resumeId}')
                    : () async {
                        final r = StorageService.getResume(widget.resumeId);
                        if (r != null && _selectedTemplate != null) {
                          final updatedResume = r.copyWith(
                            templateId: _selectedTemplate!,
                            colorScheme: _usesFixedPalette(_selectedTemplate)
                                ? 0
                                : _selectedColor,
                            updatedAt: DateTime.now(),
                          );
                          final normalizedResume =
                              _selectedTemplate == 'startup'
                                  ? updatedResume.copyWith(
                                      customSections:
                                          ensureStartupProfileSections(
                                              updatedResume),
                                    )
                                  : [
                                      'executive',
                                      'designer_profile',
                                      'professional_tone',
                                      'elegant_gold_layout',
                                    ].contains(_selectedTemplate)
                                      ? updatedResume.copyWith(
                                          customSections:
                                              ensureProfessionalRoleSections(
                                                  updatedResume),
                                        )
                                      : updatedResume;
                          await StorageService.saveResume(normalizedResume);
                        }
                        if (mounted) {
                          context.push('/preview/${widget.resumeId}');
                        }
                      },
                icon: Icon(
                  widget.isNewResume ? Iconsax.arrow_right : Iconsax.eye,
                ),
                label: Text(widget.isNewResume ? 'Skip' : 'Preview'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saveTemplate,
                icon: const Icon(Iconsax.tick_circle),
                label: Text(widget.isNewResume
                    ? 'Apply & Start Editing'
                    : 'Apply Template'),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
    );
  }
}

class TemplateInfo {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final List<String> features;
  final bool hasPhoto;

  TemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.features,
    this.hasPhoto = false,
  });
}

class _TemplateCategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TemplateCategoryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final TemplateInfo template;
  final bool isSelected;
  final bool isLocked;
  final Color accentColor;
  final VoidCallback onTap;
  final VoidCallback onPreview;
  final int index;
  final int totalCount;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.isLocked,
    required this.accentColor,
    required this.onTap,
    required this.onPreview,
    required this.index,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('template-card-${template.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          height: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? template.primaryColor : AppColors.divider,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: template.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 2)
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index/Total display
              Padding(
                padding:
                    const EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 2),
                child: Text(
                  '${index + 1}/$totalCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // ΓöÇΓöÇ Mini-layout preview ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              Expanded(
                child: Stack(
                  children: [
                    SizedBox.expand(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          child: FittedBox(
                            fit: BoxFit.fill,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: 180,
                              height: 254,
                              child: _TemplatePreview(
                                templateId: template.id,
                                accentColor: template.primaryColor,
                                templateColor: template.primaryColor,
                                resume: _templatePreviewSampleResume,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Selected badge
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: template.primaryColor,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    if (isLocked)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Iconsax.lock_1,
                                  color: Colors.white, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'Premium',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Preview button
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: GestureDetector(
                        key: ValueKey('template-preview-${template.id}'),
                        onTap: onPreview,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.52),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined,
                                  color: Colors.white, size: 10),
                              SizedBox(width: 3),
                              Text('Preview',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ΓöÇΓöÇ Label ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isLocked ? AppColors.textSecondary : null,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      template.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TemplatePreviewThumbnail extends StatelessWidget {
  final String templateId;
  final Color accentColor;
  final double width;
  final bool showShadow;
  final BorderRadius borderRadius;
  final ResumeModel? resume;

  const TemplatePreviewThumbnail({
    super.key,
    required this.templateId,
    required this.accentColor,
    this.width = 72,
    this.showShadow = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.resume,
  });

  @override
  Widget build(BuildContext context) {
    final previewResume = resume ?? _templatePreviewSampleResume;

    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 0.707,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: IgnorePointer(
              child: FittedBox(
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 180,
                  height: 254,
                  child: _TemplatePreview(
                    templateId: templateId,
                    accentColor: accentColor,
                    templateColor: accentColor,
                    resume: previewResume,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ΓöÇΓöÇΓöÇ Realistic mini-layout previews ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
final ResumeModel _templatePreviewSampleResume = ResumeModel(
  id: 'template-preview-sample',
  title: 'Template Preview',
  personalInfo: PersonalInfo(
    fullName: 'John Smith',
    email: 'john.smith@email.com',
    phone: '(555) 123-4567',
    address: 'New York, NY',
    linkedIn: 'linkedin.com/in/johnsmith',
    github: 'github.com/johnsmith',
    website: 'johnsmith.dev',
    jobTitle: 'Software Engineer',
  ),
  objective:
      'Results-driven professional with expertise in delivering high-quality solutions across web, mobile, and cloud products.',
  education: [
    Education(
      id: 'preview-edu-1',
      institution: 'State University',
      degree: 'B.Sc. Computer Science',
      fieldOfStudy: 'Software Engineering',
      startDate: DateTime(2015, 8),
      endDate: DateTime(2019, 5),
      grade: '3.8 GPA',
    ),
  ],
  experience: [
    Experience(
      id: 'preview-exp-1',
      company: 'TechCorp',
      position: 'Senior Developer',
      location: 'New York, NY',
      startDate: DateTime(2021, 1),
      isCurrentlyWorking: true,
      description:
          'Led development of scalable cloud-based products and improved delivery quality across cross-functional teams.',
      achievements: [
        'Led team of 5 to deliver cloud-based platform',
        'Reduced load time by 40% via code optimisation',
      ],
    ),
    Experience(
      id: 'preview-exp-2',
      company: 'StartupXYZ',
      position: 'Junior Developer',
      location: 'Boston, MA',
      startDate: DateTime(2019, 6),
      endDate: DateTime(2020, 12),
      description:
          'Built product features and collaborated with designers and QA on reliable releases.',
      achievements: [
        'Implemented reusable UI components for the core dashboard',
      ],
    ),
  ],
  skills: [
    Skill(id: 'skill-1', name: 'Flutter'),
    Skill(id: 'skill-2', name: 'Dart'),
    Skill(id: 'skill-3', name: 'Firebase'),
    Skill(id: 'skill-4', name: 'REST APIs'),
    Skill(id: 'skill-5', name: 'Git'),
  ],
  projects: [
    Project(
      id: 'project-1',
      title: 'Portfolio Website',
      description:
          'Developed a responsive portfolio site showcasing projects and skills.',
      technologies: const ['Flutter', 'Firebase'],
    ),
    Project(
      id: 'project-2',
      title: 'Task Management App',
      description:
          'Built a productivity-focused app with authentication and offline sync.',
      technologies: const ['React', 'Node.js'],
    ),
  ],
  certifications: [
    Certification(
      id: 'cert-1',
      name: 'AWS Certified Developer',
      issuer: 'Amazon',
    ),
    Certification(
      id: 'cert-2',
      name: 'Scrum Master',
      issuer: 'Scrum Alliance',
    ),
  ],
  languages: [
    Language(id: 'lang-1', name: 'English', proficiency: 'Professional'),
    Language(id: 'lang-2', name: 'German', proficiency: 'Professional'),
  ],
  createdAt: DateTime(2024, 1, 1),
  updatedAt: DateTime(2024, 1, 1),
);

class _TemplatePreview extends StatelessWidget {
  final String templateId;
  final Color accentColor;
  final Color? templateColor;
  final ResumeModel? resume;

  const _TemplatePreview({
    required this.templateId,
    required this.accentColor,
    this.templateColor,
    this.resume,
  });

  // ΓöÇΓöÇ Data (uses actual resume when available, falls back to placeholder) ΓöÇΓöÇΓöÇΓöÇ
  String get _name {
    if (resume == null) return 'JOHN SMITH';
    final n = resume!.personalInfo.fullName;
    return n.isNotEmpty ? n : 'JOHN SMITH';
  }

  String get _title {
    if (resume == null) return 'Software Engineer';
    return resume!.personalInfo.jobTitle?.isNotEmpty == true
        ? resume!.personalInfo.jobTitle!
        : 'Software Engineer';
  }

  String get _job1 => (resume != null && resume!.experience.isNotEmpty)
      ? resume!.experience[0].position
      : 'Senior Developer';

  String get _co1 {
    if (resume == null || resume!.experience.isEmpty) {
      return 'TechCorp  ┬╖  2021 ΓÇô Present';
    }
    final e = resume!.experience[0];
    final end = e.isCurrentlyWorking
        ? 'Present'
        : (e.endDate?.year.toString() ?? 'Present');
    return '${e.company}  ┬╖  ${e.startDate.year} ΓÇô $end';
  }

  String get _job2 => (resume != null && resume!.experience.length > 1)
      ? resume!.experience[1].position
      : 'Junior Developer';

  String get _co2 {
    if (resume == null || resume!.experience.length < 2) {
      return 'StartupXYZ  ┬╖  2019 ΓÇô 2021';
    }
    final e = resume!.experience[1];
    final end = e.isCurrentlyWorking
        ? 'Present'
        : (e.endDate?.year.toString() ?? 'Present');
    return '${e.company}  ┬╖  ${e.startDate.year} ΓÇô $end';
  }

  String get _edu {
    if (resume == null || resume!.education.isEmpty) {
      return 'B.Sc. Computer Science';
    }
    final ed = resume!.education[0];
    return '${ed.degree} ${ed.fieldOfStudy}'.trim();
  }

  String get _uni {
    if (resume == null || resume!.education.isEmpty) {
      return 'State University  ┬╖  2019';
    }
    final ed = resume!.education[0];
    final year = ed.endDate?.year ?? ed.startDate.year;
    return '${ed.institution}  ┬╖  $year';
  }

  String get _desc1 {
    if (resume == null || resume!.experience.isEmpty) {
      return 'Led team of 5 to deliver cloud-based platform';
    }
    final e = resume!.experience[0];
    if (e.achievements.isNotEmpty) return e.achievements[0];
    return e.description.isNotEmpty
        ? e.description
        : 'Led team of 5 to deliver cloud-based platform';
  }

  String get _desc2 {
    if (resume == null || resume!.experience.isEmpty) {
      return 'Reduced load time by 40% via code optimisation';
    }
    final e = resume!.experience[0];
    if (e.achievements.length > 1) return e.achievements[1];
    if (e.description.isNotEmpty) return e.description;
    return 'Reduced load time by 40% via code optimisation';
  }

  List<String> get _skills {
    if (resume == null || resume!.skills.isEmpty) {
      return ['Flutter', 'Dart', 'Firebase', 'REST APIs', 'Git'];
    }
    return resume!.skills.map((s) => s.name).toList();
  }

  List<String> _splitStartupSectionText(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    return raw
        .split(RegExp(r'\n+|,+|[\u2022ΓÇó]+'))
        .map((item) => item.replaceFirst(RegExp(r'^[-*]\s*'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _startupCustomSectionLines(String sectionId) {
    if (resume == null) {
      return const [];
    }

    final matches =
        resume!.customSections.where((section) => section.id == sectionId);
    if (matches.isEmpty) {
      return const [];
    }

    final collected = <String>[];
    for (final item in matches.first.items) {
      for (final value in [item.title, item.subtitle, item.description]) {
        for (final part in _splitStartupSectionText(value)) {
          if (!collected.contains(part)) {
            collected.add(part);
          }
        }
      }
    }

    return collected;
  }

  List<String> get _startupToolLines {
    if (_skills.isNotEmpty) {
      return _skills;
    }

    final customToolLines = _startupCustomSectionLines('startup_tools');
    final merged = <String>[];
    for (final line in customToolLines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !merged.contains(trimmed)) {
        merged.add(trimmed);
      }
    }
    return merged;
  }

  List<Experience> get _startupExperiences {
    if (resume != null && resume!.experience.isNotEmpty) {
      return resume!.experience;
    }
    return _templatePreviewSampleResume.experience;
  }

  List<String> _startupExperienceHighlights(Experience exp) {
    final highlights = <String>[];

    for (final achievement in exp.achievements) {
      final trimmed = achievement.trim();
      if (trimmed.isNotEmpty && !highlights.contains(trimmed)) {
        highlights.add(trimmed);
      }
    }

    for (final line in _splitLines(exp.description, maxItems: 6)) {
      if (!highlights.contains(line)) {
        highlights.add(line);
      }
    }

    return highlights;
  }

  String _startupExperienceMeta(Experience exp) {
    final end = exp.isCurrentlyWorking
        ? 'Present'
        : (exp.endDate?.year.toString() ?? 'Present');
    final parts = <String>[
      if (exp.company.trim().isNotEmpty) exp.company.trim(),
      '${exp.startDate.year} ΓÇô $end',
    ];
    return parts.join('  ┬╖  ');
  }

  Widget _startupExperienceBlock(Experience exp) {
    final highlights = _startupExperienceHighlights(exp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _txt(exp.position,
            size: 4.5,
            color: Colors.grey.shade900,
            weight: FontWeight.w700,
            maxLines: 2),
        _txt(_startupExperienceMeta(exp),
            size: 3.4, color: Colors.grey.shade500, maxLines: 1),
        if (highlights.isNotEmpty) ...[
          const SizedBox(height: 1.5),
          ...highlights.map(
            (highlight) => Padding(
              padding: const EdgeInsets.only(bottom: 1.2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ΓÇó ',
                      style: TextStyle(
                          fontSize: 3.6, color: accentColor, height: 1.15)),
                  Expanded(
                    child: _txt(
                      highlight,
                      size: 3.1,
                      color: Colors.grey.shade700,
                      maxLines: 0,
                      justify: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String get _objective {
    if (resume == null || (resume!.objective ?? '').isEmpty) {
      return 'Results-driven professional with expertise in delivering high-quality solutions.';
    }
    return resume!.objective!;
  }

  String get _address {
    if (resume == null || resume!.personalInfo.address.isEmpty) {
      return 'New York, NY';
    }
    return resume!.personalInfo.address;
  }

  String get _emailOnly {
    if (resume == null) return 'john@email.com';
    return resume!.personalInfo.email.isNotEmpty
        ? resume!.personalInfo.email
        : 'john@email.com';
  }

  String get _phone {
    if (resume == null) return '(555) 123-4567';
    return resume!.personalInfo.phone.isNotEmpty
        ? resume!.personalInfo.phone
        : '(555) 123-4567';
  }

  String get _linkedin {
    if (resume == null) return 'linkedin.com/in/js';
    return (resume!.personalInfo.linkedIn?.isNotEmpty ?? false)
        ? resume!.personalInfo.linkedIn!
        : 'linkedin.com/in/js';
  }

  String get _github {
    if (resume == null) return 'github.com/jsmith';
    return (resume!.personalInfo.github?.isNotEmpty ?? false)
        ? resume!.personalInfo.github!
        : 'github.com/jsmith';
  }

  String get _website {
    if (resume == null) return 'johnsmith.dev';
    return (resume!.personalInfo.website?.isNotEmpty ?? false)
        ? resume!.personalInfo.website!
        : 'johnsmith.dev';
  }

  String _yearRange(DateTime start, DateTime? end, bool isCurrent) {
    final endText = isCurrent ? 'Present' : (end?.year.toString() ?? 'Present');
    return '${start.year} - $endText';
  }

  String get _eduRange {
    if (resume == null || resume!.education.isEmpty) return '2016 - 2020';
    final ed = resume!.education.first;
    return _yearRange(ed.startDate, ed.endDate, ed.isCurrentlyStudying);
  }

  String get _exp1Range {
    if (resume == null || resume!.experience.isEmpty) return '2021 - Present';
    final exp = resume!.experience.first;
    return _yearRange(exp.startDate, exp.endDate, exp.isCurrentlyWorking);
  }

  String get _exp2Range {
    if (resume == null || resume!.experience.length < 2) return '2019 - 2021';
    final exp = resume!.experience[1];
    return _yearRange(exp.startDate, exp.endDate, exp.isCurrentlyWorking);
  }

  String get _company1 {
    if (resume == null || resume!.experience.isEmpty) return 'TechCorp';
    return resume!.experience.first.company.isNotEmpty
        ? resume!.experience.first.company
        : 'TechCorp';
  }

  String _cleanPreviewListMarker(String text) {
    final withoutBullet = text.trim().replaceFirst(
          RegExp(r'^[-ΓÇó*Γû¬ΓûáΓûíΓ£¬Γ£ªΓÿàΓÿå]+\s*'),
          '',
        );
    return withoutBullet.replaceFirst(RegExp(r'^[xX]\s+'), '').trim();
  }

  List<String> _splitLines(String text, {int? maxItems = 4}) {
    final raw = text.trim();
    if (raw.isEmpty) return const [];
    final parts = raw
        .split(RegExp(r'\n+|(?<=[.!?])\s+'))
        .map(_cleanPreviewListMarker)
        .where((item) => item.isNotEmpty)
        .toList();
    if (maxItems == null) {
      return parts;
    }
    return parts.take(maxItems).toList();
  }

  List<String> get _aboutLines {
    final lines = _splitLines(_objective, maxItems: 5);
    return lines.isNotEmpty
        ? lines
        : const [
            'Results-driven professional with expertise in delivering high-quality solutions'
          ];
  }

  List<String> get _languageLines {
    if (resume != null && resume!.languages.isNotEmpty) {
      return resume!.languages
          .map((lang) => '${lang.name} ${lang.proficiency}'.trim())
          .take(4)
          .toList();
    }
    return const ['English Professional', 'German Professional'];
  }

  List<String> get _allLanguageLines {
    if (resume != null && resume!.languages.isNotEmpty) {
      return resume!.languages
          .map((lang) => '${lang.name} ${lang.proficiency}'.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    }
    return const ['English Professional', 'German Professional'];
  }

  List<String> get _projectLines {
    if (resume != null && resume!.projects.isNotEmpty) {
      return resume!.projects.map((project) => project.title).take(4).toList();
    }
    return const ['Portfolio Website', 'Task Management App'];
  }

  List<String> get _projectUrls {
    if (resume != null && resume!.projects.isNotEmpty) {
      return resume!.projects
          .map((project) => (project.url ?? '').trim())
          .take(4)
          .toList();
    }
    return const ['portfolio.example.com', 'tasks.example.com'];
  }

  List<String> get _projectDetails {
    if (resume != null && resume!.projects.isNotEmpty) {
      return resume!.projects
          .map((project) => project.description.isNotEmpty
              ? project.description
              : project.technologies.join(' ΓÇó '))
          .take(4)
          .toList();
    }
    return const [
      'Developed a responsive portfolio site showcasing projects and skills',
      'Built a productivity-focused web app using React and Node.js',
    ];
  }

  List<String> _splitProjectLines(String text, {int? maxItems = 2}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final parts = raw
        .split(RegExp(r'\n+|[\u2022ΓÇó]+|(?<=[.!?])\s+'))
        .map(_cleanPreviewListMarker)
        .where((item) => item.isNotEmpty)
        .toList();

    if (maxItems == null) {
      return parts;
    }
    return parts.take(maxItems).toList();
  }

  String _projectUrlAt(int index) {
    if (index < 0 || index >= _projectUrls.length) {
      return '';
    }
    return _projectUrls[index].trim();
  }

  List<String> get _certificationLines {
    if (resume != null && resume!.certifications.isNotEmpty) {
      return resume!.certifications
          .map((cert) => cert.issuer.isNotEmpty
              ? '${cert.name} ┬╖ ${cert.issuer}'
              : cert.name)
          .take(3)
          .toList();
    }
    return const [
      'AWS Certified Developer ┬╖ Amazon',
      'Scrum Master ┬╖ Scrum Alliance',
    ];
  }

  String _compactPreviewSummary(
    Iterable<String> items, {
    String separator = '  ΓÇó  ',
  }) {
    return items
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .join(separator);
  }

  double _densePreviewFontSize(
    int itemCount, {
    required double regular,
    required double compact,
    required double dense,
  }) {
    if (itemCount >= 8) {
      return dense;
    }
    if (itemCount >= 5) {
      return compact;
    }
    return regular;
  }

  Widget _prefixedLines(
    List<String> lines, {
    required String prefix,
    required double size,
    required Color color,
    int maxLines = 2,
    double gap = 1,
    bool justify = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map((line) => Padding(
                  padding: EdgeInsets.only(bottom: gap),
                  child: _txt('$prefix $line',
                      size: size,
                      color: color,
                      maxLines: maxLines,
                      justify: justify),
                ))
            .toList(),
      );

  Widget _numberedLines(
    List<String> lines, {
    required double size,
    required Color color,
    int maxLines = 2,
    double gap = 1,
    bool justify = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.asMap().entries.map((entry) {
          final number = entry.key + 1;
          return Padding(
            padding: EdgeInsets.only(bottom: gap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 8,
                  child: _txt('$number.',
                      size: size,
                      color: color,
                      weight: FontWeight.w700,
                      maxLines: 1),
                ),
                Expanded(
                  child: _txt(entry.value,
                      size: size,
                      color: color,
                      maxLines: maxLines,
                      justify: justify),
                ),
              ],
            ),
          );
        }).toList(),
      );

  Color get _templateBaseColor => templateColor ?? accentColor;

  // ΓöÇΓöÇ Tiny text helper ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _txt(String text,
          {double size = 5.0,
          Color? color,
          FontWeight weight = FontWeight.normal,
          bool center = false,
          int maxLines = 1,
          bool justify = false}) =>
      Text(
        text,
        textAlign: center
            ? TextAlign.center
            : (justify ? TextAlign.justify : TextAlign.left),
        maxLines: maxLines <= 0 ? null : maxLines,
        overflow: maxLines <= 0 ? TextOverflow.visible : TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: size,
          color: color ?? Colors.grey.shade700,
          fontWeight: weight,
          height: 1.15,
        ),
      );

  Widget _divider(Color c) => Container(
      height: 0.8, color: c, margin: const EdgeInsets.symmetric(vertical: 2));

  Widget _dotIcon(Color color) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );

  Widget _skillChip(String label, Color bg, Color text) => Container(
        constraints: const BoxConstraints(maxWidth: 70),
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
        margin: const EdgeInsets.only(right: 2, bottom: 1.5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 4.5, color: text, fontWeight: FontWeight.w500)),
      );

  Widget _section(String title, Color color) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 1),
        child: _txt(title.toUpperCase(),
            size: 5.0, color: color, weight: FontWeight.bold),
      );

  @override
  Widget build(BuildContext context) {
    late final Widget preview;
    switch (templateId) {
      case 'modern':
        preview = ModernNovaTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'creative':
        preview = CreativeResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'developer':
        preview = DeveloperResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'blue_gray':
        preview = _buildBlueGray();
        break;
      case 'two_column':
        preview = TwoColumnResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'infographic':
        preview = _buildInfographic();
        break;
      case 'startup':
        preview = _buildStartup();
        break;
      case 'elegant_pink':
        preview = PinkRoseModernTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'classic':
        preview = ClassicResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'executive':
        preview = BusinessManagementResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;

      case 'sales':
        preview = SalesAndMarketingResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'academic':
        preview = AcademicResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'minimal':
        preview = MinimalResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'professional':
        preview = ProfessionalResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'modern_aesthetic':
        preview = _buildModernAesthetic();
        break;
      case 'classic_ats':
        preview = ClassicAtsResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'classic2':
        preview = _buildClassic2();
        break;
      case 'education_resume':
        preview = EducationResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'modern_resume':
        preview = EliteResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'professional_accountant':
        preview = ProfessionalAccountantResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'one_page_resume':
        preview = OnePageResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'classic_temp':
        preview = ClassicTempResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'emerald_executive':
        preview = EmeraldExecutiveResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'cool_blue':
        preview = _buildCoolBlue();
        break;
      case 'multicolor':
        preview = _buildMulticolor();
        break;
      case 'entry_level':
        preview = EntryLevelResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'ats_optimized_clean':
        preview = AtsOptimizedCleanResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'ats_standard_format':
        preview = AtsStandardFormatResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'ats_friendly_modern':
        preview = AtsFriendlyModernResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'executive_classic':
        preview = ExecutiveClassicResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'vertical_timeline':
        preview = VerticalTimelineTemplatePreview(
            accentColor: accentColor,
            templateColor: templateColor,
            resume: resume);
        break;
      case 'corporate_template':
        preview = CorporateResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'mono_nova':
        preview = MonoNovaTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'slate_arc':
        preview = SlateArcResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'editorial_frame':
        preview = EditorialFrameResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'graphite_column':
        preview = GraphiteColumnResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'rosewood_panel':
        preview = RosewoodPanelResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'designer_profile':
        preview = DesignerProfileResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'modern_edge':
        preview = _buildModernEdge(accentColor, templateColor, resume);
        break;
      case 'minimal_clean':
        preview = MinimalCleanResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'minimal_clean_ats':
        preview = MinimalCleanAtsResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'professional_tone':
        preview = HealthcareResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'elegant_design':
        preview = ElegantDesignResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'creative_professional':
        preview = CreativeProfessionalResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'bluewave_tech':
        preview = BluewaveTechResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'balanced_two_column_layout':
        preview = BalancedTwoColumnLayoutTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'elegant_gold_layout':
        preview = ElegantGoldLayoutTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'corporate_navy':
        preview = CorporateNavyTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'forest_edge_classic':
        preview = ForestEdgeClassicResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      case 'forest_edge':
        preview = ForestEdgeResumeTemplatePreview(
          accentColor: accentColor,
          templateColor: templateColor,
          resume: resume,
        );
        break;
      default:
        preview = _buildModern();
        break;
    }

    return preview;
  }

  // ΓöÇΓöÇ Modern / default ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildModern() => Container(
        color: Colors.white,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _txt(_name,
                            size: 7.8,
                            color: Colors.white,
                            weight: FontWeight.bold),
                        const SizedBox(height: 2),
                        _txt(_title,
                            size: 4.9,
                            color: Colors.white.withValues(alpha: 0.88)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _txt(_emailOnly,
                          size: 3.7,
                          color: Colors.white.withValues(alpha: 0.82),
                          maxLines: 1),
                      _txt(_phone,
                          size: 3.7,
                          color: Colors.white.withValues(alpha: 0.82)),
                      _txt(_address,
                          size: 3.7,
                          color: Colors.white.withValues(alpha: 0.82),
                          maxLines: 1),
                      _txt(_linkedin,
                          size: 3.7,
                          color: Colors.white.withValues(alpha: 0.82),
                          maxLines: 1),
                      _txt(_github,
                          size: 3.7,
                          color: Colors.white.withValues(alpha: 0.82),
                          maxLines: 1),
                      _txt(_website,
                          size: 3.7,
                          color: Colors.white.withValues(alpha: 0.82),
                          maxLines: 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_objective.isNotEmpty) ...[
                        _section('Objective', accentColor),
                        _divider(accentColor.withValues(alpha: 0.3)),
                        _prefixedLines(
                          _aboutLines.take(8).toList(),
                          prefix: 'ΓÇó',
                          size: 4.0,
                          color: Colors.grey.shade700,
                          maxLines: 0,
                          gap: 1.5,
                          justify: true,
                        ),
                      ],
                      _section('Experience', accentColor),
                      _divider(accentColor.withValues(alpha: 0.3)),
                      _txt(_job1,
                          size: 5.5,
                          color: Colors.grey.shade800,
                          weight: FontWeight.w600),
                      _txt(_co1, size: 4.5, color: accentColor),
                      _txt(_desc1, size: 4.5, justify: true),
                      const SizedBox(height: 3),
                      _txt(_job2,
                          size: 5.5,
                          color: Colors.grey.shade800,
                          weight: FontWeight.w600),
                      _txt(_co2, size: 4.5, color: accentColor),
                      _section('Education', accentColor),
                      _divider(accentColor.withValues(alpha: 0.3)),
                      _txt(_edu,
                          size: 5.5,
                          color: Colors.grey.shade800,
                          weight: FontWeight.w600),
                      _txt(_uni, size: 4.5),
                      _section('Skills', accentColor),
                      _divider(accentColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 2),
                      Wrap(
                          children: _skills
                              .map((s) => _skillChip(
                                  s,
                                  accentColor.withValues(alpha: 0.12),
                                  accentColor))
                              .toList()),
                      _section('Projects', accentColor),
                      _divider(accentColor.withValues(alpha: 0.3)),
                      ...List.generate(
                        _projectLines.take(3).length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _txt(_projectLines[index],
                                  size: 4.5,
                                  color: Colors.grey.shade800,
                                  weight: FontWeight.w600,
                                  maxLines: 0),
                              if (index < _projectDetails.length)
                                _prefixedLines(
                                  _splitLines(
                                    _projectDetails[index],
                                    maxItems: 4,
                                  ),
                                  prefix: 'ΓÇó',
                                  size: 3.8,
                                  color: Colors.grey.shade700,
                                  maxLines: 0,
                                  gap: 1.2,
                                  justify: true,
                                ),
                            ],
                          ),
                        ),
                      ),
                      _section('Certifications', accentColor),
                      _divider(accentColor.withValues(alpha: 0.3)),
                      ..._certificationLines.map((c) =>
                          _txt(c, size: 4.0, color: Colors.grey.shade700)),
                      _section('Languages', accentColor),
                      _divider(accentColor.withValues(alpha: 0.3)),
                      ..._languageLines.map(
                        (l) => _txt(l, size: 4.0, color: Colors.grey.shade700),
                      ),
                    ]),
              ),
            ),
          ),
        ]),
      );

  // ΓöÇΓöÇ FlexColor Sidebar ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildBlueGray() {
    return FlexColorSidebarTemplatePreview(
      accentColor: accentColor,
      templateColor: _templateBaseColor,
      resume: resume,
    );
  }

  // ΓöÇΓöÇ Infographic ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildInfographic() {
    return InfographicResumeTemplatePreview(
      accentColor: accentColor,
      templateColor: templateColor,
      resume: resume,
    );
  }

  // ΓöÇΓöÇ Pink Ros├⌐ Modern ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildStartup() => Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor,
                      accentColor.withValues(alpha: 0.82),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt(_name.toUpperCase(),
                              size: 7.4,
                              color: Colors.white,
                              weight: FontWeight.bold),
                          _txt(_title,
                              size: 4.7,
                              color: Colors.white.withValues(alpha: 0.92)),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 5,
                            runSpacing: 1,
                            children: [
                              _emailOnly,
                              _phone,
                              _address,
                              _linkedin,
                              _github,
                              _website
                            ]
                                .where((s) => s.isNotEmpty)
                                .map<Widget>((s) => _txt(s,
                                    size: 2.8,
                                    color:
                                        Colors.white.withValues(alpha: 0.70)))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _startupMiniCard(
                                'IMPACT',
                                [_desc1, _desc2],
                                accentColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: _startupMiniCard(
                                'TOOLS',
                                _startupToolLines,
                                accentColor,
                                commaSeparated: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        _section('ABOUT', accentColor),
                        _numberedLines(
                          _aboutLines.take(8).toList(),
                          size: 3.0,
                          color: Colors.grey.shade700,
                          maxLines: 4,
                          gap: 1.4,
                          justify: true,
                        ),
                        const SizedBox(height: 4),
                        _section('EXPERIENCE', accentColor),
                        ..._startupExperiences.asMap().entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key ==
                                          _startupExperiences.length - 1
                                      ? 0
                                      : 3,
                                ),
                                child: _startupExperienceBlock(entry.value),
                              ),
                            ),
                        if (_projectLines.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _section('PROJECTS', accentColor),
                          ...List.generate(
                            _projectLines.take(2).length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _txt(_projectLines[index],
                                      size: 4.1,
                                      color: Colors.grey.shade900,
                                      weight: FontWeight.w600,
                                      maxLines: 1),
                                  if (index < _projectDetails.length)
                                    _txt(_projectDetails[index],
                                        size: 3.0,
                                        color: Colors.grey.shade700,
                                        maxLines: 2),
                                  if (resume != null &&
                                      resume!.projects.length > index &&
                                      (resume!.projects[index].url
                                              ?.trim()
                                              .isNotEmpty ??
                                          false))
                                    _txt(resume!.projects[index].url!.trim(),
                                        size: 2.8,
                                        color: accentColor,
                                        maxLines: 1),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        _section('EDUCATION', accentColor),
                        _txt(_edu,
                            size: 4.1,
                            color: Colors.grey.shade900,
                            weight: FontWeight.w600),
                        _txt(_uni, size: 3.3, color: Colors.grey.shade500),
                        if (_certificationLines.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _section('CERTIFICATIONS', accentColor),
                          ..._certificationLines.take(3).map((c) => _txt(c,
                              size: 3.3,
                              color: Colors.grey.shade700,
                              maxLines: 2)),
                        ],
                        if (_languageLines.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _section('LANGUAGES', accentColor),
                          ..._languageLines.take(3).map((l) => _txt(l,
                              size: 3.3,
                              color: Colors.grey.shade700,
                              maxLines: 1)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _startupMiniCard(
    String label,
    List<String> lines,
    Color color, {
    bool commaSeparated = false,
  }) =>
      Container(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(label, size: 3.8, color: color, weight: FontWeight.bold),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 2),
              if (commaSeparated)
                _txt(
                  lines.join(', '),
                  size: 3.0,
                  color: Colors.grey.shade700,
                  maxLines: 0,
                  justify: true,
                )
              else
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 1.5),
                    child: _txt('ΓÇó $line',
                        size: 3.0, color: Colors.grey.shade700, maxLines: 2),
                  ),
                ),
            ],
          ],
        ),
      );

  Widget _buildModernAesthetic() => Container(
        color: Colors.white,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: Column(children: [
              _txt(_name,
                  size: 8.5,
                  color: Colors.grey.shade900,
                  weight: FontWeight.bold,
                  center: true),
              const SizedBox(height: 2),
              _txt(_title, size: 5.5, color: accentColor, center: true),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Container(height: 0.8, color: accentColor)),
                const SizedBox(width: 4),
                Flexible(
                  child: _txt(_emailOnly,
                      size: 4.0, color: Colors.grey.shade500, center: true),
                ),
                const SizedBox(width: 4),
                Expanded(child: Container(height: 0.8, color: accentColor)),
              ]),
              const SizedBox(height: 3),
              _txt(
                  [_phone, _address, _linkedin, _github, _website]
                      .where((s) => s.isNotEmpty)
                      .join('  ΓÇó  '),
                  size: 3.5,
                  color: Colors.grey.shade500,
                  center: true),
            ]),
          ),
          Container(height: 1.0, color: accentColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...orderedUserCustomSectionsFromList(
                        resume?.customSections ?? const <CustomSection>[],
                      ).expand((section) {
                        final title =
                            normalizeUserCustomSectionTitle(section.title);
                        final itemWidgets = section.items.expand((item) {
                          final displayItem =
                              buildUserCustomSectionDisplayItem(item);
                          final metaParts = <String>[
                            if (displayItem.subtitle.isNotEmpty)
                              displayItem.subtitle,
                            if (displayItem.date != null)
                              '${displayItem.date!.month.toString().padLeft(2, '0')}/${displayItem.date!.year}',
                          ];

                          if (!displayItem.hasContent) {
                            return const <Widget>[];
                          }

                          return <Widget>[
                            if (displayItem.heading.isNotEmpty)
                              _txt(
                                displayItem.heading,
                                size: 4.3,
                                color: Colors.grey.shade800,
                                weight: FontWeight.w600,
                                maxLines: 0,
                              ),
                            if (metaParts.isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 1, bottom: 1),
                                child: _txt(
                                  metaParts.join('  |  '),
                                  size: 3.8,
                                  color: Colors.grey.shade500,
                                  maxLines: 0,
                                ),
                              ),
                            ...displayItem.detailLines.map(
                              (line) => Padding(
                                padding: const EdgeInsets.only(bottom: 1.2),
                                child: _txt(
                                  '• $line',
                                  size: 3.9,
                                  color: Colors.grey.shade700,
                                  maxLines: 0,
                                  justify: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                          ];
                        }).toList(growable: false);

                        if (itemWidgets.isEmpty) {
                          return const <Widget>[];
                        }

                        return <Widget>[
                          _section(title.isEmpty ? 'Custom Section' : title,
                              accentColor),
                          ...itemWidgets,
                        ];
                      }),
                      _section('SUMMARY', accentColor),
                      _prefixedLines(
                        _aboutLines.take(8).toList(),
                        prefix: 'ΓÇó',
                        size: 4.0,
                        color: Colors.grey.shade700,
                        maxLines: 0,
                        gap: 1.4,
                      ),
                      _section('EXPERIENCE', accentColor),
                      ..._startupExperiences.take(2).map(
                            (exp) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _txt(exp.position,
                                      size: 5.3,
                                      color: Colors.grey.shade800,
                                      weight: FontWeight.w600,
                                      maxLines: 0),
                                  _txt(_startupExperienceMeta(exp),
                                      size: 4.3,
                                      color: Colors.grey.shade500,
                                      maxLines: 1),
                                  if (_startupExperienceHighlights(exp)
                                      .isNotEmpty)
                                    _prefixedLines(
                                      _startupExperienceHighlights(exp),
                                      prefix: 'ΓÇó',
                                      size: 3.9,
                                      color: Colors.grey.shade700,
                                      maxLines: 0,
                                      gap: 1.2,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      _section('EDUCATION', accentColor),
                      _txt(_edu,
                          size: 5.2,
                          color: Colors.grey.shade800,
                          weight: FontWeight.w600),
                      _txt(_uni, size: 4.3, color: Colors.grey.shade500),
                      _section('SKILLS', accentColor),
                      Wrap(
                          children: _skills
                              .take(4)
                              .map((s) => _skillChip(
                                  s,
                                  accentColor.withValues(alpha: 0.12),
                                  accentColor))
                              .toList()),
                      if (_projectLines.isNotEmpty) ...[
                        _section('PROJECTS', accentColor),
                        ...List.generate(
                          _projectLines.take(3).length,
                          (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _txt(_projectLines[index],
                                    size: 4.3,
                                    color: Colors.grey.shade800,
                                    weight: FontWeight.w600,
                                    maxLines: 0),
                                if (index < _projectDetails.length)
                                  _prefixedLines(
                                    _splitLines(
                                      _projectDetails[index],
                                      maxItems: 4,
                                    ),
                                    prefix: 'ΓÇó',
                                    size: 3.8,
                                    color: Colors.grey.shade700,
                                    maxLines: 0,
                                    gap: 1.2,
                                  ),
                                if (resume != null &&
                                    resume!.projects.length > index &&
                                    (resume!.projects[index].url
                                            ?.trim()
                                            .isNotEmpty ??
                                        false))
                                  _txt(
                                    resume!.projects[index].url!.trim(),
                                    size: 3.6,
                                    color: accentColor,
                                    maxLines: 0,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_certificationLines.isNotEmpty) ...[
                        _section('CERTIFICATIONS', accentColor),
                        ..._certificationLines.take(3).map((c) =>
                            _txt(c, size: 4.2, color: Colors.grey.shade600)),
                      ],
                      if (_languageLines.isNotEmpty) ...[
                        _section('LANGUAGES', accentColor),
                        ..._languageLines.take(4).map((l) =>
                            _txt(l, size: 4.2, color: Colors.grey.shade600)),
                      ],
                    ]),
              ),
            ),
          ),
        ]),
      );

  // ΓöÇΓöÇ Classic 2 (pure B&W, uppercase bold name, pill skills) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildClassic2() {
    Widget sectionHeader(String label) => Row(children: [
          Container(
              width: 12,
              height: 2,
              color: accentColor,
              margin: const EdgeInsets.only(right: 6)),
          Flexible(
              child: _txt(label,
                  size: 5.0, color: accentColor, weight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Container(height: 1, color: Colors.grey.shade300)),
        ]);

    final previewExperiences =
        resume?.experience.take(2).toList(growable: false) ?? const [];
    final projectCount = _projectLines.length > 2 ? 2 : _projectLines.length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contactWidth =
              (constraints.maxWidth * 0.34).clamp(92.0, 128.0).toDouble();

          Widget rightContact(String value, double size, Color color) => Align(
                alignment: Alignment.centerRight,
                child: _txt(
                  value,
                  size: size,
                  color: color,
                  center: true,
                  maxLines: 2,
                ),
              );

          return SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt(_name.toUpperCase(),
                              size: 8.5,
                              color: Colors.black,
                              weight: FontWeight.bold),
                          _txt(_title, size: 4.5, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: contactWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          rightContact(_emailOnly, 3.7, Colors.grey.shade600),
                          rightContact(_phone, 3.7, Colors.grey.shade600),
                          rightContact(_address, 3.7, Colors.grey.shade500),
                          if (_linkedin.isNotEmpty)
                            rightContact(_linkedin, 3.5, Colors.grey.shade500),
                          if (_github.isNotEmpty)
                            rightContact(_github, 3.5, Colors.grey.shade500),
                          if (_website.isNotEmpty)
                            rightContact(_website, 3.5, Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(height: 2, color: accentColor),
                const SizedBox(height: 10),
                sectionHeader('PROFESSIONAL SUMMARY'),
                _prefixedLines(
                  _aboutLines.take(5).toList(),
                  prefix: 'Γ£ª',
                  size: 4.0,
                  color: Colors.grey.shade800,
                  maxLines: 0,
                  justify: true,
                ),
                const SizedBox(height: 10),
                sectionHeader('WORK EXPERIENCE'),
                if (previewExperiences.isNotEmpty)
                  ...previewExperiences.map((exp) {
                    final summaryLines = exp.description.isNotEmpty
                        ? _splitLines(exp.description, maxItems: 2)
                        : exp.achievements
                            .map(_cleanPreviewListMarker)
                            .where((item) => item.isNotEmpty)
                            .take(2)
                            .toList();
                    final meta = [
                      exp.company,
                      if ((exp.location ?? '').trim().isNotEmpty)
                        exp.location!.trim(),
                    ].join(' ΓÇó ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt(exp.position,
                              size: 5.0,
                              color: Colors.black,
                              weight: FontWeight.w700),
                          if (meta.isNotEmpty)
                            _txt(meta, size: 4.2, color: Colors.grey.shade500),
                          if (summaryLines.isNotEmpty)
                            _prefixedLines(
                              summaryLines,
                              prefix: '-',
                              size: 3.85,
                              color: Colors.grey.shade700,
                              maxLines: 0,
                              justify: true,
                            ),
                        ],
                      ),
                    );
                  })
                else ...[
                  _txt(_job1,
                      size: 5.0, color: Colors.black, weight: FontWeight.w700),
                  _txt(_co1, size: 4.2, color: Colors.grey.shade500),
                  _prefixedLines(
                    _splitLines(_desc1, maxItems: 2),
                    prefix: '-',
                    size: 3.85,
                    color: Colors.grey.shade700,
                    maxLines: 0,
                    justify: true,
                  ),
                ],
                const SizedBox(height: 10),
                sectionHeader('EDUCATION'),
                _txt(_edu,
                    size: 5.0, color: Colors.black, weight: FontWeight.w700),
                _txt(_uni, size: 4.2, color: Colors.grey.shade500),
                const SizedBox(height: 10),
                sectionHeader('SKILLS'),
                Wrap(
                    children: _skills
                        .map((s) => _skillChip(
                              s,
                              const Color(0xFFF4F5FB),
                              accentColor.withValues(alpha: 0.95),
                            ))
                        .toList()),
                if (_projectLines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  sectionHeader('PROJECTS'),
                  for (var index = 0; index < projectCount; index++) ...[
                    _txt(_projectLines[index],
                        size: 4.2,
                        color: Colors.black,
                        weight: FontWeight.w600,
                        maxLines: 2),
                    if (_projectUrlAt(index).isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: _txt(_projectUrlAt(index),
                            size: 3.5,
                            color: Colors.grey.shade500,
                            center: true,
                            maxLines: 2),
                      ),
                    if (index < _projectDetails.length)
                      _prefixedLines(
                        _splitProjectLines(_projectDetails[index], maxItems: 2),
                        prefix: '-',
                        size: 3.8,
                        color: Colors.grey.shade700,
                        maxLines: 0,
                        justify: true,
                      ),
                  ],
                ],
                if (_certificationLines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  sectionHeader('CERTIFICATIONS'),
                  ..._certificationLines.take(3).map(
                      (c) => _txt(c, size: 4.2, color: Colors.grey.shade700)),
                ],
                if (_languageLines.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  sectionHeader('LANGUAGES'),
                  ..._languageLines.take(4).map(
                      (l) => _txt(l, size: 4.2, color: Colors.grey.shade700)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ΓöÇΓöÇ Prof. Accountant ΓÇö split body: left=experience, right=skills ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildCoolBlue() => VividProResumeTemplatePreview(
        accentColor: accentColor,
        resume: resume,
      );

  // ΓöÇΓöÇ Multicolor (vibrant, creative design) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Widget _buildMulticolor() => MulticolorResumeTemplatePreview(
        accentColor: accentColor,
        resume: resume,
      );

  Widget _buildModernEdge(
    Color accentColor,
    Color? templateColor,
    ResumeModel? resume,
  ) =>
      ModernEdgeResumeTemplatePreview(
        accentColor: accentColor,
        templateColor: templateColor,
        resume: resume,
      );
}