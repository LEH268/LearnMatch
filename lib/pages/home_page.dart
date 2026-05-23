import 'package:flutter/material.dart';
import 'special_request_link_page.dart';
import 'pre_admission_test.dart';
import 'class_network_page.dart'; 
import 'assessment_link_page.dart';
import 'student_follow_up_page.dart';
import 'class_placement_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: const Text(
          "Teacher Dashboard 🌟",
          style: TextStyle(
            color: Color(0xFF0F9D58),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F9D58).withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.account_circle_rounded, color: Color(0xFF0F9D58), size: 28),
              onPressed: () {
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F9D58), Color(0xFF0B8043)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F9D58).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Welcome Back, Educator! 👋",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Let's orchestrate your adaptive classroom today.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  const Text(
                    "Classroom Tools",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.build_circle_rounded, color: Colors.grey.shade400, size: 20),
                ],
              ),
              const SizedBox(height: 20),

              // Feature 1: Assessment Link Generator
              _buildFeatureCard(
                context,
                title: "Pre-admission Test 📝",
                description: "Discover how students learn best. Send a quick, login-free web link to instantly build their personality and VARK learning profiles.",
                iconData: Icons.assignment_rounded, 
                color: const Color(0xFFE8F5E9), 
                accentColor: const Color(0xFF0F9D58),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessmentLinkPage()),
                ),
              ),

              // Feature 2: Learning Intelligence Network
              _buildFeatureCard(
                context,
                title: "Relationship Diagram 🕸️",
                description: "Uncover the hidden social web of your classroom. Visualize student connections to proactively build an inclusive and safe learning space.",
                iconData: Icons.hub_rounded,
                color: const Color(0xFFE3F2FD), 
                accentColor: Colors.blue.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClassNetworkPage()),
                ),
              ),

              // Feature 3: AI Re-Streaming System
              _buildFeatureCard(
                context,
                title: "Class Fit Analyzer 📊",
                description: "Take the guesswork out of annual re-streaming. Use AI to analyze performance and feedback for the perfect academic placement.",
                iconData: Icons.groups_rounded,
                color: const Color(0xFFFFF3E0), 
                accentColor: Colors.orange.shade700,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StudentFollowUpPage()),
                ),
              ),

              // Feature 4: Special Request Form
              _buildFeatureCard(
                context,
                title: "Special Request 🫂",
                description: "Ensure no student is left behind. Securely record special accommodations and neurodivergent needs to deliver truly personalized support.",
                iconData: Icons.health_and_safety_rounded,
                color: const Color(0xFFF3E5F5), 
                accentColor: const Color(0xFF7B1FA2),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpecialRequestLinkPage(),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData iconData,
    required Color color, 
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.8), width: 1.5), 
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08), 
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          highlightColor: color.withOpacity(0.3),
          splashColor: color.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color, 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    iconData,
                    size: 32,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900, 
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FeaturePage extends StatelessWidget {
  final String title;
  const FeaturePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFF0F9D58), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F9D58)),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F9D58).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.construction_rounded, size: 64, color: Color(0xFF0F9D58)),
              ),
              const SizedBox(height: 24),
              Text(
                "$title\nWorkspace coming soon! ✨",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We are currently building this module for the next big update.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey),
              )
            ],
          ),
        ),
      ),
    );
  }
}