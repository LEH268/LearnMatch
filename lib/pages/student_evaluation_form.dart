import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentEvaluationForm extends StatefulWidget {
  const StudentEvaluationForm({super.key});

  @override
  State<StudentEvaluationForm> createState() =>
      _StudentEvaluationFormState();
}

class _StudentEvaluationFormState
    extends State<StudentEvaluationForm> {

  // ==========================================
  // Student Info
  // ==========================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _classController =
      TextEditingController();

  // ==========================================
  // Question State
  // ==========================================

  int _currentIndex = 0;
  bool _hasStarted = false;
  bool _isSavingToDatabase = false;

  final TextEditingController _answerController =
      TextEditingController();

  final List<String> _answers = [];

  final List<String> _questions = [
    "1. How was your experience in this class with your classmates for the past year?",
    "2. How was your experience in this class with your teachers for the past year?",
    "3. What has been the highlight throughout the year?",
    "4. Would you like to stay in this class? Why or why not?",
    "5. What do you wish the class could do differently?",
  ];

  // ==========================================
  // Start Form
  // ==========================================

  void _startForm() {
    if (_nameController.text.trim().isEmpty ||
        _classController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your name and class."),
        ),
      );
      return;
    }

    setState(() {
      _hasStarted = true;
    });
  }

  // ==========================================
  // Submit Each Answer
  // ==========================================

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

  // ==========================================
  // Score each answer 1-5 from sentiment words.
  // This is intentionally simple; the teacher's
  // follow-up page just needs a real number per
  // question instead of the old hardcoded 4s.
  // ==========================================

  int _scoreAnswer(String raw) {
    final text = raw.toLowerCase();

    const positive = [
      'love', 'loved', 'great', 'amazing', 'fun', 'enjoy', 'enjoyed',
      'happy', 'good', 'excellent', 'best', 'awesome', 'wonderful',
      'helpful', 'nice', 'kind', 'support', 'supportive', 'comfortable',
      'friend', 'friends', 'learn', 'learned', 'improved', 'better',
      'fantastic', 'engaged', 'inspired'
    ];
    const negative = [
      'hate', 'hated', 'bad', 'boring', 'awful', 'terrible', 'sad',
      'angry', 'annoyed', 'difficult', 'hard', 'struggle', 'struggled',
      'lonely', 'alone', 'bully', 'bullied', 'unfair', 'stress',
      'stressed', 'tired', 'exhausted', 'confused', 'lost', 'failed'
    ];

    int score = 3; // neutral baseline
    for (final w in positive) {
      if (text.contains(w)) score++;
    }
    for (final w in negative) {
      if (text.contains(w)) score--;
    }

    // Tiny boost so very long, considered answers nudge up slightly
    if (raw.trim().split(RegExp(r'\s+')).length > 25) score++;

    return score.clamp(1, 5);
  }

  // ==========================================
  // Submit To Firebase
  // Try to UPDATE the existing student doc that
  // was created by the pre-admission test
  // (matched by name + className). If none exists,
  // fall back to creating a new one.
  // ==========================================

  Future<void> _submitFormToDatabase() async {
    setState(() => _isSavingToDatabase = true);

    try {
      final String name = _nameController.text.trim();
      final String className = _classController.text.trim();

      // Real scores derived from the answers
      final detailedAnswers =
          _answers.map(_scoreAnswer).toList();
      final evaluationScore =
          detailedAnswers.fold<int>(0, (sum, v) => sum + v);

      final payload = <String, dynamic>{
        'name': name,
        'className': className,
        'hasSubmittedForm': true,
        'evaluationSubmitted': true,
        'evaluationScore': evaluationScore,
        'detailedAnswers': detailedAnswers,
        'writtenAnswers': _answers,
        'submittedAt': Timestamp.now(),
      };

      final collection =
          FirebaseFirestore.instance.collection('students');

      // 1) Try to find an existing student doc with the same name.
      //    We match on name (case-insensitive) so the teacher's
      //    follow-up page sees the SAME record they were already
      //    tracking, instead of a duplicate.
      final query = await collection
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      QueryDocumentSnapshot<Map<String, dynamic>>? match;
      if (query.docs.isNotEmpty) {
        match = query.docs.first;
      } else {
        // Fallback: case-insensitive scan in case the name was
        // stored with a different capitalisation.
        final all = await collection.get();
        for (final doc in all.docs) {
          final n = (doc.data()['name'] ?? '').toString().trim();
          if (n.toLowerCase() == name.toLowerCase()) {
            match = doc;
            break;
          }
        }
      }

      if (match != null) {
        // Merge into existing doc — keeps varkScores etc. intact
        await match.reference.set(payload, SetOptions(merge: true));
      } else {
        // No existing student → create new
        await collection.add(payload);
      }

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      setState(() => _isSavingToDatabase = false);

      // ==========================================
      // Success Dialog
      // ==========================================

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text('Evaluation Submitted 🎉',
                  textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            'Your response has been synced to the teacher dashboard.\n\nYour total score: $evaluationScore / 25',
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

  // ==========================================
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    double progress =
        (_currentIndex + 1) / _questions.length;

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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.grey.shade300,
                            color: Colors.deepPurpleAccent,
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildQuestionPage(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ==========================================
  // Student Info Page
  // ==========================================

  Widget _buildStudentInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.school, size: 80, color: Colors.deepPurple),
        const SizedBox(height: 20),
        const Text(
          "Student Information",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          "Use the same name you used for the pre-admission test so your evaluation links to your existing profile.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: "Student Name",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _classController,
          decoration: InputDecoration(
            labelText: "Class Name",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _startForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            "Start Evaluation",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // Saving Screen
  // ==========================================

  Widget _buildSavingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.deepPurple),
          SizedBox(height: 20),
          Text(
            'Syncing to School Database...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Question Page
  // ==========================================

  Widget _buildQuestionPage() {
    String currentQuestion = _questions[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Question ${_currentIndex + 1}",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.blueGrey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          currentQuestion,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _currentIndex == _questions.length - 1
                ? "Submit Evaluation"
                : "Next Question",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}