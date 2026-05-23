import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'special_request_form_page.dart';

class SpecialRequestLinkPage extends StatelessWidget {
  const SpecialRequestLinkPage({super.key});

  final String specialRequestLink =
      "https://learnmatch-2b5c4.web.app/#/special-request";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),

      appBar: AppBar(
        title: const Text(
          "Special Request 🧩",
          style: TextStyle(fontWeight: FontWeight.bold),
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
              "Share Special Request Form",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Send this link to parents so they can submit any special needs or conditions for their child. This information is strictly confidential.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 32),

            // Link Card (same style as Assessment)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.08),
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
                        color: Color(0xFF6A1B9A),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Special Request Access Link",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Link box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FBFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: SelectableText(
                      specialRequestLink,
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
                          ClipboardData(text: specialRequestLink),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Special Request link copied!"),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text(
                        "Copy Link",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}