import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Cute 3D Mascot / Illustration representing a teacher/education
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://cdn3d.iconscout.com/3d/premium/thumb/online-teaching-4352229-3618776.png',
                      ),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // App Title & Tagline tailored for Teachers
                const Text(
                  "LearnMatch for Teachers 🍎",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F9D58),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Empower your classroom.\nSend assessments seamlessly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // Teacher Email Input Field
                _buildCuteTextField(
                  hintText: 'Teacher Email or Staff ID 📧',
                  icon: Icons.school_rounded,
                  isPassword: false,
                ),
                const SizedBox(height: 16),

                // Password Input Field
                _buildCuteTextField(
                  hintText: 'Secure Password 🔑',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                ),
                
                // Forgot Password Button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password logic
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        color: Color(0xFF0F9D58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F9D58),
                    foregroundColor: Colors.white,
                    elevation: 5,
                    shadowColor: const Color(0xFF0F9D58).withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), 
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Access Teacher Dashboard 🚀",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // School Registration Prompt
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "School not registered?",
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to school registration page
                      },
                      child: const Text(
                        "Contact Admin 📝",
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuteTextField({
    required String hintText,
    required IconData icon,
    required bool isPassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        obscureText: isPassword ? _obscureText : false,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF0F9D58)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade400,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}