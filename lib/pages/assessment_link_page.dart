import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentLinkPage extends StatelessWidget {
  const AssessmentLinkPage({super.key});

  @override
  Widget build(BuildContext context) {

    const String assessmentLink =
        "https://learnmatch-2b5c4.web.app/#/pre-admission-test";

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),

      appBar: AppBar(
        title: const Text(
          "Assessment Link 🔗",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            // Title
            const Text(
              "Share Assessment with Students",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            // Description
            const Text(
              "Send this link to students so they can complete the pre-admission assessment online. Students can access the test directly without creating an account or logging in.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 32),

            // Link Card
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),

                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  const Row(
                    children: [

                      Icon(
                        Icons.link_rounded,
                        color: Color(0xFF0F9D58),
                      ),

                      SizedBox(width: 8),

                      Text(
                        "Assessment Access Link",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F9D58),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Link Box
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FBFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.green.shade100,
                      ),
                    ),

                    child: SelectableText(
                      assessmentLink,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Copy Button
                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(

                      onPressed: () async {

                        await Clipboard.setData(
                          const ClipboardData(
                            text: assessmentLink,
                          ),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Assessment link copied successfully!",
                            ),
                          ),
                        );
                      },

                      icon: const Icon(Icons.copy_rounded),

                      label: const Text(
                        "Copy Link",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Extra Info
            Container(
              padding: const EdgeInsets.all(16),

            ),
          ],
        ),
      ),
    );
  }
}