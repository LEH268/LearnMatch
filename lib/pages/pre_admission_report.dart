import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  final String studentName;
  final Map<String, int> varkScores;
  final Map<String, int> pScores;

  const ReportPage({
    super.key,
    required this.studentName,
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

    final int totalSE = (pScores['S'] ?? 0) + (pScores['E'] ?? 0);
    final int pS   = _calcPercent(pScores['S'] ?? 0, totalSE);
    final int pE   = _calcPercent(pScores['E'] ?? 0, totalSE);

    final int totalIX = (pScores['I'] ?? 0) + (pScores['X'] ?? 0);
    final int pI   = _calcPercent(pScores['I'] ?? 0, totalIX);
    final int pX   = _calcPercent(pScores['X'] ?? 0, totalIX);

    int totalPR = pScores['P']! + pScores['R']!;
    int pP = _calcPercent(pScores['P']!, totalPR);
    int pRef = _calcPercent(pScores['R']!, totalPR);

    // Dominant VARK
    String topVark = 'V';
    if (totalVark > 0) {
      topVark = varkScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

    final String varkInsight = topVark == 'V'
        ? "You learn best through visual aids like charts and videos."
        : topVark == 'A'
            ? "You thrive in discussions and listening environments."
            : topVark == 'R'
                ? "Reading and writing structured notes is your superpower."
                : "You are a hands-on learner. Physical engagement is key.";

    final Map<String, Color> varkColors = {
      'V': const Color(0xFF1565C0),
      'A': const Color(0xFF2E7D32),
      'R': const Color(0xFF6A1B9A),
      'K': const Color(0xFFE65100),
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: Text(
          studentName.isEmpty ? "Learning Profile" : "$studentName's Report",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F9D58),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ─────────────────────────────
            const Text(
              "AI Analysis Complete 🧠",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              studentName.isEmpty ? "" : "Student: $studentName",
              style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // ── VARK Section ───────────────────────
            const Text(
              "1. VARK Learning Style",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildVarkBar("Visual (V)",       pV,  varkColors['V']!, topVark == 'V'),
            _buildVarkBar("Auditory (A)",     pA,  varkColors['A']!, topVark == 'A'),
            _buildVarkBar("Read/Write (R)",   pR,  varkColors['R']!, topVark == 'R'),
            _buildVarkBar("Kinesthetic (K)",  pK,  varkColors['K']!, topVark == 'K'),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (varkColors[topVark] ?? Colors.grey).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded,
                      color: varkColors[topVark] ?? Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(varkInsight,
                        style: const TextStyle(
                            fontSize: 14, height: 1.5)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Personality Section ────────────────
            const Text(
              "2. Cognitive Profile",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildDualBar("Structured",  pS,  "Exploratory", pE,  Colors.indigo),
            const SizedBox(height: 12),
            _buildDualBar("Introvert",   pI,  "Extrovert",   pX,  Colors.teal),
            const SizedBox(height: 12),
            _buildDualBar("Impulsivity", pP,  "Reflectivity",pRef,Colors.deepOrange),

            const SizedBox(height: 40),

            // ── Back button ────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Back",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── VARK single bar ──────────────────────────────
  Widget _buildVarkBar(
      String label, int percent, Color color, bool isTop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      fontWeight:
                          isTop ? FontWeight.bold : FontWeight.normal,
                      color: isTop ? color : Colors.black87)),
              const Spacer(),
              Text("$percent%",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color)),
              if (isTop)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("Dominant",
                        style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: color.withOpacity(0.10),
              color: color,
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Dual bar (left vs right) ─────────────────────
  Widget _buildDualBar(
    String leftLabel,
    int leftPct,
    String rightLabel,
    int rightPct,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leftLabel,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color)),
              Text(rightLabel,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color.withOpacity(0.6))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  flex: leftPct == 0 && rightPct == 0 ? 1 : leftPct,
                  child: Container(
                      height: 12, color: color),
                ),
                Expanded(
                  flex: leftPct == 0 && rightPct == 0 ? 1 : rightPct,
                  child: Container(
                      height: 12,
                      color: color.withOpacity(0.25)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$leftPct%",
                  style: const TextStyle(fontSize: 12)),
              Text("$rightPct%",
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}