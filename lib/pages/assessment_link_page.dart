import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/placement_engine.dart';
import 'pre_admission_report.dart';

class AssessmentLinkPage extends StatefulWidget {
  const AssessmentLinkPage({super.key});

  @override
  State<AssessmentLinkPage> createState() => _AssessmentLinkPageState();
}

class _AssessmentLinkPageState extends State<AssessmentLinkPage> {
  static const String _assessmentLink =
      "https://learnmatch-2b5c4.web.app/#/pre-admission-test";

  final PlacementEngine _engine = PlacementEngine();
  bool _isPlacing = false;

  // ── One-click placement ────────────────────────
  Future<void> _runPlacement() async {
    setState(() => _isPlacing = true);
    try {
      final results = await _engine.runPlacement();
      if (!mounted) return;

      // Show summary dialog
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Placement Complete 🎉',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            '${results.length} students have been assigned to their classes.',
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Placement failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text(
          "Assessment Link 🔗",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title ──────────────────────────────
            const Text(
              "Share Assessment with Students",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Send this link to students so they can complete the pre-admission assessment online. Students can access the test directly without creating an account.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // ── Link Card ──────────────────────────
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
                      Icon(Icons.link_rounded, color: Color(0xFF0F9D58)),
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

                  // Link box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FBFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: SelectableText(
                      _assessmentLink,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Copy button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            const ClipboardData(text: _assessmentLink));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Assessment link copied successfully!")),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text("Copy Link",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── One-click placement button ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPlacing ? null : _runPlacement,
                      icon: _isPlacing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        _isPlacing ? "Placing Students..." : "One-Click Class Placement",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Student Reports Section ────────────
            const Text(
              "Student Reports 📋",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Tap any student to view their full learning profile report.",
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),

            // Firestore stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .orderBy('testCompletedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 48, color: Colors.blueGrey),
                        SizedBox(height: 12),
                        Text(
                          "No submissions yet.\nShare the link above to get started!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final className = data['className'] ?? 'Unassigned';
                    final varkRaw =
                        Map<String, int>.from(data['varkScores'] ?? {});
                    final pRaw = Map<String, int>.from(
                        data['personalityScores'] ?? {});

                    // Dominant VARK
                    String dominant = '-';
                    if (varkRaw.isNotEmpty) {
                      dominant = varkRaw.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key;
                    }

                    final classColor = _classColor(className);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor:
                              classColor.withOpacity(0.12),
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: classColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Style: $dominant  •  Class: $className',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.blueGrey),
                        onTap: () {
                          // Build pScores map expected by ReportPage
                          final pScores = {
                            'S': pRaw['Structured'] ?? 0,
                            'E': pRaw['Exploratory'] ?? 0,
                            'I': pRaw['Introvert'] ?? 0,
                            'X': pRaw['Extrovert'] ?? 0,
                            'P': pRaw['Impulsivity'] ?? 0,
                            'R': pRaw['Reflectivity'] ?? 0,
                          };

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportPage(
                                studentName: name,
                                varkScores: varkRaw,
                                pScores: pScores,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Color _classColor(String className) {
    switch (className) {
      case 'Class V': return const Color(0xFF1565C0);
      case 'Class A': return const Color(0xFF2E7D32);
      case 'Class R': return const Color(0xFF6A1B9A);
      case 'Class K': return const Color(0xFFE65100);
      default:        return Colors.blueGrey;
    }
  }
}