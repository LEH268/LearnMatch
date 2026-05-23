import 'package:flutter/material.dart';

import 'special_request_link_page.dart';
import 'pre_admission_test.dart';
import 'class_network_page.dart';
import 'assessment_link_page.dart';
import 'student_follow_up_page.dart';
import 'class_placement_page.dart';

import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final role = await AuthService.getCurrentUserRole();

      if (mounted) {
        setState(() {
          _role = role;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _role = null;
          _loading = false;
        });
      }
    }
  }

  bool get isAdmin => _role == 'admin';
  bool get isTeacher => _role == 'teacher';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isAdmin ? "Admin Dashboard ⚙️" : "Teacher Dashboard 🌟",
          style: const TextStyle(
            color: Color(0xFF0F9D58),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Welcome Back 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // ADMIN ONLY
              // =========================
              if (isAdmin) ...[
                _buildFeatureCard(
                  context,
                  title: "Class Placement 🧠",
                  description: "Run AI-based class grouping and student assignment.",
                  icon: Icons.auto_awesome,
                  color: const Color(0xFFFFF3E0),
                  accent: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClassPlacementPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                _buildFeatureCard(
                  context,
                  title: "Assessment Link 🔗",
                  description: "Generate and manage assessment links.",
                  icon: Icons.link,
                  color: const Color(0xFFE8F5E9),
                  accent: const Color(0xFF0F9D58),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AssessmentLinkPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],

              // =========================
              // COMMON FEATURES
              // =========================
              _buildFeatureCard(
                context,
                title: "Class Network 🕸️",
                description: "View student connections and learning behavior map.",
                icon: Icons.hub,
                color: const Color(0xFFE3F2FD),
                accent: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClassNetworkPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _buildFeatureCard(
                context,
                title: "Pre-Admission Test 📝",
                description: "Student learning profile assessment system.",
                icon: Icons.assignment,
                color: const Color(0xFFEDE7F6),
                accent: const Color(0xFF6A1B9A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PreAdmissionTestPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _buildFeatureCard(
                context,
                title: "Student Follow-up 📊",
                description: "Track student progress and learning insights.",
                icon: Icons.insights,
                color: const Color(0xFFFFFDE7),
                accent: Colors.amber,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentFollowUpPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _buildFeatureCard(
                context,
                title: "Special Requests 🧩",
                description: "Manage student needs and special conditions.",
                icon: Icons.health_and_safety,
                color: const Color(0xFFFCE4EC),
                accent: Colors.pink,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpecialRequestLinkPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // CARD UI
  // =========================
  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: accent, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: accent.withOpacity(0.6)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}