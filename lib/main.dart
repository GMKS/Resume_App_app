import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
// Add qr_flutter to your pubspec.yaml

void main() => runApp(const ResumeApp());

// Models
class SavedResume {
  final String id;
  String title, template;
  Map<String, String> data;
  List<CompanyApplication> applications;
  DateTime createdAt, updatedAt;

  SavedResume({
    required this.id,
    required this.title,
    required this.template,
    required this.data,
    required this.applications,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'template': template,
    'data': data,
    'applications': applications.map((app) => app.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedResume.fromJson(Map<String, dynamic> json) => SavedResume(
    id: json['id'],
    title: json['title'],
    template: json['template'],
    data: Map<String, String>.from(json['data']),
    applications: (json['applications'] as List)
        .map((app) => CompanyApplication.fromJson(app))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

class CompanyApplication {
  final String id;
  String companyName, position, status, notes;
  DateTime appliedDate;

  CompanyApplication({
    required this.id,
    required this.companyName,
    required this.position,
    required this.appliedDate,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'companyName': companyName,
    'position': position,
    'appliedDate': appliedDate.toIso8601String(),
    'status': status,
    'notes': notes,
  };

  factory CompanyApplication.fromJson(Map<String, dynamic> json) =>
      CompanyApplication(
        id: json['id'],
        companyName: json['companyName'],
        position: json['position'],
        appliedDate: DateTime.parse(json['appliedDate']),
        status: json['status'],
        notes: json['notes'],
      );
}

class WorkExperience {
  final String company, position, startDate, endDate, description;
  WorkExperience({
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.description,
  });
  String toJson() => '$company|$position|$startDate|$endDate|$description';
  static WorkExperience fromJson(String json) {
    final parts = json.split('|');
    return WorkExperience(
      company: parts[0],
      position: parts[1],
      startDate: parts[2],
      endDate: parts[3],
      description: parts[4],
    );
  }
}

class Education {
  final String degree, institution, year;
  Education({
    required this.degree,
    required this.institution,
    required this.year,
  });
  String toJson() => '$degree|$institution|$year';
  static Education fromJson(String json) {
    final parts = json.split('|');
    return Education(degree: parts[0], institution: parts[1], year: parts[2]);
  }
}

// Services
class ResumeStorageService {
  static const String _resumesKey = 'saved_resumes';

  static Future<List<SavedResume>> getResumes() async {
    final prefs = await SharedPreferences.getInstance();
    final resumesJson = prefs.getStringList(_resumesKey) ?? [];
    return resumesJson
        .map((json) => SavedResume.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> saveResume(SavedResume resume) async {
    final prefs = await SharedPreferences.getInstance();
    final resumes = await getResumes();
    final index = resumes.indexWhere((r) => r.id == resume.id);
    if (index >= 0) {
      resumes[index] = resume;
    } else {
      resumes.add(resume);
    }
    await prefs.setStringList(
      _resumesKey,
      resumes.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static Future<void> deleteResume(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final resumes = await getResumes();
    resumes.removeWhere((r) => r.id == id);
    await prefs.setStringList(
      _resumesKey,
      resumes.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}

class OtpService {
  static final Map<String, String> _otps = {};
  static String sendOtp(String user) {
    final otp = (100000 + Random().nextInt(900000)).toString();
    _otps[user] = otp;
    return otp;
  }

  static bool verifyOtp(String user, String otp) => _otps[user] == otp;
  static void clearOtp(String user) => _otps.remove(user);
}

// Widgets
class ResumeApp extends StatelessWidget {
  const ResumeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Resume Builder',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: const SignupScreen(),
    debugShowCheckedModeBanner: false,
  );
}

// Add this CustomClipper for the wavy header
class TopWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.5, size.height,
      size.width, size.height * 0.75,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// --- SIGN IN SCREEN REDESIGN ---
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLogin = true, _isForgot = false, _otpSent = false;
  String? _error;

  void _handleAuth() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    final user = _userController.text.trim();
    final pass = _passwordController.text.trim();
    final otp = _otpController.text.trim();

    if (_otpSent) {
      if (otp.isEmpty) return setState(() => _error = 'Enter OTP');
      if (OtpService.verifyOtp(user, otp)) {
        OtpService.clearOtp(user);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainAppScreen()),
        );
      } else {
        setState(() => _error = 'Invalid OTP');
      }
      return;
    }

    if (_isForgot) {
      if (user.isEmpty) return setState(() => _error = 'Enter email or mobile');
      final sentOtp = OtpService.sendOtp(user);
      setState(() {
        _otpSent = true;
        _error = 'OTP sent: $sentOtp (for demo)';
      });
      return;
    }

    if (user.isEmpty || pass.isEmpty) {
      return setState(() => _error = 'Fill all fields');
    }
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainAppScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFE3F0FF); // light blue
    final accent = const Color(0xFF4A90E2); // blue accent
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Top wavy header
          SizedBox(
            height: 260,
            width: double.infinity,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                color: accent,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60, left: 32),
                    child: Text(
                      _isLogin ? "Welcome" : "Sign Up",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 32,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                _isLogin ? 'Sign in' : 'Sign up',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _userController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email, color: accent),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: bgColor,
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Enter email'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              if (!_isForgot && !_otpSent)
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: Icon(Icons.lock, color: accent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: bgColor,
                                  ),
                                  obscureText: true,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Enter password'
                                      : null,
                                ),
                              if (_otpSent)
                                TextFormField(
                                  controller: _otpController,
                                  decoration: InputDecoration(
                                    labelText: 'Enter OTP',
                                    prefixIcon: Icon(Icons.verified, color: accent),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: bgColor,
                                  ),
                                ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  if (!_isForgot && !_otpSent)
                                    Checkbox(
                                      value: true,
                                      onChanged: (_) {},
                                      activeColor: accent,
                                    ),
                                  if (!_isForgot && !_otpSent)
                                    const Text("Remember Me"),
                                  const Spacer(),
                                  if (_isLogin && !_otpSent)
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _isForgot = !_isForgot;
                                        _otpSent = false;
                                        _error = null;
                                      }),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(color: accent),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _otpSent
                                      ? 'Verify OTP'
                                      : _isForgot
                                          ? 'Send OTP'
                                          : (_isLogin ? 'Login' : 'Sign Up'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => setState(() {
                                  _isLogin = !_isLogin;
                                  _isForgot = false;
                                  _otpSent = false;
                                  _error = null;
                                }),
                                child: Text(
                                  _isLogin
                                      ? "Don't have an Account? Sign up"
                                      : "Already have an Account? Sign in",
                                  style: TextStyle(color: accent),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HOME SCREEN REDESIGN ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFFE3F0FF); // light blue
    final accent = const Color(0xFF4A90E2); // blue accent
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: accent),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Top wavy header
          SizedBox(
            height: 220,
            width: double.infinity,
            child: ClipPath(
              clipper: TopWaveClipper(),
              child: Container(
                color: accent,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 48, left: 32),
                    child: Text(
                      "Welcome",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 140),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: accent.withOpacity(0.15),
                      child: Icon(Icons.description, color: accent),
                    ),
                    title: const Text(
                      'Create New Resume',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Pick a template and start editing'),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: accent,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResumeTemplateSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.15),
                      child: const Icon(Icons.folder, color: Colors.teal),
                    ),
                    title: const Text(
                      'View Saved Resumes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('Access your saved resumes'),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedResumesScreen()),
                      );
                    },
                  ),
                ),
                const Spacer(),
                freePlanBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Add this widget where you want to show the plan info
  Widget freePlanBanner() => Card(
    color: Colors.yellow.shade50,
    margin: const EdgeInsets.symmetric(vertical: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Free Plan Features',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          SizedBox(height: 8),
          Text('• Save up to 5 resumes in the cloud'),
          Text('• Export in PDF (Classic only)'),
          Text('• Share via Email (Classic only)'),
          Text('• Classic & limited Modern templates'),
        ],
      ),
    ),
  );
}

class ResumeTemplateSelectionScreen extends StatefulWidget {
  const ResumeTemplateSelectionScreen({super.key});
  @override
  State<ResumeTemplateSelectionScreen> createState() =>
      _ResumeTemplateSelectionScreenState();
}

class _ResumeTemplateSelectionScreenState
    extends State<ResumeTemplateSelectionScreen> {
  int selected = 0;
  final List<Map<String, dynamic>> templates = [
    {
      'title': 'Classic',
      'icon': Icons.description,
      'desc': 'Simple, professional, clean.',
    },
    {
      'title': 'Modern',
      'icon': Icons.auto_awesome,
      'desc': 'Stylish, bold headings, color.',
    },
    {
      'title': 'Minimal',
      'icon': Icons.minimize,
      'desc': 'Minimalist, lots of whitespace.',
    },
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // If only one route in stack, go to HomeScreen instead of popping to black
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainAppScreen()),
            );
          }
        },
      ),
      title: const Text('Choose resume template'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Awesome! Let\'s get started! What type of resume template do you want?',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = selected == index;
              return GestureDetector(
                onTap: () => setState(() => selected = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected ? Colors.purple : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        template['icon'],
                        color: isSelected ? Colors.purple : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template['title'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.purple
                                    : Colors.black,
                              ),
                            ),
                            Text(
                              template['desc'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<int>(
                        value: index,
                        groupValue: selected,
                        onChanged: (value) => setState(() => selected = value!),
                        activeColor: Colors.purple,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    Widget targetScreen;
                    switch (selected) {
                      case 0:
                        targetScreen = const ClassicResumeFormScreen();
                        break;
                      case 1:
                        targetScreen = const ModernResumeFormScreen();
                        break;
                      case 2:
                        targetScreen = MinimalResumeFormScreen();
                        break;
                      default:
                        targetScreen = const ClassicResumeFormScreen();
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => targetScreen),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SavedResumesScreen extends StatefulWidget {
  const SavedResumesScreen({super.key});
  @override
  State<SavedResumesScreen> createState() => _SavedResumesScreenState();
}

class _SavedResumesScreenState extends State<SavedResumesScreen> {
  List<SavedResume> _resumes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    final resumes = await ResumeStorageService.getResumes();
    setState(() {
      _resumes = resumes;
      _loading = false;
    });
  }

  void _editResume(SavedResume resume) {
    Widget targetScreen;
    switch (resume.template.toLowerCase()) {
      case 'classic':
        targetScreen = ClassicResumeFormScreen(existingResume: resume);
        break;
      case 'modern':
        targetScreen = ModernResumeFormScreen(existingResume: resume);
        break;
      case 'minimal':
        targetScreen = MinimalResumeFormScreen(existingResume: resume);
        break;
      default:
        targetScreen = ClassicResumeFormScreen(existingResume: resume);
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    ).then((_) => _loadResumes());
  }

  void _duplicateResume(SavedResume resume) async {
    final newResume = SavedResume(
      id: ResumeStorageService.generateId(),
      title: '${resume.title} (Copy)',
      template: resume.template,
      data: Map<String, String>.from(resume.data),
      applications: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ResumeStorageService.saveResume(newResume);
    _loadResumes();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume duplicated successfully')),
    );
  }

  void _confirmDelete(SavedResume resume) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Resume'),
        content: Text('Are you sure you want to delete "${resume.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ResumeStorageService.deleteResume(resume.id);
              _loadResumes();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Navigator.of(context).canPop()
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      title: const Text('Saved Resumes'),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadResumes),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _resumes.isEmpty
        ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No saved resumes yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    )
        : ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _resumes.length,
      itemBuilder: (context, index) {
        final resume = _resumes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTemplateColor(resume.template),
              child: Text(
                resume.template[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              resume.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Template: ${resume.template}\nApplications: ${resume.applications.length}',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Text('Duplicate'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editResume(resume);
                    break;
                  case 'duplicate':
                    _duplicateResume(resume);
                    break;
                  case 'delete':
                    _confirmDelete(resume);
                    break;
                }
              },
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ResumeDetailsScreen(resume: resume),
              ),
            ).then((_) => _loadResumes()),
          ),
        );
      },
    );

  Color _getTemplateColor(String template) {
    switch (template.toLowerCase()) {
      case 'classic':
        return Colors.blue;
      case 'modern':
        return Colors.purple;
      case 'minimal':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }
}

class ResumeDetailsScreen extends StatelessWidget {
  final SavedResume resume;
  const ResumeDetailsScreen({super.key, required this.resume});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(resume.title)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Template: ${resume.template}'),
                Text('Applications: ${resume.applications.length}'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// Base Form Widget for reusability
class BaseResumeForm extends StatefulWidget {
  final SavedResume? existingResume;
  final String template;
  final Widget child;

  const BaseResumeForm({
    super.key,
    required this.existingResume,
    required this.template,
    required this.child,
  });

  @override
  State<BaseResumeForm> createState() => _BaseResumeFormState();
}

class _BaseResumeFormState extends State<BaseResumeForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = {
      'name': TextEditingController(),
      'email': TextEditingController(),
      'phone': TextEditingController(),
      'summary': TextEditingController(),
      'skills': TextEditingController(),
      'experience': TextEditingController(),
      'education': TextEditingController(),
    };
    if (widget.existingResume != null) _loadData();
  }

  void _loadData() {
    controllers.forEach((key, controller) {
      controller.text = widget.existingResume!.data[key] ?? '';
    });
  }

  Future<void> saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    final data = controllers.map(
      (key, controller) => MapEntry(key, controller.text),
    );
    final title = controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${controllers['name']!.text} Resume';

    final resume = SavedResume(
      id: widget.existingResume?.id ?? ResumeStorageService.generateId(),
      title: widget.existingResume?.title ?? title,
      template: widget.template,
      data: data,
      applications: widget.existingResume?.applications ?? [],
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ResumeStorageService.saveResume(resume);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.template} Resume saved successfully!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controllers[key],
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => v?.isEmpty == true ? '$label is required' : null
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) =>
      Form(key: _formKey, child: widget.child);
}

class ClassicResumeFormScreen extends StatefulWidget {
  final SavedResume? existingResume;
  const ClassicResumeFormScreen({super.key, this.existingResume});

  @override
  State<ClassicResumeFormScreen> createState() =>
      _ClassicResumeFormScreenState();
}

class _ClassicResumeFormScreenState extends State<ClassicResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'summary': TextEditingController(),
    'skills': TextEditingController(),
    'certifications': TextEditingController(),
    'education': TextEditingController(),
    'company': TextEditingController(),
    'position': TextEditingController(),
    'workDesc': TextEditingController(),
  };

  DateTime? _workStart, _workEnd;
  final List<String> _skillsList = [
    'Java',
    'Core Java',
    'Java Full Stack',
    'JavaScript',
    'Python',
    'C++',
    'C#',
    'SQL',
    'HTML',
    'CSS',
    'Dart',
    'Flutter',
    'React',
    'Angular',
    'Spring Boot',
  ];
  List<String> _filteredSkills = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingResume != null) {
      final data = widget.existingResume!.data;
      _controllers.forEach((k, c) => c.text = data[k] ?? '');
      if (data['workStart'] != null) {
        _workStart = DateTime.tryParse(data['workStart']!);
      }
      if (data['workEnd'] != null) {
        _workEnd = DateTime.tryParse(data['workEnd']!);
      }
    }
    _controllers['skills']!.addListener(_onSkillChanged);
  }

  void _onSkillChanged() {
    final input = _controllers['skills']!.text.toLowerCase();
    setState(() {
      _filteredSkills = input.isEmpty
          ? []
          : _skillsList
                .where((s) => s.toLowerCase().startsWith(input))
                .toList();
    });
  }

  void _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_workStart ?? DateTime.now())
        : (_workEnd ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _workStart = picked;
        } else {
          _workEnd = picked;
        }
      });
    }
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _controllers.map((k, c) => MapEntry(k, c.text));
    if (_workStart != null) data['workStart'] = _workStart!.toIso8601String();
    if (_workEnd != null) data['workEnd'] = _workEnd!.toIso8601String();
    final title = _controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${_controllers['name']!.text} Resume';
    final resume = SavedResume(
      id: widget.existingResume?.id ?? ResumeStorageService.generateId(),
      title: widget.existingResume?.title ?? title,
      template: 'Classic',
      data: data,
      applications: widget.existingResume?.applications ?? [],
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ResumeStorageService.saveResume(resume);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resume saved!')));
      Navigator.pop(context);
    }
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        fontFamily: 'Calibri',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Classic Resume',
          style: TextStyle(fontFamily: 'Times New Roman', color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _sectionTitle('Contact Info'),
            _buildField('name', 'Full Name', required: true),
            _buildField(
              'email',
              'Email',
              required: true,
              keyboard: TextInputType.emailAddress,
            ),
            _buildField('phone', 'Phone', keyboard: TextInputType.phone),

            _sectionTitle('Summary'),
            _buildField('summary', 'Professional Summary', maxLines: 3),

            _sectionTitle('Skills'),
            Stack(
              children: [
                _buildField(
                  'skills',
                  'Type to search/add skills (e.g. Ja...)',
                  onChanged: (_) => _onSkillChanged(),
                ),
                if (_filteredSkills.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 56,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListView(
                        shrinkWrap: true,
                        children: _filteredSkills
                            .map(
                              (skill) => ListTile(
                                title: Text(
                                  skill,
                                  style: const TextStyle(fontFamily: 'Arial'),
                                ),
                                onTap: () {
                                  _controllers['skills']!.text = skill;
                                  setState(() => _filteredSkills.clear());
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
              ],
            ),

            _sectionTitle('Work Experience'),
            _buildField('company', 'Company Name'),
            _buildField('position', 'Position'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _workStart == null
                            ? ''
                            : "${_workStart!.year}-${_workStart!.month.toString().padLeft(2, '0')}-${_workStart!.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontFamily: 'Arial'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Date',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _workEnd == null
                            ? ''
                            : "${_workEnd!.year}-${_workEnd!.month.toString().padLeft(2, '0')}-${_workEnd!.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontFamily: 'Arial'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildField('workDesc', 'Description', maxLines: 2),

            _sectionTitle('Education'),
            _buildField('education', 'Education Details', maxLines: 2),

            _sectionTitle('Certifications'),
            _buildField('certifications', 'Certifications', maxLines: 2),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveResume,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Arial',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Save Resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    void Function(String)? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _controllers[key],
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(fontFamily: 'Arial', fontSize: 16),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? '$label is required' : null
            : null,
        onChanged: onChanged,
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class ModernResumeFormScreen extends StatefulWidget {
  final SavedResume? existingResume;
  const ModernResumeFormScreen({super.key, this.existingResume});

  @override
  State<ModernResumeFormScreen> createState() => _ModernResumeFormScreenState();
}

class _ModernResumeFormScreenState extends State<ModernResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'summary': TextEditingController(),
    'linkedin': TextEditingController(),
    'github': TextEditingController(),
    'portfolio': TextEditingController(),
    'certifications': TextEditingController(),
    'achievements': TextEditingController(),
    'hobbies': TextEditingController(),
  };

  // Profile picture
  ImageProvider? _profileImage;

  // Skills
  final List<String> _allSkills = [
    'Flutter',
    'Dart',
    'JavaScript',
    'Python',
    'UI/UX',
    'React',
    'Figma',
    'Java',
    'C++',
    'SQL',
  ];
  final Map<String, double> _skillRatings = {};

  // Work/Education Timeline
  final List<Map<String, dynamic>> _workTimeline = [];
  final List<Map<String, dynamic>> _eduTimeline = [];

  // For adding new work/edu
  final _workCompany = TextEditingController();
  final _workRole = TextEditingController();
  DateTime? _workStart, _workEnd;

  final _eduSchool = TextEditingController();
  final _eduDegree = TextEditingController();
  DateTime? _eduStart, _eduEnd;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _workCompany.dispose();
    _workRole.dispose();
    _eduSchool.dispose();
    _eduDegree.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    // For demo: use a placeholder, or use image_picker for real app
    setState(() {
      _profileImage = const AssetImage('assets/profile_placeholder.png');
    });
  }

  void _addWork() {
    if (_workCompany.text.isEmpty ||
        _workRole.text.isEmpty ||
        _workStart == null) {
      return;
    }
    setState(() {
      _workTimeline.add({
        'company': _workCompany.text,
        'role': _workRole.text,
        'start': _workStart,
        'end': _workEnd,
      });
      _workCompany.clear();
      _workRole.clear();
      _workStart = null;
      _workEnd = null;
    });
  }

  void _addEdu() {
    if (_eduSchool.text.isEmpty ||
        _eduDegree.text.isEmpty ||
        _eduStart == null) {
      return;
    }
    setState(() {
      _eduTimeline.add({
        'school': _eduSchool.text,
        'degree': _eduDegree.text,
        'start': _eduStart,
        'end': _eduEnd,
      });
      _eduSchool.clear();
      _eduDegree.clear();
      _eduStart = null;
      _eduEnd = null;
    });
  }

  Future<void> _pickDate(
    BuildContext context,
    ValueChanged<DateTime> onPicked, {
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _saveResume() async {
    if (!_formKey.currentState!.validate()) return;
    final data = _controllers.map((k, c) => MapEntry(k, c.text));
    data['skills'] = _skillRatings.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    data['workTimeline'] = jsonEncode(
      _workTimeline
          .map(
            (e) => {
              'company': e['company'],
              'role': e['role'],
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
    );
    data['eduTimeline'] = jsonEncode(
      _eduTimeline
          .map(
            (e) => {
              'school': e['school'],
              'degree': e['degree'],
              'start': (e['start'] as DateTime?)?.toIso8601String(),
              'end': (e['end'] as DateTime?)?.toIso8601String(),
            },
          )
          .toList(),
    );
    final title = _controllers['name']!.text.isEmpty
        ? 'My Resume'
        : '${_controllers['name']!.text} Resume';
    final resume = SavedResume(
      id: widget.existingResume?.id ?? ResumeStorageService.generateId(),
      title: widget.existingResume?.title ?? title,
      template: 'Modern',
      data: data,
      applications: widget.existingResume?.applications ?? [],
      createdAt: widget.existingResume?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ResumeStorageService.saveResume(resume);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Modern Resume saved!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.purple;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Resume'),
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Profile + Contact
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: accent.withOpacity(0.2),
                          backgroundImage: _profileImage,
                          child: _profileImage == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 32,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _modernContactRow(
                              Icons.person,
                              _controllers['name']!,
                              'Full Name',
                            ),
                            _modernContactRow(
                              Icons.email,
                              _controllers['email']!,
                              'Email',
                            ),
                            _modernContactRow(
                              Icons.phone,
                              _controllers['phone']!,
                              'Phone',
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.linked_camera,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'LinkedIn',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.code,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'GitHub',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.web,
                                    color: Colors.teal,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'Portfolio',
                                ),
                                // if (_controllers['linkedin']!.text.isNotEmpty)
                                //   QrImage(
                                //     data: _controllers['linkedin']!.text,
                                //     size: 32,
                                //     backgroundColor: Colors.white,
                                //   ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Stylish Summary
              Card(
                color: accent.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.purple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _controllers['summary'],
                          maxLines: 3,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Summary',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Skills
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Skills',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allSkills.map((skill) {
                          final selected = _skillRatings.containsKey(skill);
                          return FilterChip(
                            label: Text(skill),
                            selected: selected,
                            selectedColor: accent.withOpacity(0.2),
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _skillRatings[skill] = 3;
                                } else {
                                  _skillRatings.remove(skill);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_skillRatings.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ..._skillRatings.entries.map(
                          (e) => Row(
                            children: [
                              Text(
                                e.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: e.value,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  label: '${e.value.round()}',
                                  onChanged: (v) =>
                                      setState(() => _skillRatings[e.key] = v),
                                  activeColor: accent,
                                ),
                              ),
                              Text('⭐' * e.value.round()),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Work Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🏢', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Work Experience',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._workTimeline.map(
                        (w) => _timelineTile(
                          title: w['role'],
                          subtitle: w['company'],
                          start: w['start'],
                          end: w['end'],
                          color: accent,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _workCompany,
                              decoration: const InputDecoration(
                                labelText: 'Company',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _workRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _workStart == null
                                    ? 'Start Date'
                                    : "${_workStart!.year}-${_workStart!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _workStart = d),
                                initial: _workStart,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _workEnd == null
                                    ? 'End Date'
                                    : "${_workEnd!.year}-${_workEnd!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _workEnd = d),
                                initial: _workEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          onPressed: _addWork,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Education Timeline
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🎓', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'Education',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._eduTimeline.map(
                        (e) => _timelineTile(
                          title: e['degree'],
                          subtitle: e['school'],
                          start: e['start'],
                          end: e['end'],
                          color: Colors.teal,
                        ),
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _eduSchool,
                              decoration: const InputDecoration(
                                labelText: 'School/College',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _eduDegree,
                              decoration: const InputDecoration(
                                labelText: 'Degree',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _eduStart == null
                                    ? 'Start Date'
                                    : "${_eduStart!.year}-${_eduStart!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _eduStart = d),
                                initial: _eduStart,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _eduEnd == null
                                    ? 'End Date'
                                    : "${_eduEnd!.year}-${_eduEnd!.month.toString().padLeft(2, '0')}",
                              ),
                              onPressed: () => _pickDate(
                                context,
                                (d) => setState(() => _eduEnd = d),
                                initial: _eduEnd,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                          ),
                          onPressed: _addEdu,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Certifications
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Certifications',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _controllers['certifications']!.text
                            .split(',')
                            .where((c) => c.trim().isNotEmpty)
                            .map(
                              (c) => Chip(
                                label: Text(c.trim()),
                                avatar: const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                backgroundColor: Colors.blue.shade50,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Achievements & Hobbies
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.orange,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Achievements & Hobbies',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _controllers['achievements'],
                        decoration: const InputDecoration(
                          labelText: 'Achievements (comma separated)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _controllers['hobbies'],
                        decoration: const InputDecoration(
                          labelText: 'Hobbies (comma separated)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ..._controllers['achievements']!.text
                              .split(',')
                              .where((a) => a.trim().isNotEmpty)
                              .map(
                                (a) => Chip(
                                  label: Text(a.trim()),
                                  avatar: const Icon(
                                    Icons.emoji_events,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.orange.shade50,
                                ),
                              ),
                          ..._controllers['hobbies']!.text
                              .split(',')
                              .where((h) => h.trim().isNotEmpty)
                              .map(
                                (h) => Chip(
                                  label: Text(h.trim()),
                                  avatar: const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  backgroundColor: Colors.green.shade50,
                                ),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Modern Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _saveResume,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modernContactRow(
    IconData icon,
    TextEditingController controller,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.purple, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: label,
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _timelineTile({
    required String title,
    required String subtitle,
    required DateTime? start,
    required DateTime? end,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 40, color: color.withOpacity(0.4)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(subtitle, style: const TextStyle(color: Colors.black87)),
                Text(
                  '${start != null ? "${start.year}-${start.month.toString().padLeft(2, '0')}" : ''}'
                  ' - '
                  '${end != null ? "${end.year}-${end.month.toString().padLeft(2, '0')}" : 'Present'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MinimalResumeFormScreen extends StatelessWidget {
  final SavedResume? existingResume;
  const MinimalResumeFormScreen({super.key, this.existingResume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minimal Resume')),
      body: Center(
        child: Text(
          'Minimal Resume Form Coming Soon!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
