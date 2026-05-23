import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student.dart' hide GraphNode, GraphEdge, Teacher, ClassGroup, NodeType;
import '../models/teacher.dart';
import '../models/class_group.dart';
import '../models/graph_node.dart';
import '../models/graph_edge.dart';
import '../repositories/graph_repository.dart';
import '../services/firestore_service.dart';
import '../painters/edge_painter.dart';

// =====================================================
// CLASS INTELLIGENCE NETWORK
// Live Firestore data + the original beautiful visuals
// (glow edges, gradient AI profile card, breath-floating
//  nodes, focus-expand interaction)
// =====================================================

class ClassNetworkPage extends StatefulWidget {
  const ClassNetworkPage({super.key});

  @override
  State<ClassNetworkPage> createState() => _ClassNetworkPageState();
}

class _ClassNetworkPageState extends State<ClassNetworkPage>
    with TickerProviderStateMixin {
  final FirestoreService _service = FirestoreService();

  // ── Graph data ─────────────────────────────────────
  List<GraphNode> _allNodes = [];
  List<GraphEdge> _allEdges = [];
  List<GraphNode> visibleNodes = [];
  List<GraphEdge> visibleEdges = [];

  // ── Interaction state ──────────────────────────────
  final Set<String> _expandedClassIds = {};
  String? _focusedTeacherId;

  // ── Canvas ─────────────────────────────────────────
  final double canvasWidth = 3200;
  final double canvasHeight = 3200;
  final double nodeSize = 110;
  bool _isCanvasCentered = false;

  late AnimationController _breathController;
  final TransformationController _transformationController =
      TransformationController();

  // ── Firestore snapshot cache ───────────────────────
  List<Student> _students = [];
  List<Teacher> _teachers = [];
  List<ClassGroup> _classes = [];

  // User-dragged positions, keyed by node id. Survives Firestore refreshes
  // so manually-arranged layouts don't snap back when data updates.
  final Map<String, Offset> _positionOverrides = {};

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  // =====================================================
  // BUILD GRAPH FROM LATEST FIRESTORE SNAPSHOTS
  // =====================================================

  void _rebuildGraph(
    List<Student> students,
    List<Teacher> teachers,
    List<ClassGroup> classes,
  ) {
    _allNodes = GraphRepository.buildNodes(students, teachers, classes);
    // Re-apply any positions the user has dragged. Stale overrides (for
    // nodes that no longer exist) are pruned so the map can't grow forever.
    final liveIds = _allNodes.map((n) => n.id).toSet();
    _positionOverrides.removeWhere((id, _) => !liveIds.contains(id));
    for (final n in _allNodes) {
      final override = _positionOverrides[n.id];
      if (override != null) n.position = override;
    }
    _allEdges = GraphRepository.buildEdges(_allNodes);
    _filterVisibleElements();
  }

  // =====================================================
  // VISIBILITY FILTER
  // =====================================================

  void _filterVisibleElements() {
    visibleNodes = [];
    visibleEdges = [];

    // DEFAULT VIEW: classes + teachers only
    if (_focusedTeacherId == null && _expandedClassIds.isEmpty) {
      visibleNodes = _allNodes
          .where((n) =>
              n.type == NodeType.classNode ||
              n.type == NodeType.teacherNode)
          .toList();
    }

    // EXPANDED CLASS VIEW
    else if (_focusedTeacherId == null && _expandedClassIds.isNotEmpty) {
      final expandedClassNodes = _allNodes
          .where((n) =>
              n.type == NodeType.classNode &&
              _expandedClassIds.contains(n.id))
          .toList();

      visibleNodes.addAll(expandedClassNodes);

      final expandedNames = expandedClassNodes
          .map((n) => (n.data as ClassGroup).className)
          .toList();

      // Students of expanded classes
      visibleNodes.addAll(_allNodes.where(
        (n) =>
            n.type == NodeType.studentNode &&
            expandedNames.contains((n.data as Student).className),
      ));

      // Teachers who teach any expanded class
      visibleNodes.addAll(_allNodes.where(
        (n) =>
            n.type == NodeType.teacherNode &&
            (n.data as Teacher)
                .classesTaught
                .any((c) => expandedNames.contains(c)),
      ));
    }

    // FOCUSED TEACHER VIEW
    else if (_focusedTeacherId != null) {
      final focusedMatches =
          _allNodes.where((n) => n.id == _focusedTeacherId).toList();
      if (focusedMatches.isEmpty) {
        // Stale focus — reset
        _focusedTeacherId = null;
        _filterVisibleElements();
        return;
      }
      final focusedNode = focusedMatches.first;
      final teacher = focusedNode.data as Teacher;

      visibleNodes.add(focusedNode);

      final teacherClassNodes = _allNodes
          .where((n) =>
              n.type == NodeType.classNode &&
              teacher.classesTaught
                  .contains((n.data as ClassGroup).className))
          .toList();

      visibleNodes.addAll(teacherClassNodes);

      // Show students only for expanded classes that this teacher teaches
      for (final classId in _expandedClassIds) {
        final classMatches =
            _allNodes.where((n) => n.id == classId).toList();
        if (classMatches.isEmpty) continue;
        final className = (classMatches.first.data as ClassGroup).className;
        if (!teacher.classesTaught.contains(className)) continue;

        visibleNodes.addAll(_allNodes.where(
          (n) =>
              n.type == NodeType.studentNode &&
              (n.data as Student).className == className,
        ));
      }
    }

    // Filter edges to those whose both endpoints are visible
    final visibleIds = visibleNodes.map((n) => n.id).toSet();
    visibleEdges = _allEdges
        .where((e) =>
            visibleIds.contains(e.source.id) &&
            visibleIds.contains(e.target.id))
        .toList();
    // No setState here — callers that fire outside the build phase
    // (tap handlers, Reset button) wrap their own setState.
    // Calls from inside build (via StreamBuilder → _rebuildGraph)
    // don't need it because the framework is already rebuilding.
  }

  // =====================================================
  // NODE TAP
  // =====================================================

  void _handleNodeTap(GraphNode node) {
    if (node.type == NodeType.classNode) {
      setState(() {
        if (_expandedClassIds.contains(node.id)) {
          _expandedClassIds.remove(node.id);
        } else {
          _expandedClassIds.add(node.id);
        }
        _filterVisibleElements();
      });
    } else if (node.type == NodeType.teacherNode) {
      setState(() {
        if (_focusedTeacherId == node.id) {
          _focusedTeacherId = null;
        } else {
          _focusedTeacherId = node.id;
          _expandedClassIds.clear();
        }
        _filterVisibleElements();
      });
    } else if (node.type == NodeType.studentNode) {
      _showStudentProfile(node.data as Student);
    }
  }

  // =====================================================
  // ADD TEACHER DIALOG
  // =====================================================

  void _showAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final List<String> selectedClasses = [];
    final classNames = _classes.map((c) => c.className).toList();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              const Text('Add Teacher',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dialogTextField(
                      nameCtrl, 'Teacher Name', Icons.person_rounded),
                  const SizedBox(height: 12),
                  _dialogTextField(subjectCtrl,
                      'Subject(s) e.g. Math, Science', Icons.book_rounded),
                  const SizedBox(height: 16),
                  const Text('Assign to Classes:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  if (classNames.isEmpty)
                    const Text('No classes created yet.',
                        style:
                            TextStyle(color: Colors.blueGrey, fontSize: 13))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: classNames.map((c) {
                        final selected = selectedClasses.contains(c);
                        return FilterChip(
                          label: Text(c,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          selected: selected,
                          selectedColor: Colors.orange,
                          backgroundColor: Colors.grey.shade100,
                          onSelected: (v) {
                            setDialogState(() {
                              if (v) {
                                selectedClasses.add(c);
                              } else {
                                selectedClasses.remove(c);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final subjects = subjectCtrl.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                await FirebaseFirestore.instance.collection('teachers').add({
                  'name': name,
                  'subjects': subjects,
                  'classesTaught': selectedClasses,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Teacher',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

// =====================================================
  // DELETE TEACHER DIALOG
  // =====================================================
  void _confirmDeleteTeacher(Teacher teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
            const SizedBox(width: 8),
            const Text('删除老师 (Delete Teacher)'),
          ],
        ),
        content: Text('Are you sure you want to remove ${teacher.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              // 从 Firestore 删除老师数据
              await FirebaseFirestore.instance
                  .collection('teachers')
                  .doc(teacher.id)
                  .delete();
              
              if (ctx.mounted) Navigator.pop(ctx);

              // 如果删除的老师刚好是当前 Focus 的老师，则重置视图
              if (_focusedTeacherId == teacher.id) {
                setState(() {
                  _focusedTeacherId = null;
                  _filterVisibleElements();
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // =====================================================
  // STUDENT PROFILE — gradient AI insight card + scores
  // =====================================================

  String _dominantVarkLabel(Map<String, int> v) {
    if (v.isEmpty) return 'N/A';
    String top = 'V';
    int best = -1;
    for (final k in ['V', 'A', 'R', 'K']) {
      if ((v[k] ?? 0) > best) {
        best = v[k] ?? 0;
        top = k;
      }
    }
    const labels = {
      'V': 'Visual',
      'A': 'Auditory',
      'R': 'Read/Write',
      'K': 'Kinesthetic',
    };
    return labels[top] ?? top;
  }

  String _dominantPersonalityLabel(Map<String, int> p) {
    if (p.isEmpty) return 'Balanced';
    String top = p.keys.first;
    int best = -1;
    p.forEach((k, v) {
      if (v > best) {
        best = v;
        top = k;
      }
    });
    return top;
  }

  String _adaptivePath(String varkLabel, String personalityLabel) {
    final pathByStyle = {
      'Visual': 'Diagram-rich micro-lessons with colour-coded notes.',
      'Auditory': 'Discussion-led learning and recorded explainers.',
      'Read/Write': 'Structured notes, summaries, and written drills.',
      'Kinesthetic': 'Hands-on tasks and movement-based revision.',
    };
    final base = pathByStyle[varkLabel] ?? 'Mixed-modality adaptive path.';
    return '$base  Personality tilt: $personalityLabel.';
  }

  void _showStudentProfile(Student student) {
    final varkLabel = _dominantVarkLabel(student.varkScores);
    final pLabel = _dominantPersonalityLabel(student.personalityScores);
    final aiInsight =
        'Dominant learning style: $varkLabel. Personality trait: $pLabel.';
    final adaptivePath = _adaptivePath(varkLabel, pLabel);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.withOpacity(0.12),
              child: const Icon(Icons.person, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 20)),
                  Text(
                    student.className.isEmpty
                        ? 'Unassigned'
                        : student.className,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Gradient AI insight card (matches the look you wanted)
                _buildInsightCard(aiInsight, adaptivePath),
                const SizedBox(height: 20),

                if (student.varkScores.isNotEmpty)
                  _buildScoreCard('VARK Learning Style',
                      student.varkScores, Colors.deepPurple),
                if (student.varkScores.isNotEmpty)
                  const SizedBox(height: 16),

                if (student.personalityScores.isNotEmpty)
                  _buildScoreCard('Personality Profile',
                      student.personalityScores, Colors.teal),
                if (student.personalityScores.isNotEmpty)
                  const SizedBox(height: 16),

                _buildProfileRow(Icons.phone, 'Emergency Contact',
                    student.emergencyContact.isEmpty
                        ? '—'
                        : student.emergencyContact),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String insight, String adaptivePath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Cognitive Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Text(insight),
          const SizedBox(height: 12),
          Text(
            adaptivePath,
            style: TextStyle(
              color: Colors.deepPurple.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, Map<String, int> scores, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.07),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          const SizedBox(height: 12),
          ...scores.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 90,
                        child: Text(e.key,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 12))),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (e.value / 10).clamp(0.0, 1.0),
                          backgroundColor: color.withOpacity(0.12),
                          color: color,
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // LEGEND PANEL
  // =====================================================

  Widget _buildLegendPanel() {
    return Positioned(
      bottom: 24,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Legend',
                style:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            _legendItem(Colors.orange.shade300, 'Teacher ↔ Class'),
            const SizedBox(height: 6),
            _legendItem(const Color(0xFF0066FF), 'Student ↔ Class'),
            const SizedBox(height: 8),
            const Text('Tap class to expand',
                style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            const Text('Tap teacher to focus',
                style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
            const Text('Long press teacher to delete',
                style: TextStyle(fontSize: 10, color: Colors.redAccent)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  // =====================================================
  // NODE WIDGET — matches the original gorgeous design
  // =====================================================

  Widget _buildBeautifulNodeWidget(GraphNode node) {
    Color primaryColor = Colors.blue;
    IconData icon = Icons.person;

    final bool isFocused = _expandedClassIds.contains(node.id) ||
        _focusedTeacherId == node.id;

    switch (node.type) {
      case NodeType.classNode:
        primaryColor =
            isFocused ? Colors.purpleAccent : Colors.deepPurple;
        icon = Icons.groups_rounded;
        break;
      case NodeType.teacherNode:
        primaryColor = isFocused ? Colors.orangeAccent : Colors.orange;
        icon = Icons.school_rounded;
        break;
      case NodeType.studentNode:
        primaryColor = Colors.blue;
        icon = Icons.person;
        break;
    }

    return Container(
      width: nodeSize,
      height: 125,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ICON
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.12),
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 10),

          // TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              node.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),

          // TEACHER SUBJECTS
          if (node.type == NodeType.teacherNode)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                (node.data as Teacher).subjects.join(', '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (!_isCanvasCentered) {
      final s = MediaQuery.of(context).size;
      _transformationController.value = Matrix4.identity()
        ..translate(
          -(canvasWidth / 2) + s.width / 2,
          -(canvasHeight / 2) + s.height / 2,
        );
      _isCanvasCentered = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'AI Class Intelligence Network',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _showAddTeacherDialog,
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Add Teacher',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getStudentsStream(),
        builder: (context, studentSnap) {
          if (studentSnap.hasError) {
            return Center(child: Text('Error: ${studentSnap.error}'));
          }
          if (!studentSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _students = studentSnap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            return Student(
              id: doc.id,
              name: d['name'] ?? 'Unknown',
              emergencyContact: d['emergencyContact'] ?? '',
              className: d['className'] ?? 'Unassigned',
              varkScores: Map<String, int>.from(d['varkScores'] ?? {}),
              personalityScores:
                  Map<String, int>.from(d['personalityScores'] ?? {}),
              grades: '',
              basicInfo: '',
              specialConditions: '',
              aiCognitiveAnalysis: '',
              aiAdaptivePath: '',
            );
          }).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _service.getTeachersStream(),
            builder: (context, teacherSnap) {
              if (teacherSnap.hasError) {
                return Center(child: Text('Error: ${teacherSnap.error}'));
              }
              if (!teacherSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              _teachers = teacherSnap.data!.docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Teacher(
                  id: doc.id,
                  name: d['name'] ?? '',
                  subjects: List<String>.from(d['subjects'] ?? []),
                  classesTaught:
                      List<String>.from(d['classesTaught'] ?? []),
                );
              }).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _service.getClassesStream(),
                builder: (context, classSnap) {
                  if (classSnap.hasError) {
                    return Center(
                        child: Text('Error: ${classSnap.error}'));
                  }
                  if (!classSnap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  // Pull classes from the classes collection; fall back to
                  // distinct className values found among students.
                  _classes = classSnap.data!.docs.isNotEmpty
                      ? classSnap.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return ClassGroup(
                              className: d['className'] ?? doc.id);
                        }).toList()
                      : _students
                          .map((s) => s.className)
                          .toSet()
                          .where((c) => c.isNotEmpty && c != 'Unassigned')
                          .map((c) => ClassGroup(className: c))
                          .toList();

                  _rebuildGraph(_students, _teachers, _classes);

                  if (_allNodes.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Stack(
                    children: [
                      _buildCanvas(),
                      _buildLegendPanel(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),

      floatingActionButton:
          (_expandedClassIds.isEmpty && _focusedTeacherId == null)
              ? null
              : FloatingActionButton.extended(
                  backgroundColor: const Color(0xFF0F9D58),
                  onPressed: () {
                    setState(() {
                      _expandedClassIds.clear();
                      _focusedTeacherId = null;
                      _filterVisibleElements();
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Reset Network',
                      style: TextStyle(color: Colors.white)),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No data yet.\nCreate classes and run placement first.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTeacherDialog,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add a Teacher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas() {
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.2,
      maxScale: 1.7,
      transformationController: _transformationController,
      child: SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: AnimatedBuilder(
          animation: _breathController,
          builder: (_, __) => Stack(
            clipBehavior: Clip.none,
            children: [
              // EDGES (with glow)
              CustomPaint(
                size: Size(canvasWidth, canvasHeight),
                painter:
                    EdgePainter(edges: visibleEdges, nodeSize: nodeSize),
              ),
              // NODES (breath-floating + draggable)
              ...visibleNodes.map((node) {
                final floating = sin(
                        _breathController.value * pi * 2 + node.randomPhase) *
                    8;
                return Positioned(
                  left: node.position.dx,
                  top: node.position.dy + floating,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      // 短按功能：打开、聚焦或展开
                      onTap: () => _handleNodeTap(node),
                      
                      // 新增长按功能：长按老师节点触发删除
                      onLongPress: () {
                        if (node.type == NodeType.teacherNode) {
                          _confirmDeleteTeacher(node.data as Teacher);
                        }
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          node.position = Offset(
                            node.position.dx + details.delta.dx,
                            node.position.dy + details.delta.dy,
                          );
                          _positionOverrides[node.id] = node.position;
                        });
                      },
                      child: _buildBeautifulNodeWidget(node),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}