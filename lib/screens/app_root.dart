import 'package:flutter/material.dart';
import 'signup_screen.dart';

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
