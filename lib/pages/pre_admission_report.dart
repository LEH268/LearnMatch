import 'package:flutter/material.dart';

// ==========================================
// STUDENT REPORT PAGE
// ==========================================
class ReportPage extends StatelessWidget {
  final Map<String, int> varkScores;
  final Map<String, int> pScores;

  const ReportPage({
    super.key,
    required this.varkScores,
    required this.pScores,
  });

  int _calcPercent(int score, int total) =>
      total == 0 ? 0 : ((score / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    int totalVark = varkScores.values.reduce((a, b) => a + b);

    int pV = _calcPercent(varkScores['V']!, totalVark);
    int pA = _calcPercent(varkScores['A']!, totalVark);
    int pR = _calcPercent(varkScores['R']!, totalVark);
    int pK = _calcPercent(varkScores['K']!, totalVark);

    int totalSE = pScores['S']! + pScores['E']!;
    int pS = _calcPercent(pScores['S']!, totalSE);
    int pE = _calcPercent(pScores['E']!, totalSE);

    int totalIX = pScores['I']! + pScores['X']!;
    int pI = _calcPercent(pScores['I']!, totalIX);
    int pX = _calcPercent(pScores['X']!, totalIX);

    int totalPR = pScores['P']! + pScores['R']!;
    int pP = _calcPercent(pScores['P']!, totalPR);
    int pRef = _calcPercent(pScores['R']!, totalPR);

    String topVark = varkScores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    String varkInsight = topVark == 'V'
        ? "You learn best through visual aids like charts and videos."
        : topVark == 'A'
            ? "You thrive in discussions and listening environments."
            : topVark == 'R'
                ? "Reading and writing structured notes is your superpower."
                : "You are a hands-on learner. Physical engagement is key.";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Your Learning Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Analysis Complete 🧠",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            const Text("1. VARK Learning Style",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            Text("V: $pV% | A: $pA% | R: $pR% | K: $pK%"),
            const SizedBox(height: 10),

            Text(varkInsight),

            const SizedBox(height: 30),

            const Text("2. Cognitive Profile",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            Text(
              "Structured $pS% vs Exploratory $pE%\n"
              "Introvert $pI% vs Extrovert $pX%\n"
              "Impulsivity $pP% vs Reflectivity $pRef%",
            ),

            const SizedBox(height: 40),

            Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text("Back to Start"),
              ),
            )
          ],
        ),
      ),
    );
  }
}