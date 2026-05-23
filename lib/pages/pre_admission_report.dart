import 'package:flutter/material.dart';

// =============
// Report Page
// =============
class ReportPage extends StatelessWidget {
  final Map<String, int> varkScores;
  final Map<String, int> pScores;

  const ReportPage({super.key, required this.varkScores, required this.pScores});

  int _calcPercent(int score, int total) => total == 0 ? 0 : ((score / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    // 1. count VARK total marks and calculate percentages
    int totalVark = varkScores.values.reduce((a, b) => a + b);
    int pV = _calcPercent(varkScores['V']!, totalVark);
    int pA = _calcPercent(varkScores['A']!, totalVark);
    int pR = _calcPercent(varkScores['R']!, totalVark);
    int pK = _calcPercent(varkScores['K']!, totalVark);

    // 2. count personality trait totals and calculate dynamic percentages
    int totalSE = pScores['S']! + pScores['E']!;
    int pS = _calcPercent(pScores['S']!, totalSE);
    int pE = _calcPercent(pScores['E']!, totalSE);

    int totalIX = pScores['I']! + pScores['X']!;
    int pI = _calcPercent(pScores['I']!, totalIX);
    int pX = _calcPercent(pScores['X']!, totalIX);

    int totalPR = pScores['P']! + pScores['R']!;
    int pP = _calcPercent(pScores['P']!, totalPR);
    int pRef = _calcPercent(pScores['R']!, totalPR);

    // 3. generate simple AI insight text
    String topVark = varkScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    String varkInsight = topVark == 'V' ? "You learn best through visual aids like charts and videos." :
                         topVark == 'A' ? "You thrive in discussions and listening environments." :
                         topVark == 'R' ? "Reading and writing structured notes is your superpower." :
                                          "You are a hands-on learner. Physical engagement is key for you.";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Your Learning Profile"), foregroundColor: Colors.black87, backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("AI Analysis Complete 🧠", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // Section 1: VARK
            _buildSectionTitle("1. Learning Style (VARK)"),
            Text("Visual: $pV% | Auditory: $pA% | Read/Write: $pR% | Kinesthetic: $pK%", style: const TextStyle(fontSize: 16)),
            _buildInsightBox(varkInsight),

            const SizedBox(height: 30),

            // Section 2: Personality
            _buildSectionTitle("2. Cognitive Personality"),
            Text("Structure Need: Structured $pS% vs Exploratory $pE%\n"
                 "Social Mode: Introvert $pI% vs Extrovert $pX%\n"
                 "Pacing: Impulsivity $pP% vs Reflectivity $pRef%", style: const TextStyle(fontSize: 16, height: 1.5)),
            _buildInsightBox("Your profile suggests you work best in ${pS > 50 ? 'structured' : 'flexible'} environments and prefer ${pI > 50 ? 'independent study' : 'group collaborations'}."),

            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text("Return to Dashboard", style: TextStyle(fontSize: 18, color: Color(0xFF0F9D58))),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F9D58))),
    );
  }

  Widget _buildInsightBox(String insight) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF0F9D58), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text("AI Insight: $insight", style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}