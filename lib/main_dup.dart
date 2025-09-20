import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const ResumeApp());
}

// ---------------- Models ----------------
class SavedResume {
  final String id, title, template;
  final Map<String, dynamic> data;
  final DateTime createdAt, updatedAt;

  SavedResume({
    required this.id,
    required this.title,
    required this.template,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'template': template,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SavedResume.fromJson(Map<String, dynamic> j) => SavedResume(
    id: j['id'],
    title: j['title'],
    template: j['template'],
    data: Map<String, dynamic>.from(j['data']),
    createdAt: DateTime.parse(j['createdAt']),
    updatedAt: DateTime.parse(j['updatedAt']),
  );
}

// ---------------- Services ----------------
class ResumeStorageService {
  static const _key = 'saved_resumes';

  static Future<List<SavedResume>> getResumes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? [])
        .map((e) => SavedResume.fromJson(jsonDecode(e)))
        .toList();
  }

  static Future<void> saveResume(SavedResume r) async {
    final prefs = await SharedPreferences.getInstance();
    final resumes = await getResumes();
    resumes.removeWhere((e) => e.id == r.id);
    resumes.add(r);
    await prefs.setStringList(
      _key,
      resumes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static Future<void> deleteResume(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final resumes = await getResumes();
    resumes.removeWhere((e) => e.id == id);
    await prefs.setStringList(
      _key,
      resumes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();
}

// ---------------- Premium ----------------
bool isPremiumUser = false;
Future<void> checkSubscriptionStatus() async =>
    isPremiumUser = await InAppPurchase.instance.isAvailable();
void showPremiumMessage(BuildContext c) => ScaffoldMessenger.of(c).showSnackBar(
  const SnackBar(content: Text('Upgrade to premium for unlimited resumes!')),
);

// ---------------- Ads ----------------
final BannerAd myBannerAd = BannerAd(
  size: AdSize.banner,
  adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit ID
  listener: BannerAdListener(),
  request: const AdRequest(),
)..load();

Widget buildAdBanner() => isPremiumUser
    ? const SizedBox.shrink()
    : SizedBox(height: 50, child: AdWidget(ad: myBannerAd));

// ---------------- UI ----------------
class ResumeApp extends StatelessWidget {
  const ResumeApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'Resume Builder',
    theme: ThemeData(primarySwatch: Colors.purple),
    debugShowCheckedModeBanner: false,
    home: const HomeScreen(),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Resume Builder')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(
                builder: (_) => const ResumeTemplateSelectionScreen(),
              ),
            ),
            child: const Text("Create Resume"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => const SavedResumesScreen()),
            ),
            child: const Text("View Saved Resumes"),
          ),
          buildAdBanner(),
        ],
      ),
    ),
  );
}

// ---------------- Template Selection ----------------
class ResumeTemplateSelectionScreen extends StatefulWidget {
  const ResumeTemplateSelectionScreen({super.key});
  @override
  State<ResumeTemplateSelectionScreen> createState() =>
      _ResumeTemplateSelectionScreenState();
}

class _ResumeTemplateSelectionScreenState
    extends State<ResumeTemplateSelectionScreen> {
  int selected = 0;
  final templates = [
    {'title': 'Classic', 'desc': 'Simple, clean, professional'},
    {'title': 'Modern', 'desc': 'Stylish, bold, colorful'},
    {'title': 'Minimal', 'desc': 'Whitespace, concise'},
  ];

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text("Choose Template")),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: templates.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(templates[i]['title']!),
              subtitle: Text(templates[i]['desc']!),
              leading: Radio<int>(
                value: i,
                groupValue: selected,
                onChanged: (v) => setState(() => selected = v!),
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final forms = [
              const ClassicResumeForm(),
              const ModernResumeForm(),
              const MinimalResumeForm(),
            ];
            Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => forms[selected]),
            );
          },
          child: const Text("Next"),
        ),
      ],
    ),
  );
}

// ---------------- Base Form ----------------
class BaseResumeForm extends StatefulWidget {
  final String template;
  const BaseResumeForm({super.key, required this.template});
  @override
  State<BaseResumeForm> createState() => _BaseResumeFormState();
}

class _BaseResumeFormState extends State<BaseResumeForm> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'summary': TextEditingController(),
    'skills': TextEditingController(),
  };

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final resume = SavedResume(
      id: ResumeStorageService.generateId(),
      title: "${_controllers['name']!.text} Resume",
      template: widget.template,
      data: _controllers.map((k, v) => MapEntry(k, v.text)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ResumeStorageService.saveResume(resume);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text("${widget.template} Resume")),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (var e in _controllers.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: e.value,
                decoration: InputDecoration(labelText: e.key),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
            ),
          ElevatedButton(onPressed: _save, child: const Text("Save Resume")),
        ],
      ),
    ),
  );
}

// ---------------- Template Forms ----------------
class ClassicResumeForm extends StatelessWidget {
  const ClassicResumeForm({super.key});
  @override
  Widget build(BuildContext c) => const BaseResumeForm(template: "Classic");
}

class ModernResumeForm extends StatelessWidget {
  const ModernResumeForm({super.key});
  @override
  Widget build(BuildContext c) => const BaseResumeForm(template: "Modern");
}

class MinimalResumeForm extends StatelessWidget {
  const MinimalResumeForm({super.key});
  @override
  Widget build(BuildContext c) => const BaseResumeForm(template: "Minimal");
}

// ---------------- Saved Resumes ----------------
class SavedResumesScreen extends StatelessWidget {
  const SavedResumesScreen({super.key});
  @override
  Widget build(BuildContext c) => FutureBuilder(
    future: ResumeStorageService.getResumes(),
    builder: (_, s) {
      if (!s.hasData) return const Center(child: CircularProgressIndicator());
      final resumes = s.data! as List<SavedResume>;
      if (resumes.isEmpty) return const Center(child: Text("No saved resumes"));
      return ListView.builder(
        itemCount: resumes.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(resumes[i].title),
          subtitle: Text("Template: ${resumes[i].template}"),
          onTap: () => Navigator.push(
            c,
            MaterialPageRoute(
              builder: (_) => ResumeDetails(resume: resumes[i]),
            ),
          ),
        ),
      );
    },
  );
}

class ResumeDetails extends StatelessWidget {
  final SavedResume resume;
  const ResumeDetails({super.key, required this.resume});
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text(resume.title)),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Text("Data: ${resume.data}"),
    ),
  );
}

// ---------------- AI Resume Tips ----------------
Future<String> getResumeTips(String content) async {
  final res = await http.post(
    Uri.parse("https://api.openai.com/v1/chat/completions"),
    headers: {'Authorization': 'Bearer YOUR_API_KEY'},
    body: jsonEncode({
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'user', 'content': 'Provide tips: $content'},
      ],
      'max_tokens': 100,
    }),
  );
  return jsonDecode(res.body)['choices'][0]['message']['content'];
}
