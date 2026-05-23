import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {

  static const String apiKey = '';

  static final model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: apiKey,
  );

  // =========================
  // VARK Insight
  // =========================
  static Future<String> generateVarkInsight({
    required Map<String, int> scores,
  }) async {

    final prompt = """
You are an educational AI.

Analyze this student's VARK learning style scores:

Visual: ${scores['V']}
Auditory: ${scores['A']}
Read/Write: ${scores['R']}
Kinesthetic: ${scores['K']}

Give:
1. Dominant learning style
2. Short explanation
3. Best learning strategy

Keep it under 80 words.
""";

    final response = await model.generateContent(
      [Content.text(prompt)],
    );

    return response.text ?? "No insight generated.";
  }

  // =========================
  // Personality Insight
  // =========================
  static Future<String> generatePersonalityInsight({
    required Map<String, int> scores,
  }) async {

    final prompt = """
You are an educational psychologist AI.

Analyze this student's personality profile:

Structured: ${scores['S']}
Exploratory: ${scores['E']}

Introvert: ${scores['I']}
Extrovert: ${scores['X']}

Impulsive: ${scores['P']}
Reflective: ${scores['R']}

Give:
1. Personality summary
2. Classroom behavior prediction
3. Suggested teaching approach

Keep it under 80 words.
""";

    final response = await model.generateContent(
      [Content.text(prompt)],
    );

    return response.text ?? "No insight generated.";
  }
}