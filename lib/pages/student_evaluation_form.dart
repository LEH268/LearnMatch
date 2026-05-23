import 'package:flutter/material.dart';
import 'package:learn_match/models/student_record.dart';
import 'package:learn_match/ai/fake_database.dart';

class FakeDatabase {
  static List<StudentRecord> students = [];
}

class StudentEvaluationForm extends StatefulWidget {
  const StudentEvaluationForm({super.key});

  @override
  State<StudentEvaluationForm> createState() => _StudentEvaluationFormState();
}

class _StudentEvaluationFormState extends State<StudentEvaluationForm> {
  int _currentIndex = 0;
  bool _isSavingToDatabase = false; // State to show saving process

  final TextEditingController _answerController =
    TextEditingController();

List<String> _answers = [];

  final List<String> _questions = [
    "1. How was your experience in this class with your classmates for the past year?",

    "2. How was your experience in this class with your teachers for the past year?",

    "3. What has been the highlight throughout the year?",

    "4. Would you like to stay in this class? Why or why not?",

    "5. What do you wish the class could do differently?",
  ];

  void _submitAnswer() {

    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please write your answer."),
        ),
      );
      return;
    }

    _answers.add(_answerController.text);

    _answerController.clear();

    setState(() {

      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else {
        _submitFormToDatabase();
      }
    });
  }

  Future<void> _submitFormToDatabase() async {
    setState(() {
      _isSavingToDatabase = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    // 🔥 STEP 5 KEY: push into fake database
    FakeDatabase.students.add(
      StudentRecord(
        id: "S${FakeDatabase.students.length + 1}",
        name: "Student ${FakeDatabase.students.length + 1}",
        hasSubmittedForm: true,
        evaluationScore: _calculateScoreFromAnswers(),
        detailedAnswers: _answers.map((e) => _convertAnswerToScore(e)).toList(),
      ),
    );

    setState(() {
      _isSavingToDatabase = false;
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  int _calculateScoreFromAnswers() {
    return _answers.length * 5;
  }

  int _convertAnswerToScore(String answer) {
    if (answer.length > 200) return 5;
    if (answer.length > 100) return 4;
    if (answer.length > 50) return 3;
    if (answer.length > 20) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text("End of Year Evaluation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isSavingToDatabase 
            ? _buildSavingScreen() 
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
                  Expanded(
                    child: _buildQuestionPage(),
                  ),
                ],
              ),
        ),
      ),
    );
  }

  // A custom saving screen shown when student completes the form
  Widget _buildSavingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.deepPurple),
          SizedBox(height: 20),
          Text(
            'Encrypting & Auto-saving to Database...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

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