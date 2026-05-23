import 'package:flutter/material.dart';

class StudentEvaluationForm extends StatefulWidget {
  const StudentEvaluationForm({super.key});

  @override
  State<StudentEvaluationForm> createState() => _StudentEvaluationFormState();
}

class _StudentEvaluationFormState extends State<StudentEvaluationForm> {
  int _currentIndex = 0;
  int _totalScore = 0;
  bool _isSavingToDatabase = false; // State to show saving process

  final List<Map<String, dynamic>> _questions = [
    {
      'theme': 'Part 1: Class Comfort & Environment',
      'question': '1. How comfortable do you feel asking questions or sharing your thoughts in this class?',
      'options': [
        {'text': 'Very comfortable. I always share my thoughts.', 'score': 5},
        {'text': 'Mostly comfortable, but sometimes I hold back.', 'score': 4},
        {'text': 'I only speak if the teacher calls on me.', 'score': 3},
        {'text': 'I rarely speak, I feel a bit nervous.', 'score': 2},
        {'text': 'I never speak. I do not feel comfortable at all.', 'score': 1},
      ]
    },
    {
      'theme': 'Part 2: Understanding of Materials',
      'question': '2. How well do you feel you grasped the core concepts taught this year?',
      'options': [
        {'text': 'Mastered them easily. I could teach others.', 'score': 5},
        {'text': 'Understood most of it, just a few confusing parts.', 'score': 4},
        {'text': 'I needed extra help to understand the basics.', 'score': 3},
        {'text': 'I struggled often and fell behind.', 'score': 2},
        {'text': 'Completely lost. The material was too hard.', 'score': 1},
      ]
    },
    {
      'theme': 'Part 3: Engagement & Participation',
      'question': '3. How active were you during class discussions and group activities?',
      'options': [
        {'text': 'Always highly focused and active in groups.', 'score': 5},
        {'text': 'Usually focused, but sometimes got distracted.', 'score': 4},
        {'text': 'I just listened and let others do the group work.', 'score': 3},
        {'text': 'I was easily distracted by my phone or friends.', 'score': 2},
        {'text': 'I was completely disengaged and did not participate.', 'score': 1},
      ]
    },
    {
      'theme': 'Part 4: Learning Pace',
      'question': '4. Did you feel the pace of this class matched your learning speed?',
      'options': [
        {'text': 'Perfect pace. I learned smoothly.', 'score': 5},
        {'text': 'Slightly fast/slow, but totally manageable.', 'score': 4},
        {'text': 'Often too fast or too slow for me.', 'score': 3},
        {'text': 'Very hard to keep up. I felt stressed.', 'score': 2},
        {'text': 'Overwhelming. I couldn\'t follow at all.', 'score': 1},
      ]
    },
    {
      'theme': 'Part 5: Overall Growth',
      'question': '5. Overall, how would you rate your personal growth in this class this year?',
      'options': [
        {'text': 'Exceptional growth. I improved significantly.', 'score': 5},
        {'text': 'Solid improvement. I learned a lot.', 'score': 4},
        {'text': 'Stayed about the same. No big changes.', 'score': 3},
        {'text': 'Declined slightly. I lost motivation.', 'score': 2},
        {'text': 'Very disappointed. I did not grow at all.', 'score': 1},
      ]
    }
  ];

  void _answerQuestion(int score) {
    setState(() {
      _totalScore += score;
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
    final currentQ = _questions[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          currentQ['theme'],
          style: const TextStyle(fontSize: 14, color: Colors.blueGrey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          currentQ['question'],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 40),
        ...((currentQ['options'] as List).map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: () => _answerQuestion(opt['score']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(opt['text'], style: const TextStyle(fontSize: 16, height: 1.4)),
            ),
          );
        })),
      ],
    );
  }
}