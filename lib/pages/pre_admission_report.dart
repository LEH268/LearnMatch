import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ReportPage extends StatefulWidget {
  
  final String studentName;
  final Map<String, int> varkScores;
  final Map<String, int> pScores;

  const ReportPage({
    super.key,
    required this.studentName,
    required this.varkScores,
    required this.pScores,
  });

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  
  String aiVarkInsight = "Generating AI insight...";
  String aiPersonalityInsight = "Generating AI insight...";
  bool isLoadingAI = true;

  final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: '',
  );

  @override
  void initState() {
    super.initState();
    generateAIInsights();
  }

  int _calcPercent(int score, int total) =>
      total == 0 ? 0 : ((score / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    int totalVark = widget.varkScores.values.reduce((a, b) => a + b);

    int pV = _calcPercent(widget.varkScores['V']!, totalVark);
    int pA = _calcPercent(widget.varkScores['A']!, totalVark);
    int pR = _calcPercent(widget.varkScores['R']!, totalVark);
    int pK = _calcPercent(widget.varkScores['K']!, totalVark);

    final int totalSE = (widget.pScores['S'] ?? 0) + (widget.pScores['E'] ?? 0);
    final int pS   = _calcPercent(widget.pScores['S'] ?? 0, totalSE);
    final int pE   = _calcPercent(widget.pScores['E'] ?? 0, totalSE);

    final int totalIX = (widget.pScores['I'] ?? 0) + (widget.pScores['X'] ?? 0);
    final int pI   = _calcPercent(widget.pScores['I'] ?? 0, totalIX);
    final int pX   = _calcPercent(widget.pScores['X'] ?? 0, totalIX);

    int totalPR = widget.pScores['P']! + widget.pScores['R']!;
    int pP = _calcPercent(widget.pScores['P']!, totalPR);
    int pRef = _calcPercent(widget.pScores['R']!, totalPR);

    // Dominant VARK
    String topVark = 'V';
    if (totalVark > 0) {
      topVark = widget.varkScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
    }

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
          widget.studentName.isEmpty ? "Learning Profile" : "${widget.studentName}'s Report",
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
              widget.studentName.isEmpty ? "" : "Student: ${widget.studentName}",
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
                    // 修正了未定义的变量名
                    child: Text(isLoadingAI ? "Generating AI insight..." : aiVarkInsight,
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

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.psychology,
                    color: Colors.teal,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      isLoadingAI
                          ? "Generating AI personality insight..."
                          : aiPersonalityInsight,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

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

  Future<void> generateAIInsights() async {
    int totalVark =
        widget.varkScores.values.reduce((a, b) => a + b);

    int pV = _calcPercent(widget.varkScores['V']!, totalVark);
    int pA = _calcPercent(widget.varkScores['A']!, totalVark);
    int pR = _calcPercent(widget.varkScores['R']!, totalVark);
    int pK = _calcPercent(widget.varkScores['K']!, totalVark);

    final int totalSE =
        (widget.pScores['S'] ?? 0) +
        (widget.pScores['E'] ?? 0);

    final int pS =
        _calcPercent(widget.pScores['S'] ?? 0, totalSE);

    final int pE =
        _calcPercent(widget.pScores['E'] ?? 0, totalSE);

    final int totalIX =
        (widget.pScores['I'] ?? 0) +
        (widget.pScores['X'] ?? 0);

    final int pI =
        _calcPercent(widget.pScores['I'] ?? 0, totalIX);

    final int pX =
        _calcPercent(widget.pScores['X'] ?? 0, totalIX);

    int totalPR =
        widget.pScores['P']! +
        widget.pScores['R']!;

    int pP =
        _calcPercent(widget.pScores['P']!, totalPR);

    int pRef =
        _calcPercent(widget.pScores['R']!, totalPR);

    try {
      // 💡 获取学生名字，如果没填名字就用 "This student"
      String studentLabel = widget.studentName.isEmpty ? "This student" : widget.studentName;

      // 重新调教 VARK AI prompt
      final varkPrompt = """
  Student VARK scores:
  Visual: $pV%
  Auditory: $pA%
  Read/Write: $pR%
  Kinesthetic: $pK%

  Write a short learning insight in 2 sentences based on these VARK scores. 
  IMPORTANT: This report is being read by a teacher. You MUST refer to the student as '$studentLabel' or use third-person pronouns. Do NOT use the word 'you'.
  """;

      final varkResponse = await model.generateContent([
        Content.text(varkPrompt)
      ]);

      // 重新调教 Personality AI prompt
      final personalityPrompt = """
  Student personality profile:
  Structured: $pS%
  Exploratory: $pE%
  Introvert: $pI%
  Extrovert: $pX%
  Impulsive: $pP%
  Reflective: $pRef%

  Write a short personality and learning behavior insight in 2 sentences based on these scores.
  IMPORTANT: This report is being read by a teacher. You MUST refer to the student as '$studentLabel' or use third-person pronouns. Do NOT use the word 'you'.
  """;

      final personalityResponse = await model.generateContent([
        Content.text(personalityPrompt)
      ]);

      setState(() {
        aiVarkInsight =
            varkResponse.text ??
            "No AI insight generated.";

        aiPersonalityInsight =
            personalityResponse.text ??
            "No AI insight generated.";

        isLoadingAI = false;
      });

    } catch (e) {

      setState(() {
        aiVarkInsight =
            "Failed to generate AI insight.";

        aiPersonalityInsight =
            "Failed to generate AI insight.";

        isLoadingAI = false;
      });
    }
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