import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/reminder_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

final ValueNotifier<bool> loggedInNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<void> _init() async {
    await ReminderService.instance.init();
    // Force logout EVERY cold start:
    await AuthService.instance.init(alwaysFresh: true);
    loggedInNotifier.value = false; // always show login first
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: FutureBuilder(
        future: _init(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ValueListenableBuilder<bool>(
            valueListenable: loggedInNotifier,
            builder: (_, loggedIn, __) =>
                loggedIn ? const HomeShell() : const LoginScreen(),
          );
        },
      ),
    );
  }
}
