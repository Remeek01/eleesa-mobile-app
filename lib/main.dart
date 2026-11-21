import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'theme/theme_controller.dart';

void main() {
  runApp(const EleesaApp());
}

class EleesaApp extends StatelessWidget {
  const EleesaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: eleesaTheme,
      builder: (context, _) {
        return MaterialApp(
          title: 'ELEESA Hub',
          debugShowCheckedModeBanner: false,
          theme: eleesaTheme.buildThemeData(),
          home: const LoginScreen(),
        );
      },
    );
  }
}