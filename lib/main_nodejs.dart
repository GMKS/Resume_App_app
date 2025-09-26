import 'package:flutter/material.dart';
import 'screens/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ResumeBuilderApp());
}

class ResumeBuilderApp extends StatelessWidget {
  const ResumeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AppInitializer(),
    );
  }
}
