import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/class_network_page.dart';
import 'pages/pre_admission_test.dart';
import 'pages/special_request_form_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      appId: "YOUR_APP_ID",
      messagingSenderId: "YOUR_SENDER_ID",
      projectId: "YOUR_PROJECT_ID",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LearnMatch',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F9D58),
        ),
        useMaterial3: true,
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/network': (context) => const ClassNetworkPage(),
        '/pre-admission-test': (context) => const PreAdmissionTestPage(),
        '/special-request': (context) => const SpecialRequestFormPage(),
      },
    );
  }
}