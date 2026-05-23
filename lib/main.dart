import 'package:flutter/material.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'pre_admission_test.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'LearnMatch Teacher Portal',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58),
        ),
        useMaterial3: true,
      ),

      // 保持 login page 为入口
      initialRoute: '/',

      routes: {

        // Login Page
        '/': (context) => const LoginPage(),

        // Teacher Dashboard
        '/home': (context) => const HomePage(),

        // Student Test Page
        '/pre-admission-test': (context)
            => const PreAdmissionTestPage(),
      },
    );
  }
}