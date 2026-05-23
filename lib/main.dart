import 'package:flutter/material.dart';

import 'login_page.dart';
import 'home_page.dart';
import 'pre_admission_test.dart';
import 'assessment_link_page.dart';
import 'class_network_page.dart';
import 'student_follow_up_page.dart';

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
      initialRoute: '/',
      
      routes: {
        // Login Page
        '/': (context) => const LoginPage(),
        
        // Teacher Dashboard
        '/home': (context) => const HomePage(),
        
        // Pre-admission Test Page
        '/pre-admission-test': (context) => const PreAdmissionTestPage(),

        // Feature 1: Assessment Link
        '/assessment-link': (context) => const AssessmentLinkPage(),

        // Feature 2: Student Intelligence
        '/class-network': (context) => const ClassNetworkPage(),

        // Feature 3: Student Follow-up & AI Placement
        '/student-follow-up': (context) => const StudentFollowUpPage(),
      },
    );
  }
}