import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 请确保这里的路径正确指向你的 firestore_service.dart
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
  final String className;

  StudentRecord({
    required this.id,
    required this.name,
    required this.hasSubmittedForm,
    this.evaluationScore,
    this.detailedAnswers,
    this.className = 'No Class', // 默认给一个 'No Class' 防止空值错误
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

  // === Firebase 服务和数据流 ===
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

  // === 核心逻辑：从 Firebase 实时拉取所有数据（加入安全解析） ===
  void _fetchStudentsFromFirebase() {
    _studentsSubscription = _firestoreService.getStudentsStream().listen((snapshot) {
      final students = snapshot.docs.map((doc) {
        // 1. 获取数据，防 null 处理
        final data = doc.data() as Map<String, dynamic>? ?? {};

        // 2. 极度安全的类型解析
        String parsedClassName = data['className']?.toString().trim() ?? '';
        if (parsedClassName.isEmpty) {
          parsedClassName = 'No Class'; // 解决学生 form 没有 classname 的问题
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
  // === 新的 Academic Year 和 Half-Year Grades 控制 ===
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

  final List<String> _formQuestions = [
    'Part 1: Class Comfort & Environment',
    'Part 2: Understanding of Materials',
    'Part 3: Engagement & Participation',
    'Part 4: Learning Pace',
    'Part 5: Overall Growth'
  ];

  // 计算整年平均分逻辑
  double _calculateAverageGrade() {
    double firstHalf = double.tryParse(_firstHalfController.text) ?? -1.0;
    double secondHalf = double.tryParse(_secondHalfController.text) ?? -1.0;

    if (firstHalf >= 0 && secondHalf >= 0) {
      return (firstHalf + secondHalf) / 2; // 上半年和下半年都有
    } else if (firstHalf >= 0) {
      return firstHalf; // 只有上半年
    } else if (secondHalf >= 0) {
      return secondHalf; // 只有下半年
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

    // 模拟数据拉取
    // 💡 提示：这里在对接 Firebase 时，你应该通过 widget.student.id 去直接查询对应的 Form
    // 因为即使学生没有 ClassName，ID 或者名字也是可以对应上的。
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSyncing = false;
      if (widget.student.hasSubmittedForm) {
        _isDataFetched = true;
        _fetchedStudentEvalScore = widget.student.evaluationScore ?? 0;
        _fetchedDetailedAnswers = widget.student.detailedAnswers ?? [];
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
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.student.name}\'s Form Details',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              ...List.generate(_formQuestions.length, (index) {
                int score = _fetchedDetailedAnswers.isNotEmpty && index < _fetchedDetailedAnswers.length
                    ? _fetchedDetailedAnswers[index]
                    : 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formQuestions[index],
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
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

    if ((lowerComment.contains('excellent') ||
            lowerComment.contains('good') ||
            lowerComment.contains('great')) &&
        !(lowerComment.contains('struggle') || lowerComment.contains('poor'))) {
      return "AI Conclusion: Positive learning attitude. Grasps concepts easily.";
    } else if (lowerComment.contains('struggle') ||
        lowerComment.contains('hard') ||
        lowerComment.contains('poor')) {
      return "AI Conclusion: Facing academic challenges. Requires pacing adjustments.";
    } else if (lowerComment.contains('improve') || lowerComment.contains('better')) {
      return "AI Conclusion: Showing gradual progress and positive development.";
    }
    return "AI Conclusion: Maintains a standard and steady performance.";
  }

  void _generateReport() {
    if (_firstHalfController.text.isEmpty && _secondHalfController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter at least First Half or Second Half grade.')));
      return;
    }
    if (!_isDataFetched && widget.student.hasSubmittedForm) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sync the student\'s data first.')));
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
          academicYear: _selectedYear,
          firstHalfGrade: double.tryParse(_firstHalfController.text),
          secondHalfGrade: double.tryParse(_secondHalfController.text),
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
            // 1. 学年和半年成绩输入 (Academic Performance Input)
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
                onPressed: _generateReport,
                icon: const Icon(Icons.analytics),
                label: const Text('Generate Final Report'),
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
  final int evaluationScore;
  final bool hasEvalData;
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
            Text('AI Re-streaming Report\n$studentName',
                textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              child: ListTile(
                title: const Text('Academic Performance',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                subtitle: Text(
                  'Academic Year: $academicYear\n'
                  'First Half Year: ${firstHalfGrade != null ? firstHalfGrade!.toStringAsFixed(1) : 'N/A'}\n'
                  'Second Half Year: ${secondHalfGrade != null ? secondHalfGrade!.toStringAsFixed(1) : 'N/A'}\n'
                  '-------------------------\n'
                  'Yearly Average: ${averageGrade.toStringAsFixed(1)}/100\n'
                  'Final Grade: $gradeLetter'
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: ListTile(
                title: const Text('Student Self-Evaluation',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
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
                    const Text('Final Placement Recommendation',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
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