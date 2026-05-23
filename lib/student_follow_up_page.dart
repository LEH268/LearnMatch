import 'package:flutter/material.dart';

class StudentFollowUpPage extends StatefulWidget {
  const StudentFollowUpPage({Key? key}) : super(key: key);

  @override
  _StudentFollowUpPageState createState() => _StudentFollowUpPageState();
}

class _StudentFollowUpPageState extends State<StudentFollowUpPage> {
  // 1. Term Grades State
  List<double> _termGrades = [];
  final TextEditingController _gradeController = TextEditingController();

  // 2. Database Sync State (Simulating fetching student's self-evaluation)
  bool _isSyncing = false;
  bool _isDataFetched = false;
  int _fetchedStudentEvalScore = 0; // Max 25 points from the student link

  // 3. Teacher Comment State
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

  // Simulate fetching data from Firebase/Backend
  Future<void> _fetchStudentEvaluation() async {
    setState(() {
      _isSyncing = true;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isSyncing = false;
      _isDataFetched = true;
      _fetchedStudentEvalScore = 22; // Simulated score retrieved from database (out of 25)
    });
  }

  // Simulated AI Logic for Teacher's Comment
  String _simulateAIAnalysis(String comment) {
    if (comment.isEmpty) return "No comment provided for AI analysis.";
    
    String lowerComment = comment.toLowerCase();
    
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
        const SnackBar(content: Text('Please add at least one term grade.')),
      );
      return;
    }
    if (!_isDataFetched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sync the student\'s self-evaluation data first.')),
      );
      return;
    }

    double avgGrade = _calculateAverageGrade();
    String gradeLetter = _getGradeLetter(avgGrade);
    String aiAnalysis = _simulateAIAnalysis(_teacherCommentController.text);

    // Generate Final Recommendation (Max Grade: 100, Max Eval: 25)
    String finalRecommendation = "";
    if (avgGrade >= 75 && _fetchedStudentEvalScore >= 20) {
      finalRecommendation = "The student is highly suitable for this class. They are excelling academically and feel extremely comfortable in this environment. No class change is needed.";
    } else if (avgGrade < 60 || _fetchedStudentEvalScore < 12) {
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
          evaluationScore: _fetchedStudentEvalScore,
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
            const Text('1. Term Grades Input', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

            // 2. Student Evaluation Data Fetch Section
            const Text('2. Student Self-Evaluation Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text('Sync the feedback form submitted by the student.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in, color: Colors.deepPurple, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Form Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _isDataFetched ? 'Data Synced Successfully' : 'Not Synced Yet',
                          style: TextStyle(color: _isDataFetched ? Colors.green : Colors.redAccent),
                        ),
                        if (_isDataFetched)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Score Received: $_fetchedStudentEvalScore / 25',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!_isDataFetched)
                    ElevatedButton.icon(
                      onPressed: _isSyncing ? null : _fetchStudentEvaluation,
                      icon: _isSyncing 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : const Icon(Icons.sync),
                      label: Text(_isSyncing ? 'Syncing...' : 'Fetch Data'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                    ),
                ],
              ),
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
                  foregroundColor: Colors.white,
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
  final int evaluationScore;
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
                    Text('Total Satisfaction Score: $evaluationScore / 25', style: const TextStyle(fontSize: 16)),
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