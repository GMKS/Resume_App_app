// filepath: c:\Users\SIS4\Downloads\Resume_App_app\lib\widgets\app_back_wrapper.dart
import 'package:flutter/material.dart';

class AppBackWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  const AppBackWrapper({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(title ?? ''),
      ),
      body: child,
    );
  }
}
