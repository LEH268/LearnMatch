import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class StudentEvaluationForm extends StatefulWidget {
  const StudentEvaluationForm({super.key});

  @override
  State<StudentEvaluationForm> createState() =>
      _StudentEvaluationFormState();
}

class _StudentEvaluationFormState extends State<StudentEvaluationForm> {
  // ──────────────────────────────────────────
  // Student Info
  // ──────────────────────────────────────────
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();

  // ──────────────────────────────────────────
  // Question State
  // ──────────────────────────────────────────
  int _currentIndex = 0;
  bool _hasStarted = false;
  bool _isSavingToDatabase = false;
  String _saveStatusMessage = 'Syncing to your student profile…';

  final TextEditingController _answerController = TextEditingController();
  final List<String> _answers = [];

  final List<String> _questions = [
    "1. How was your experience in this class with your classmates for the past year?",
    "2. How was your experience in this class with your teachers for the past year?",
    "3. What has been the highlight throughout the year?",
    "4. Would you like to stay in this class? Why or why not?",
    "5. What do you wish the class could do differently?",
  ];

  // Same Gemini model pattern as pre_admission_report.dart
  final _aiModel = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: '',
  );

  // ──────────────────────────────────────────
  // Flow control
  // ──────────────────────────────────────────
  void _startForm() {
    if (_nameController.text.trim().isEmpty ||
        _classController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name and class.")),
      );
      return;
    }
    setState(() => _hasStarted = true);
  }

  void _submitAnswer() {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your answer.")),
      );
      return;
    }
    _answers.add(_answerController.text.trim());
    _answerController.clear();

    setState(() {
      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else {
        _submitFormToDatabase();
      }
    });
  }

  // ──────────────────────────────────────────
  // AI scoring per question (1–5) + total (0–25)
  // ──────────────────────────────────────────
  Future<List<int>> _aiScoreAnswers(List<String> answers) async {
    // Build a single prompt with all 5 answers so the AI returns
    // scores in one call (cheaper + faster + more consistent).
    final buffer = StringBuffer();
    for (int i = 0; i < answers.length; i++) {
      buffer.writeln('Q${i + 1}: ${_questions[i]}');
      buffer.writeln('Answer: ${answers[i]}');
      buffer.writeln();
    }

    final prompt = """
You are an Educational AI that evaluates how positive and engaged a student is from their end-of-year reflection answers.

For EACH answer below, give a score from 1 to 5:
- 5 = very positive, engaged, happy, growth-minded
- 4 = generally positive
- 3 = neutral / mixed
- 2 = generally negative
- 1 = very negative, disengaged, unhappy

Reflect on the SENTIMENT, EFFORT, and DETAIL of the answer.

${buffer.toString()}

Output ONLY the 5 scores on a single line, separated by commas, in order Q1,Q2,Q3,Q4,Q5.
Example output: 4,3,5,2,4
""";

    try {
      final response = await _aiModel.generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();

      // Parse the comma-separated digits. Be defensive — the model
      // might add extra punctuation or text.
      final numbers = RegExp(r'[1-5]')
          .allMatches(text)
          .map((m) => int.parse(m.group(0)!))
          .toList();

      if (numbers.length >= answers.length) {
        return numbers.take(answers.length).toList();
      }
      // Fallback: pad with 3s (neutral) if AI returned too few
      return [
        ...numbers,
        ...List.filled(answers.length - numbers.length, 3),
      ];
    } catch (_) {
      // AI unavailable → neutral baseline. Teacher will still see
      // the written answers and can use their own judgement.
      return List.filled(answers.length, 3);
    }
  }

  // ──────────────────────────────────────────
  // Find the existing student doc (case- and whitespace-insensitive).
  // Returns null if no record exists yet.
  // ──────────────────────────────────────────
  Future<DocumentReference?> _findExistingStudentDoc(
    String typedName,
    String typedClass,
  ) async {
    final normalized = typedName.trim().toLowerCase();
    final collection = FirebaseFirestore.instance.collection('students');

    // We can't rely on .where('name', isEqualTo: ...) alone because
    // Firestore is case-sensitive AND the pre-admission test may
    // have stored the name with stray whitespace. So just pull all
    // students (this collection is small per school) and compare
    // ourselves. We prefer the one with VARK data (real profile).
    final all = await collection.get();

    DocumentSnapshot? namedMatch;
    DocumentSnapshot? namedAndClassMatch;

    for (final doc in all.docs) {
      final data = doc.data();
      final n = (data['name'] ?? '').toString().trim().toLowerCase();
      if (n != normalized) continue;

      // Prefer the doc that already has assessment data, because
      // that's the real student profile we want to merge into.
      final hasVark = (data['varkScores'] as Map?)?.isNotEmpty ?? false;
      if (namedMatch == null) namedMatch = doc;
      if (hasVark) namedMatch = doc;

      final c = (data['className'] ?? '').toString().trim().toLowerCase();
      if (c == typedClass.trim().toLowerCase()) {
        namedAndClassMatch = doc;
      }
    }

    // Prefer name + class match. Fall back to name-only.
    final chosen = namedAndClassMatch ?? namedMatch;
    return chosen?.reference;
  }

  // ──────────────────────────────────────────
  // Submit
  // ──────────────────────────────────────────
  Future<void> _submitFormToDatabase() async {
    setState(() {
      _isSavingToDatabase = true;
      _saveStatusMessage = 'AI is reviewing your answers…';
    });

    try {
      final String name = _nameController.text.trim();
      final String className = _classController.text.trim();

      // 1. AI scores the answers
      final detailedAnswers = await _aiScoreAnswers(_answers);
      final evaluationScore =
          detailedAnswers.fold<int>(0, (sum, v) => sum + v);

      if (mounted) {
        setState(() => _saveStatusMessage = 'Syncing to your student profile…');
      }

      // 2. Find the existing student doc (created by pre-admission test)
      final existingRef = await _findExistingStudentDoc(name, className);

      final evaluationPayload = <String, dynamic>{
        'hasSubmittedForm': true,
        'evaluationSubmitted': true,
        'evaluationScore': evaluationScore,
        'detailedAnswers': detailedAnswers,
        'writtenAnswers': _answers,
        'submittedAt': Timestamp.now(),
      };

      bool merged;
      if (existingRef != null) {
        // MERGE — keeps varkScores / personalityScores / placement intact.
        // Don't overwrite name or className unless missing.
        final existing = await existingRef.get();
        final eData = existing.data() as Map<String, dynamic>? ?? {};

        await existingRef.set({
          ...evaluationPayload,
          'name': (eData['name'] ?? name),
          'className': ((eData['className'] ?? '').toString().isEmpty
              ? className
              : eData['className']),
        }, SetOptions(merge: true));
        merged = true;
      } else {
        // Genuinely new student — only happens if student skipped
        // pre-admission entirely.
        await FirebaseFirestore.instance.collection('students').add({
          'name': name,
          'className': className,
          ...evaluationPayload,
          'createdAt': FieldValue.serverTimestamp(),
        });
        merged = false;
      }

      if (!mounted) return;
      setState(() => _isSavingToDatabase = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text('Evaluation Submitted 🎉',
                  textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            merged
                ? 'Your evaluation has been AI-scored and synced to your existing student profile.\n\nAI Score: $evaluationScore / 25'
                : 'Your evaluation has been AI-scored and recorded.\n\nAI Score: $evaluationScore / 25',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingToDatabase = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    }
  }

  // ──────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text(
          "End of Year Evaluation",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isSavingToDatabase
              ? _buildSavingScreen()
              : !_hasStarted
                  ? _buildStudentInfoPage()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.deepPurpleAccent,
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(child: _buildQuestionPage()),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildStudentInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.school, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 20),
        const Text("Student Information",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          "Please use the SAME name and class you used for the pre-admission test, so your evaluation links to your profile.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Student Name",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _classController,
          decoration: InputDecoration(
            labelText: "Class Name",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Start Evaluation",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSavingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.deepPurple),
          const SizedBox(height: 20),
          Text(
            _saveStatusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage() {
    final currentQuestion = _questions[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Question ${_currentIndex + 1}",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 12),
        Text(currentQuestion,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            )),
        const SizedBox(height: 30),
        TextField(
          controller: _answerController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: "Write your response here...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _submitAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            _currentIndex == _questions.length - 1
                ? "Submit Evaluation"
                : "Next Question",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}