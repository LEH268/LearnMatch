import 'package:flutter/material.dart';

class StudentFollowUpPage extends StatefulWidget {
  const StudentFollowUpPage({Key? key}) : super(key: key);

  @override
  _StudentFollowUpPageState createState() => _StudentFollowUpPageState();
}

class _StudentFollowUpPageState extends State<StudentFollowUpPage> {
  // Term Grades State
  List<double> _termGrades = [];
  final TextEditingController _gradeController = TextEditingController();

  // Student Evaluation State (Score 1 to 5)
  Map<String, double> _evaluationScores = {
    'Class Comfort & Environment': 3,
    'Understanding of Materials': 3,
    'Engagement & Participation': 3,
    'Self-improvement Feeling': 3,
  };

  // Teacher Comment State
  final TextEditingController _teacherCommentController = TextEditingController();

  // Helper Methods for Grades
  void _addGrade() {
    if (_gradeController.text.isNotEmpty) {
      double? grade = double.tryParse(_gradeController.text);
      if (grade != null && grade >= 0 && grade <= 100) {
        setState(() {
          _termGrades.add(grade);
          _gradeController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid grade between 0 and 100')),
        );
      }
    }
  }

  double _calculateAverageGrade() {
    if (_termGrades.isEmpty) return 0.0;
    double sum = _termGrades.fold(0, (prev, element) => prev + element);
    return sum / _termGrades.length;
  }

  String _getGradeLetter(double average) {
    if (average == 0.0 && _termGrades.isEmpty) return 'N/A';
    if (average >= 90) return 'A+';
    if (average >= 80) return 'A';
    if (average >= 75) return 'A-';
    if (average >= 70) return 'B+';
    if (average >= 65) return 'B';
    if (average >= 60) return 'C';
    if (average >= 50) return 'D';
    return 'F';
  }

  double _calculateTotalEvaluationScore() {
    return _evaluationScores.values.fold(0, (prev, element) => prev + element);
  }

  // Simulated AI Logic for Teacher's Comment
  String _simulateAIAnalysis(String comment) {
    if (comment.isEmpty) return "No comment provided for AI analysis.";
    
    String lowerComment = comment.toLowerCase();
    
    // In a real application, you would send this to an AI API (e.g., Gemini).
    if ((lowerComment.contains('excellent') || lowerComment.contains('good') || lowerComment.contains('great')) && 
        !(lowerComment.contains('struggle') || lowerComment.contains('poor'))) {
      return "AI Conclusion: The student exhibits a highly positive learning attitude and grasps concepts easily.";
    } else if (lowerComment.contains('struggle') || lowerComment.contains('hard') || lowerComment.contains('poor')) {
      return "AI Conclusion: The student is currently facing academic challenges and requires extra attention or pacing adjustments.";
    } else if (lowerComment.contains('improve') || lowerComment.contains('better')) {
      return "AI Conclusion: The student is showing gradual progress and positive development over time.";
    }
    
    return "AI Conclusion: The student maintains a standard and steady performance in the class.";
  }

  void _generateReport() {
    if (_termGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one term grade before generating the report.')),
      );
      return;
    }

    double avgGrade = _calculateAverageGrade();
    String gradeLetter = _getGradeLetter(avgGrade);
    double totalEval = _calculateTotalEvaluationScore();
    String aiAnalysis = _simulateAIAnalysis(_teacherCommentController.text);

    // Generate Final Recommendation
    String finalRecommendation = "";
    if (avgGrade >= 75 && totalEval >= 15) {
      finalRecommendation = "The student is highly suitable for this class. They are excelling academically and feel comfortable in this environment. No class change is needed.";
    } else if (avgGrade < 60 || totalEval < 10) {
      finalRecommendation = "The student is struggling either academically or socially. It is highly recommended to consider transferring them to a different class format or providing dedicated tutoring.";
    } else {
      finalRecommendation = "The student fits reasonably well in this class. Standard monitoring is advised for the next year.";
    }

    // Navigate to the Report Page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YearlyReportPage(
          averageGrade: avgGrade,
          gradeLetter: gradeLetter,
          evaluationScore: totalEval,
          aiAnalysis: aiAnalysis,
          recommendation: finalRecommendation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Follow-up & Evaluation'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Term Grades Section
            const Text('1. Term Grades', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Enter Term Grade (0-100)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addGrade,
                  child: const Text('Add Grade'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _termGrades.asMap().entries.map((entry) {
                return Chip(
                  label: Text('Term ${entry.key + 1}: ${entry.value}'),
                  onDeleted: () {
                    setState(() {
                      _termGrades.removeAt(entry.key);
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(height: 30, thickness: 2),

            // 2. Student Evaluation Form Section
            const Text('2. End of Year Student Evaluation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Rate from 1 (Poor) to 5 (Excellent)', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ..._evaluationScores.keys.map((key) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _evaluationScores[key]!,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _evaluationScores[key]!.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        _evaluationScores[key] = value;
                      });
                    },
                  ),
                ],
              );
            }).toList(),
            Text(
              'Current Evaluation Score: ${_calculateTotalEvaluationScore().round()} / 20',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Divider(height: 40, thickness: 2),

            // 3. Teacher Comment Section
            const Text('3. Teacher\'s Yearly Observation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _teacherCommentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Write about the student\'s progress, attitude, and challenges over the year...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 4. Generate Report Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.analytics),
                label: const Text('Generate AI Yearly Report', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// Yearly Report Page (Generated Output)
// -------------------------------------------------------------------

class YearlyReportPage extends StatelessWidget {
  final double averageGrade;
  final String gradeLetter;
  final double evaluationScore;
  final String aiAnalysis;
  final String recommendation;

  const YearlyReportPage({
    Key? key,
    required this.averageGrade,
    required this.gradeLetter,
    required this.evaluationScore,
    required this.aiAnalysis,
    required this.recommendation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Yearly Report'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.school, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Final Student Report',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Academic Performance Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Academic Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 10),
                    Text('Average Score: ${averageGrade.toStringAsFixed(1)} / 100', style: const TextStyle(fontSize: 16)),
                    Text('Final Grade: $gradeLetter', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Student Self-Evaluation Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Student Self-Evaluation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 10),
                    Text('Total Satisfaction Score: ${evaluationScore.round()} / 20', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // AI Analysis Card
            Card(
              elevation: 4,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Teacher Comment Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 10),
                    Text(aiAnalysis, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // Final Conclusion / Recommendation Card
            Card(
              elevation: 4,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Final Recommendation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 10),
                    Text(recommendation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}