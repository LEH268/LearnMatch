import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// 1. Data Model (Simulating Database Records)
// ==========================================
class StudentRecord {
  final String id;
  final String name;
  final bool hasSubmittedForm;
  final int? evaluationScore;
  final List<int>? detailedAnswers;
  final String className; // NEW: class the student belongs to

  StudentRecord({
    required this.id,
    required this.name,
    required this.hasSubmittedForm,
    this.evaluationScore,
    this.detailedAnswers,
    this.className = '',
  });
}

// ==========================================
// 2. Student List & Filter Page (Entry Point)
// ==========================================
class StudentFollowUpPage extends StatefulWidget {
  const StudentFollowUpPage({Key? key}) : super(key: key);

  @override
  _StudentFollowUpPageState createState() => _StudentFollowUpPageState();
}

class _StudentFollowUpPageState extends State<StudentFollowUpPage> {

  final String evaluationLink =
    "https://learnmatch-2b5c4.web.app/#/student-evaluation";

  // Simulated database
  final List<StudentRecord> _allStudents = [
    StudentRecord(id: 'S01', name: 'Alice Smith', hasSubmittedForm: true, evaluationScore: 23, detailedAnswers: [5, 4, 5, 4, 5], className: 'Class V'),
    StudentRecord(id: 'S02', name: 'Bob Johnson', hasSubmittedForm: false, className: 'Class A'),
    StudentRecord(id: 'S03', name: 'Charlie Brown', hasSubmittedForm: true, evaluationScore: 15, detailedAnswers: [3, 3, 3, 3, 3], className: 'Class V'),
    StudentRecord(id: 'S04', name: 'Diana Prince', hasSubmittedForm: true, evaluationScore: 20, detailedAnswers: [4, 4, 5, 3, 4], className: 'Class R'),
    StudentRecord(id: 'S05', name: 'Ethan Hunt', hasSubmittedForm: false, className: 'Class K'),
    StudentRecord(id: 'S06', name: 'Fiona Green', hasSubmittedForm: true, evaluationScore: 18, detailedAnswers: [4, 3, 4, 3, 4], className: 'Class A'),
    StudentRecord(id: 'S07', name: 'George King', hasSubmittedForm: false, className: 'Class R'),
    StudentRecord(id: 'S08', name: 'Hannah Lee', hasSubmittedForm: true, evaluationScore: 22, detailedAnswers: [5, 4, 4, 5, 4], className: 'Class K'),
  ];

  List<StudentRecord> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();

  // ── Filter state ─────────────────────────────
  String _selectedClass = 'All Classes';
  String _selectedStatus = 'All'; // All | Submitted | Pending
  static const int _pageSize = 5;
  int _currentPage = 0;

  List<String> get _classOptions {
    final classes = _allStudents.map((s) => s.className).toSet().toList()..sort();
    return ['All Classes', ...classes];
  }

  @override
  void initState() {
    super.initState();
    _applyFilters();
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _currentPage = 0;
      _filteredStudents = _allStudents.where((s) {
        final matchName = query.isEmpty || s.name.toLowerCase().contains(query);
        final matchClass = _selectedClass == 'All Classes' || s.className == _selectedClass;
        final matchStatus = _selectedStatus == 'All' ||
            (_selectedStatus == 'Submitted' && s.hasSubmittedForm) ||
            (_selectedStatus == 'Pending' && !s.hasSubmittedForm);
        return matchName && matchClass && matchStatus;
      }).toList();
    });
  }

  List<StudentRecord> get _pagedStudents {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, _filteredStudents.length);
    if (start >= _filteredStudents.length) return [];
    return _filteredStudents.sublist(start, end);
  }

  int get _totalPages => (_filteredStudents.length / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text('Student Reports', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search Bar ────────────────────────
            TextField(
              controller: _searchController,
              onChanged: (_) => _applyFilters(),
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter Row ────────────────────────
            Row(
              children: [
                // Class filter dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueAccent),
                      style: const TextStyle(color: Colors.black87, fontSize: 13),
                      items: _classOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          _selectedClass = v;
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Status filter chips
                ...[('All', Colors.blueGrey), ('Submitted', Colors.green), ('Pending', Colors.orange)]
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(entry.$1, style: const TextStyle(fontSize: 12)),
                            selected: _selectedStatus == entry.$1,
                            selectedColor: entry.$2.withOpacity(0.2),
                            onSelected: (_) {
                              _selectedStatus = entry.$1;
                              _applyFilters();
                            },
                            labelStyle: TextStyle(
                              color: _selectedStatus == entry.$1 ? entry.$2 : Colors.blueGrey,
                              fontWeight: _selectedStatus == entry.$1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        )),
              ],
            ),

            const SizedBox(height: 16),

            // ── Evaluation Link Card ─────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: Colors.deepPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      evaluationLink,
                      style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: evaluationLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Evaluation link copied!")),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Result count & class badge ─────────
            Row(
              children: [
                Text(
                  'Showing ${_pagedStudents.length} of ${_filteredStudents.length} reports',
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (_selectedClass != 'All Classes')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _selectedClass,
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Student List ──────────────────────
            Expanded(
              child: _filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('No students found',
                              style: TextStyle(color: Colors.blueGrey, fontSize: 15)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _pagedStudents.length,
                            itemBuilder: (context, index) {
                              final student = _pagedStudents[index];
                              return Card(
                                elevation: 1.5,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Colors.blueAccent.withOpacity(0.15),
                                    child: Text(student.name[0],
                                        style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  title: Text(student.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (student.className.isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(right: 8),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent.withOpacity(0.10),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(student.className,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blueAccent,
                                                      fontWeight: FontWeight.bold)),
                                            ),
                                          Text(
                                            student.hasSubmittedForm
                                                ? 'Submitted ✅'
                                                : 'Pending ⏳',
                                            style: TextStyle(
                                              color: student.hasSubmittedForm
                                                  ? Colors.green
                                                  : Colors.orange,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 14, color: Colors.grey),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            StudentDetailPage(student: student),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        // ── Pagination ────────────────
                        if (_totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded),
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                  color: Colors.blueAccent,
                                ),
                                ...List.generate(_totalPages, (i) => GestureDetector(
                                  onTap: () => setState(() => _currentPage = i),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _currentPage == i
                                          ? Colors.blueAccent
                                          : Colors.blueAccent.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text('${i + 1}',
                                          style: TextStyle(
                                            color: _currentPage == i
                                                ? Colors.white
                                                : Colors.blueAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          )),
                                    ),
                                  ),
                                )),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded),
                                  onPressed: _currentPage < _totalPages - 1
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 3. Specific Student Detail & Follow-up Page
// ==========================================
class StudentDetailPage extends StatefulWidget {
  final StudentRecord student;
  const StudentDetailPage({Key? key, required this.student}) : super(key: key);

  @override
  _StudentDetailPageState createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  List<double> _termGrades = [];
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _teacherCommentController = TextEditingController();

  bool _isSyncing = false;
  bool _isDataFetched = false;
  int _fetchedStudentEvalScore = 0;
  List<int> _fetchedDetailedAnswers = []; // To store the specific 5 answers

  final List<String> _formQuestions = [
    'Part 1: Class Comfort & Environment',
    'Part 2: Understanding of Materials',
    'Part 3: Engagement & Participation',
    'Part 4: Learning Pace',
    'Part 5: Overall Growth'
  ];

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
    return _termGrades.fold(0.0, (p, c) => p + c) / _termGrades.length;
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

  Future<void> _fetchStudentEvaluation() async {
    setState(() { _isSyncing = true; });
    
    // Simulating database fetch delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isSyncing = false;
      if (widget.student.hasSubmittedForm) {
        _isDataFetched = true;
        _fetchedStudentEvalScore = widget.student.evaluationScore ?? 0;
        _fetchedDetailedAnswers = widget.student.detailedAnswers ?? [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully synced data for ${widget.student.name}.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.student.name} has not submitted the form yet.'), backgroundColor: Colors.redAccent),
        );
      }
    });
  }

  // Show bottom sheet to display what the student actually filled in
  void _showStudentFormDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.student.name}\'s Form Details', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              ...List.generate(_formQuestions.length, (index) {
                int score = _fetchedDetailedAnswers.isNotEmpty ? _fetchedDetailedAnswers[index] : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formQuestions[index], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < score ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text('$score / 5', style: TextStyle(color: Colors.grey.shade700)),
                        ],
                      )
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  String _simulateAIAnalysis(String comment) {
    if (comment.isEmpty) return "No teacher comment provided for AI analysis.";
    String lowerComment = comment.toLowerCase();
    
    if ((lowerComment.contains('excellent') || lowerComment.contains('good') || lowerComment.contains('great')) && 
        !(lowerComment.contains('struggle') || lowerComment.contains('poor'))) {
      return "AI Conclusion: Positive learning attitude. Grasps concepts easily.";
    } else if (lowerComment.contains('struggle') || lowerComment.contains('hard') || lowerComment.contains('poor')) {
      return "AI Conclusion: Facing academic challenges. Requires pacing adjustments.";
    } else if (lowerComment.contains('improve') || lowerComment.contains('better')) {
      return "AI Conclusion: Showing gradual progress and positive development.";
    }
    return "AI Conclusion: Maintains a standard and steady performance.";
  }

  void _generateReport() {
    if (_termGrades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one term grade.')));
      return;
    }
    if (!_isDataFetched && widget.student.hasSubmittedForm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sync the student\'s data first.')));
      return;
    }

    double avgGrade = _calculateAverageGrade();
    String gradeLetter = _getGradeLetter(avgGrade);
    String aiAnalysis = _simulateAIAnalysis(_teacherCommentController.text);

    String finalRecommendation = "";
    if (avgGrade >= 75 && _fetchedStudentEvalScore >= 20) {
      finalRecommendation = "${widget.student.name} is excelling and comfortable. No class change needed.";
    } else if (avgGrade < 60 || _fetchedStudentEvalScore < 12) {
      finalRecommendation = "${widget.student.name} is struggling. Consider re-streaming or dedicated tutoring.";
    } else {
      finalRecommendation = "${widget.student.name} fits reasonably well. Standard monitoring advised.";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YearlyReportPage(
          studentName: widget.student.name,
          averageGrade: avgGrade,
          gradeLetter: gradeLetter,
          evaluationScore: _fetchedStudentEvalScore,
          hasEvalData: _isDataFetched,
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
        title: Text('${widget.student.name}\'s Profile'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Term Grades Input
            const Text('1. Term Grades Input', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gradeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Enter Grade (0-100)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _addGrade, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: _termGrades.asMap().entries.map((entry) {
                return Chip(
                  label: Text('T${entry.key + 1}: ${entry.value}'),
                  onDeleted: () => setState(() => _termGrades.removeAt(entry.key)),
                );
              }).toList(),
            ),
            const Divider(height: 40, thickness: 1),

            // 2. Student Database Sync
            const Text('2. Sync Student Response', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Pull data from the evaluation link submitted by the student.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_sync, color: Colors.deepPurple, size: 30),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${_isDataFetched ? 'Synced' : (widget.student.hasSubmittedForm ? 'Ready to Sync' : 'Not Submitted')}'),
                            if (_isDataFetched) Text('Score: $_fetchedStudentEvalScore / 25', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ],
                        ),
                      ),
                      if (!_isDataFetched)
                        ElevatedButton(
                          onPressed: _isSyncing ? null : _fetchStudentEvaluation,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                          child: _isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Fetch'),
                        ),
                    ],
                  ),
          
                  if (_isDataFetched) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showStudentFormDetails,
                        icon: const Icon(Icons.visibility, color: Colors.deepPurple),
                        label: const Text('View Student\'s Submitted Form', style: TextStyle(color: Colors.deepPurple)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.deepPurple),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                        ),
                      ),
                    )
                  ]
                ],
              ),
            ),
            const Divider(height: 40, thickness: 1),

            // 3. Teacher Comment
            const Text('3. Teacher\'s Observation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _teacherCommentController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Write observation for AI analysis...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            // Generate Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _generateReport,
                icon: const Icon(Icons.analytics),
                label: const Text('Generate Final Report'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 30), // Added bottom padding
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. Yearly Report Page (Generated Output)
// ==========================================
class YearlyReportPage extends StatelessWidget {
  final String studentName;
  final double averageGrade;
  final String gradeLetter;
  final int evaluationScore;
  final bool hasEvalData;
  final String aiAnalysis;
  final String recommendation;

  const YearlyReportPage({
    Key? key,
    required this.studentName,
    required this.averageGrade,
    required this.gradeLetter,
    required this.evaluationScore,
    required this.hasEvalData,
    required this.aiAnalysis,
    required this.recommendation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$studentName\'s Report'), backgroundColor: Colors.deepPurple),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.school, size: 60, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text('AI Re-streaming Report\n$studentName', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            Card(
              elevation: 3,
              child: ListTile(
                title: const Text('Academic Performance', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                subtitle: Text('Average Score: ${averageGrade.toStringAsFixed(1)}/100\nFinal Grade: $gradeLetter'),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 3,
              child: ListTile(
                title: const Text('Student Self-Evaluation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                subtitle: Text(hasEvalData ? 'Satisfaction Score: $evaluationScore / 25' : 'No data submitted by student.'),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 3,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Comment Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Text(aiAnalysis, style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              elevation: 3,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Final Placement Recommendation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 8),
                    Text(recommendation, style: const TextStyle(fontWeight: FontWeight.w500)),
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