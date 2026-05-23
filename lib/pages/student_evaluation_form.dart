import 'package:flutter/material.dart';

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

  // 模拟自动保存到云端数据库 (Firebase) 的过程
  Future<void> _submitFormToDatabase() async {
    setState(() {
      _isSavingToDatabase = true;
    });

    // TODO: In a real app, this is where you write to Firebase:
    // await FirebaseFirestore.instance.collection('evaluations').add({
    //   'studentId': currentUser.id,
    //   'score': _totalScore,
    //   'timestamp': FieldValue.serverTimestamp(),
    // });
    
    // Simulate network delay for saving
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSavingToDatabase = false;
    });

    // Show success dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text('Auto-Saved! 🎉', textAlign: TextAlign.center),
            ],
          ),
          content: const Text(
            'Your evaluation has been successfully uploaded to the school database. Your teacher can now sync it.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      );
    }
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