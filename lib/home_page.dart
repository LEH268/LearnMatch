import 'package:flutter/material.dart';
import 'pre_admission_test.dart';
import 'class_network_page.dart'; // Added the import for the new Class Network Page
import 'assessment_link_page.dart';

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
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Color(0xFF0F9D58), size: 30),
            onPressed: () {
              // TODO: Navigate to teacher profile settings
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Greeting for the Teacher
              const Text(
                "Welcome Back, Educator! 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's orchestrate your adaptive classroom today.",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Core Features Section Title
              const Text(
                "Classroom Tools 🛠️",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),

              // Feature 1: Assessment Link Generator (Form for students)
              _buildFeatureCard(
                context,
                title: "Create Assessment Link 🔗",
                description: "Draft questions and generate a shareable web link. Students fill it out with zero login required!",
                iconData: Icons.assignment_rounded, 
                color: const Color(0xFFE8F5E9), // Light green
                accentColor: const Color(0xFF0F9D58),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessmentLinkPage()),
                ),
              ),
              const SizedBox(height: 20),

              // Feature 2: Learning Intelligence Network (Analytics)
              // This now navigates to the new ClassNetworkPage!
              _buildFeatureCard(
                context,
                title: "Student Intelligence 🕸️",
                description: "Monitor incoming form responses, visualize class relationships, and catch early risk signals instantly.",
                iconData: Icons.hub_rounded,
                color: const Color(0xFFE3F2FD), // Light blue
                accentColor: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ClassNetworkPage()),
                ),
              ),
              const SizedBox(height: 20),

              // Feature 3: AI Re-Streaming System (Class placement logic)
              _buildFeatureCard(
                context,
                title: "AI Class Placement 🚀",
                description: "Run end-of-cycle evaluations for your entire class. Get AI-driven recommendations for re-streaming.",
                iconData: Icons.groups_rounded,
                color: const Color(0xFFFFF3E0), // Light orange
                accentColor: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeaturePage(title: "AI Re-Streaming System")),
                ),
              ),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    iconData,
                    size: 32,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: accentColor, 
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: accentColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for other features
class FeaturePage extends StatelessWidget {
  final String title;
  const FeaturePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction_rounded, size: 80, color: Color(0xFF0F9D58)),
            const SizedBox(height: 16),
            Text(
              "$title\nWorkspace coming soon! ✨",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: Colors.blueGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}