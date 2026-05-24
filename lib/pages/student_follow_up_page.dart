import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../services/firestore_service.dart';

// ==========================================
// 1. Data Model 
// ==========================================
class StudentRecord {
  final String id;
  final String name;
  final bool hasSubmittedForm;
  final int? evaluationScore;
  final List<int>? detailedAnswers;
  final List<String>? writtenAnswers;
  final String className;

  StudentRecord({
    required this.id,
    required this.name,
    required this.hasSubmittedForm,
    this.evaluationScore,
    this.detailedAnswers,
    this.writtenAnswers,
    this.className = 'No Class',
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

  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<QuerySnapshot>? _studentsSubscription;

  List<StudentRecord> _allStudents = [];
  List<StudentRecord> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // ── Filter state ─────────────────────────────
  String _selectedClass = 'All Classes';
  String _selectedStatus = 'All'; // All | Submitted | Pending
  static const int _pageSize = 5;
  int _currentPage = 0;

  List<String> get _classOptions {
    final classes = _allStudents
        .map((s) => s.className)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All Classes', ...classes];
  }

  @override
  void initState() {
    super.initState();
    _fetchStudentsFromFirebase();
  }

  void _fetchStudentsFromFirebase() {
    _studentsSubscription = _firestoreService.getStudentsStream().listen((snapshot) {
      final students = snapshot.docs.map((doc) {
        
        final data = doc.data() as Map<String, dynamic>? ?? {};

        String parsedClassName = data['className']?.toString().trim() ?? '';
        if (parsedClassName.isEmpty) {
          parsedClassName = 'No Class'; 
        }

        return StudentRecord(
          id: doc.id,
          name: data['name']?.toString() ?? 'Unknown Student',
          className: parsedClassName,
          hasSubmittedForm: data['hasSubmittedForm'] == true || data['hasSubmittedForm'] == 'true',
          evaluationScore: int.tryParse(data['evaluationScore']?.toString() ?? ''),
          detailedAnswers: (data['detailedAnswers'] as List<dynamic>?)
              ?.map((e) => int.tryParse(e.toString()) ?? 0)
              .toList(),
          writtenAnswers: (data['writtenAnswers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
        );
      }).toList();

      setState(() {
        _allStudents = students;
        _isLoading = false;

        if (_selectedClass != 'All Classes' && !_classOptions.contains(_selectedClass)) {
          _selectedClass = 'All Classes';
        }

        _applyFilters();
      });
    }, onError: (error) {
      print("🔴 Firebase Error: $error");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _studentsSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
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
                      items: _classOptions
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
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
                              fontWeight: _selectedStatus == entry.$1 ? FontWeight.bold : FontWeight.normal,
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
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Student List ──────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : _filteredStudents.isEmpty
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueAccent.withOpacity(0.15),
                                        child: Text(
                                            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                                color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                      ),
                                      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              if (student.className.isNotEmpty)
                                                Container(
                                                  margin: const EdgeInsets.only(right: 8),
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                                                student.hasSubmittedForm ? 'Submitted ✅' : 'Pending ⏳',
                                                style: TextStyle(
                                                  color: student.hasSubmittedForm ? Colors.green : Colors.orange,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => StudentDetailPage(student: student),
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
                                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                      color: Colors.blueAccent,
                                    ),
                                    ...List.generate(
                                        _totalPages,
                                        (i) => GestureDetector(
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
                                                        color: _currentPage == i ? Colors.white : Colors.blueAccent,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      )),
                                                ),
                                              ),
                                            )),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded),
                                      onPressed:
                                          _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
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
  String _selectedYear = 'Year 1';
  final List<String> _yearOptions = [
    'Year 1', 'Year 2', 'Year 3', 'Year 4', 'Year 5', 'Year 6',
    'Form 1', 'Form 2', 'Form 3', 'Form 4', 'Form 5'
  ];
  final TextEditingController _firstHalfController = TextEditingController();
  final TextEditingController _secondHalfController = TextEditingController();

  final TextEditingController _teacherCommentController = TextEditingController();

  bool _isSyncing = false;
  bool _isDataFetched = false;
  int _fetchedStudentEvalScore = 0;
  List<int> _fetchedDetailedAnswers = [];
  List<String> _fetchedWrittenAnswers = [];
  bool _isGeneratingAI = false;
  
  final aiModel = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: '', 
  );

  final List<String> _formQuestions = [
    'Part 1: Class Comfort & Environment',
    'Part 2: Understanding of Materials',
    'Part 3: Engagement & Participation',
    'Part 4: Learning Pace',
    'Part 5: Overall Growth'
  ];

  double _calculateAverageGrade() {
    double firstHalf = double.tryParse(_firstHalfController.text) ?? -1.0;
    double secondHalf = double.tryParse(_secondHalfController.text) ?? -1.0;

    if (firstHalf >= 0 && secondHalf >= 0) {
      return (firstHalf + secondHalf) / 2;
    } else if (firstHalf >= 0) {
      return firstHalf; 
    } else if (secondHalf >= 0) {
      return secondHalf; 
    }
    return 0.0;
  }

  String _getGradeLetter(double average) {
    if (_firstHalfController.text.isEmpty && _secondHalfController.text.isEmpty) return 'N/A';
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
    setState(() {
      _isSyncing = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSyncing = false;
      if (widget.student.hasSubmittedForm) {
        _isDataFetched = true;
        _fetchedStudentEvalScore = widget.student.evaluationScore ?? 0;
        _fetchedDetailedAnswers = widget.student.detailedAnswers ?? [];
        _fetchedWrittenAnswers = widget.student.writtenAnswers ?? [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Successfully synced data for ${widget.student.name}.'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${widget.student.name} has not submitted the form yet.'),
              backgroundColor: Colors.redAccent),
        );
      }
    });
  }

  void _showStudentFormDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text("${widget.student.name}'s Submission",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI Sentiment Score: $_fetchedStudentEvalScore / 25',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _formQuestions.length,
                      itemBuilder: (_, index) {
                        final int aiScore =
                            (_fetchedDetailedAnswers.length > index)
                                ? _fetchedDetailedAnswers[index]
                                : 0;
                        final String answer =
                            (_fetchedWrittenAnswers.length > index)
                                ? _fetchedWrittenAnswers[index]
                                : '(no response)';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(_formQuestions[index],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 6),
                              // Student's actual written answer
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius:
                                      BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.grey.shade200),
                                ),
                                child: Text(answer,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4)),
                              ),
                              const SizedBox(height: 8),
                              // AI score bar
                              Row(
                                children: [
                                  const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 14,
                                      color: Colors.deepPurple),
                                  const SizedBox(width: 6),
                                  const Text('AI Score: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueGrey,
                                          fontWeight:
                                              FontWeight.w600)),
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: aiScore / 5,
                                        backgroundColor: Colors
                                            .deepPurple
                                            .withOpacity(0.12),
                                        color: _scoreColor(aiScore),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('$aiScore / 5',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              _scoreColor(aiScore))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white),
                      child: const Text('Close'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _scoreColor(int score) {
    if (score >= 4) return Colors.green;
    if (score == 3) return Colors.amber.shade700;
    return Colors.redAccent;
  }

  // AI analysis and recommendation generation
  Future<void> _generateReport() async {
    
    if (_firstHalfController.text.isEmpty && _secondHalfController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter at least First Half or Second Half grade.')));
      return;
    }
    if (!_isDataFetched && widget.student.hasSubmittedForm) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sync the student\'s data first.')));
      return;
    }

    final double avgGrade = _calculateAverageGrade();          // 0–100
    final String gradeLetter = _getGradeLetter(avgGrade);
    final String teacherComment = _teacherCommentController.text.trim();

    setState(() => _isGeneratingAI = true);

    try {
      // ───────────────────────────────────────────────
      // STEP 1. AI scores the teacher's written comment
      // (returns 0–100 score + a brief analysis)
      // ───────────────────────────────────────────────
      int teacherAiScore = 50; // neutral default if AI fails / no comment
      String teacherAnalysis =
          'No specific observation provided by the teacher.';

      if (teacherComment.isNotEmpty) {
        try {
          final teacherPrompt = """
You are an Educational AI evaluating how well a student is fitting into their current class, based on the teacher's written observation.

Teacher's observation: "$teacherComment"

Score this observation from 0 to 100:
- 80-100: very positive (student thriving, engaged, doing well)
- 50-79:  acceptable (some concerns but mostly fine)
- 20-49:  concerning (struggling, disengaged, or behavioural issues)
- 0-19:   serious problems

Format your response EXACTLY like this:
Score: <number 0-100>
Analysis: <2-sentence summary of what the teacher's observation tells us about the student's fit>
""";

          final tResp =
              await aiModel.generateContent([Content.text(teacherPrompt)]);
          final tText = (tResp.text ?? '').trim();
          final scoreMatch =
              RegExp(r'Score:\s*(\d{1,3})').firstMatch(tText);
          if (scoreMatch != null) {
            teacherAiScore =
                int.parse(scoreMatch.group(1)!).clamp(0, 100);
          }
          final analysisMatch =
              RegExp(r'Analysis:\s*(.+)', dotAll: true).firstMatch(tText);
          if (analysisMatch != null) {
            teacherAnalysis = analysisMatch.group(1)!.trim();
          }
        } catch (_) {
          teacherAnalysis =
              "AI could not analyse the teacher's observation. Comment: $teacherComment";
        }
      }

      // ───────────────────────────────────────────────
      // STEP 2. Convert the 3 source scores onto a 0-100
      // scale so they can be combined fairly:
      //   - Academic grade:      already 0-100
      //   - Student AI score:    0-25  →  ×4 to get 0-100
      //   - Teacher AI score:    already 0-100
      // ───────────────────────────────────────────────
      final double studentAiPct =
          (_fetchedStudentEvalScore / 25.0) * 100;
      final double teacherAiPct = teacherAiScore.toDouble();
      final double academicPct = avgGrade;

      // Weighted blend (tweak these if you want a different bias).
      // Equal-ish weight: academic 0.40, student feeling 0.30, teacher 0.30.
      final double fitScore = (academicPct * 0.40 +
              studentAiPct * 0.30 +
              teacherAiPct * 0.30)
          .clamp(0, 100);

      // ───────────────────────────────────────────────
      // STEP 3. Ask AI for a final combined recommendation
      // grounded in all three numbers
      // ───────────────────────────────────────────────
      String finalAnalysis = teacherAnalysis;
      String finalRecommendation = '';

      try {
        final finalPrompt = """
You are an educational AI helping a teacher decide whether a student fits well in their current class for next academic year.

Three indicators:
1. Academic average:         ${avgGrade.toStringAsFixed(1)} / 100  ($gradeLetter)
2. Student self-evaluation:  $_fetchedStudentEvalScore / 25  (AI-scored from their written reflections)
3. Teacher observation:      $teacherAiScore / 100  (AI-scored from teacher comment)

Combined fit score: ${fitScore.toStringAsFixed(1)} / 100

Decision rules:
- 75+: Student is a great fit. Recommend staying in current class.
- 55-74: Acceptable fit but watch certain areas. Recommend staying with adjustments.
- 35-54: Mismatched. Recommend re-streaming to a different class pace or learning style.
- Below 35: Serious mismatch. Recommend intervention (tutoring, counselling, or class change).

Output EXACTLY like this:
Analysis: <2-sentence summary that connects the three indicators>
Recommendation: <1-sentence clear action recommendation>
""";

        final fResp =
            await aiModel.generateContent([Content.text(finalPrompt)]);
        final fText = (fResp.text ?? '').trim();

        if (fText.contains('Analysis:') &&
            fText.contains('Recommendation:')) {
          final parts = fText.split('Recommendation:');
          finalAnalysis =
              parts[0].replaceAll('Analysis:', '').trim();
          finalRecommendation = parts[1].trim();
        } else {
          finalAnalysis = fText;
          finalRecommendation =
              _ruleBasedRecommendation(fitScore);
        }
      } catch (_) {
        // AI failed → fall back to rule-based recommendation
        finalRecommendation = _ruleBasedRecommendation(fitScore);
      }

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => YearlyReportPage(
              studentName: widget.student.name,
              academicYear: _selectedYear,
              firstHalfGrade: double.tryParse(_firstHalfController.text),
              secondHalfGrade: double.tryParse(_secondHalfController.text),
              averageGrade: avgGrade,
              gradeLetter: gradeLetter,
              evaluationScore: _fetchedStudentEvalScore,
              hasEvalData: _isDataFetched,
              teacherAiScore: teacherAiScore,
              teacherComment: teacherComment,
              fitScore: fitScore,
              aiAnalysis: finalAnalysis,
              recommendation: finalRecommendation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI Generation Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  String _ruleBasedRecommendation(double fitScore) {
    if (fitScore >= 75) {
      return 'Student is fitting well in this class — recommend staying.';
    }
    if (fitScore >= 55) {
      return 'Acceptable fit. Continue monitoring but no class change required.';
    }
    if (fitScore >= 35) {
      return 'Mismatch detected. Consider re-streaming to a different class.';
    }
    return 'Serious fit issue — intervention recommended (tutoring or class change).';
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
            const Text('1. Academic Performance Input', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Year Dropdown
            DropdownButtonFormField<String>(
              value: _selectedYear,
              items: _yearOptions.map((year) => DropdownMenuItem(value: year, child: Text(year))).toList(),
              onChanged: (val) => setState(() => _selectedYear = val!),
              decoration: const InputDecoration(labelText: 'Academic Year', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // First Half and Second Half Grades
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstHalfController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'First Half Year (0-100)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _secondHalfController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Second Half Year (0-100)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('* Leave blank if the half-year grade is not available yet.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Divider(height: 40, thickness: 1),

            // 2. Student Database Sync
            const Text('2. Sync Student Response', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Pull data from the evaluation link submitted by the student. (Matches by ID/Name)',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                            Text(
                                'Status: ${_isDataFetched ? 'Synced' : (widget.student.hasSubmittedForm ? 'Ready to Sync' : 'Not Submitted')}'),
                            if (_isDataFetched)
                              Text('Score: $_fetchedStudentEvalScore / 25',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ],
                        ),
                      ),
                      if (!_isDataFetched)
                        ElevatedButton(
                          onPressed: _isSyncing ? null : _fetchStudentEvaluation,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                          child: _isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Fetch'),
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
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
              decoration: const InputDecoration(
                  hintText: 'Write observation for AI analysis...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),

            // Generate Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isGeneratingAI ? null : _generateReport, // <-- 加上防御机制
                icon: _isGeneratingAI 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Icon(Icons.analytics),
                label: Text(_isGeneratingAI ? 'AI is thinking...' : 'Generate Final Report'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
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
  final String academicYear;
  final double? firstHalfGrade;
  final double? secondHalfGrade;
  final double averageGrade;
  final String gradeLetter;
  final int evaluationScore;       // student AI score 0-25
  final bool hasEvalData;
  final int teacherAiScore;        // teacher AI score 0-100
  final String teacherComment;
  final double fitScore;           // combined 0-100
  final String aiAnalysis;
  final String recommendation;

  const YearlyReportPage({
    Key? key,
    required this.studentName,
    required this.academicYear,
    this.firstHalfGrade,
    this.secondHalfGrade,
    required this.averageGrade,
    required this.gradeLetter,
    required this.evaluationScore,
    required this.hasEvalData,
    required this.teacherAiScore,
    required this.teacherComment,
    required this.fitScore,
    required this.aiAnalysis,
    required this.recommendation,
  }) : super(key: key);

  Color _fitColor() {
    if (fitScore >= 75) return Colors.green;
    if (fitScore >= 55) return Colors.amber.shade700;
    if (fitScore >= 35) return Colors.orange;
    return Colors.redAccent;
  }

  String _fitVerdict() {
    if (fitScore >= 75) return 'Great fit';
    if (fitScore >= 55) return 'Acceptable fit';
    if (fitScore >= 35) return 'Mismatch';
    return 'Serious mismatch';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('$studentName\'s Report'),
          backgroundColor: Colors.deepPurple),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.school, size: 60, color: Colors.deepPurple),
            const SizedBox(height: 10),
            Text('AI Re-streaming Report\n$studentName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // ── COMBINED FIT SCORE (the headline) ──
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      _fitColor().withOpacity(0.18),
                      _fitColor().withOpacity(0.04),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    const Text('Class Fit Score',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text('${fitScore.toStringAsFixed(1)} / 100',
                        style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: _fitColor())),
                    const SizedBox(height: 4),
                    Text(_fitVerdict(),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _fitColor())),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: fitScore / 100,
                        backgroundColor: _fitColor().withOpacity(0.15),
                        color: _fitColor(),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Composed of  Academic 40% • Student 30% • Teacher 30%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 3 component scores ──
            _scoreCard(
              icon: Icons.menu_book_rounded,
              color: Colors.blue,
              title: 'Academic Performance',
              valueLabel: '${averageGrade.toStringAsFixed(1)} / 100',
              gradeLabel: gradeLetter,
              progress: averageGrade / 100,
              subtitle:
                  '$academicYear  •  H1: ${firstHalfGrade != null ? firstHalfGrade!.toStringAsFixed(1) : 'N/A'}  •  H2: ${secondHalfGrade != null ? secondHalfGrade!.toStringAsFixed(1) : 'N/A'}',
            ),
            const SizedBox(height: 10),
            _scoreCard(
              icon: Icons.psychology_rounded,
              color: Colors.deepPurple,
              title: 'Student AI Evaluation',
              valueLabel: hasEvalData
                  ? '$evaluationScore / 25'
                  : 'Not Submitted',
              gradeLabel: hasEvalData
                  ? '${((evaluationScore / 25) * 100).round()}%'
                  : '',
              progress: hasEvalData ? evaluationScore / 25 : 0,
              subtitle:
                  'AI scored the student\'s written reflections on classmates, teachers, and growth.',
            ),
            const SizedBox(height: 10),
            _scoreCard(
              icon: Icons.rate_review_rounded,
              color: Colors.teal,
              title: 'Teacher AI Evaluation',
              valueLabel: '$teacherAiScore / 100',
              gradeLabel: '',
              progress: teacherAiScore / 100,
              subtitle: teacherComment.isEmpty
                  ? 'No teacher observation was provided.'
                  : '"${teacherComment.length > 90 ? "${teacherComment.substring(0, 90)}…" : teacherComment}"',
            ),
            const SizedBox(height: 16),

            // ── AI analysis ──
            Card(
              elevation: 3,
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Combined Analysis',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent)),
                    const SizedBox(height: 8),
                    Text(aiAnalysis,
                        style:
                            const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Final recommendation ──
            Card(
              elevation: 3,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Final Placement Recommendation',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    const SizedBox(height: 8),
                    Text(recommendation,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, height: 1.5)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreCard({
    required IconData icon,
    required Color color,
    required String title,
    required String valueLabel,
    required String gradeLabel,
    required double progress,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 15)),
                ),
                Text(valueLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
                if (gradeLabel.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(gradeLabel,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: color.withOpacity(0.12),
                color: color,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black54, height: 1.4)),
          ],
        ),
      ),
    );
  }
}