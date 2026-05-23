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
  final double canvasWidth  = 3200;
  final double canvasHeight = 3200;
  final double nodeSize     = 110;
  bool _isCanvasCentered    = false;

  late AnimationController _breathController;
  final TransformationController _transformationController =
      TransformationController();

  // ── Firestore snapshot cache ───────────────────────
  List<Student>    _students = [];
  List<Teacher>    _teachers = [];
  List<ClassGroup> _classes  = [];

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

  // ── Rebuild graph from latest Firestore data ───────
  void _rebuildGraph(
    List<Student>    students,
    List<Teacher>    teachers,
    List<ClassGroup> classes,
  ) {
    _allNodes = GraphRepository.buildNodes(students, teachers, classes);
    _allEdges = GraphRepository.buildEdges(_allNodes);
    _filterVisibleElements();
  }

  // ── Visibility filter ──────────────────────────────
  void _filterVisibleElements() {
    setState(() {
      visibleNodes = [];
      visibleEdges = [];

      if (_focusedTeacherId == null && _expandedClassIds.isEmpty) {
        // Default: show class + teacher nodes only
        visibleNodes = _allNodes
            .where((n) =>
                n.type == NodeType.classNode ||
                n.type == NodeType.teacherNode)
            .toList();

      } else if (_focusedTeacherId == null && _expandedClassIds.isNotEmpty) {
        // Expanded class view
        final expandedClassNodes = _allNodes.where(
          (n) => n.type == NodeType.classNode && _expandedClassIds.contains(n.id),
        ).toList();

        visibleNodes.addAll(expandedClassNodes);

        final expandedNames = expandedClassNodes
            .map((n) => (n.data as ClassGroup).className)
            .toList();

        visibleNodes.addAll(_allNodes.where(
          (n) => n.type == NodeType.studentNode &&
              expandedNames.contains((n.data as Student).className),
        ));

        visibleNodes.addAll(_allNodes.where(
          (n) =>
              n.type == NodeType.teacherNode &&
              (n.data as Teacher)
                  .classesTaught
                  .any((c) => expandedNames.contains(c)),
        ));

      } else if (_focusedTeacherId != null) {
        // Focused teacher view
        final focusedNode =
            _allNodes.firstWhere((n) => n.id == _focusedTeacherId);
        final teacher = focusedNode.data as Teacher;

        visibleNodes.add(focusedNode);

        final teacherClassNodes = _allNodes.where(
          (n) =>
              n.type == NodeType.classNode &&
              teacher.classesTaught
                  .contains((n.data as ClassGroup).className),
        ).toList();

        visibleNodes.addAll(teacherClassNodes);

        // Also show students if their class is expanded
        for (final classId in _expandedClassIds) {
          final classMatches =
              _allNodes.where((n) => n.id == classId).toList();
          if (classMatches.isEmpty) continue;
          final className =
              (classMatches.first.data as ClassGroup).className;
          if (!teacher.classesTaught.contains(className)) continue;

          visibleNodes.addAll(_allNodes.where(
            (n) =>
                n.type == NodeType.studentNode &&
                (n.data as Student).className == className,
          ));
        }
      }

      // Filter edges: both endpoints must be visible
      final visibleIds = visibleNodes.map((n) => n.id).toSet();
      visibleEdges = _allEdges
          .where((e) =>
              visibleIds.contains(e.source.id) &&
              visibleIds.contains(e.target.id))
          .toList();
    });
  }

  // ── Node tap ───────────────────────────────────────
  void _handleNodeTap(GraphNode node) {
    if (node.type == NodeType.classNode) {
      if (_expandedClassIds.contains(node.id)) {
        _expandedClassIds.remove(node.id);
      } else {
        _expandedClassIds.add(node.id);
      }
      _filterVisibleElements();
    } else if (node.type == NodeType.teacherNode) {
      if (_focusedTeacherId == node.id) {
        _focusedTeacherId = null;
      } else {
        _focusedTeacherId = node.id;
        _expandedClassIds.clear();
      }
      _filterVisibleElements();
    } else if (node.type == NodeType.studentNode) {
      _showStudentProfile(node.data as Student);
    }
  }

  // ── Student profile dialog ─────────────────────────
  void _showStudentProfile(Student student) {
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
                    student.className.isEmpty ? 'Unassigned' : student.className,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // VARK Scores
                if (student.varkScores.isNotEmpty)
                  _buildScoreCard(
                    'VARK Learning Style',
                    student.varkScores,
                    Colors.deepPurple,
                  ),
                const SizedBox(height: 16),
                // Personality Scores
                if (student.personalityScores.isNotEmpty)
                  _buildScoreCard(
                    'Personality Profile',
                    student.personalityScores,
                    Colors.teal,
                  ),
                const SizedBox(height: 16),
                _buildProfileRow(
                    Icons.phone, 'Emergency Contact', student.emergencyContact),
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

  Widget _buildScoreCard(
      String title, Map<String, int> scores, Color color) {
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
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 15)),
          const SizedBox(height: 12),
          ...scores.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 32,
                        child: Text(e.key,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color))),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Node widget ────────────────────────────────────
  Widget _buildNodeWidget(GraphNode node) {
    final bool isFocused = _expandedClassIds.contains(node.id) ||
        _focusedTeacherId == node.id;

    Color color;
    IconData icon;

    switch (node.type) {
      case NodeType.classNode:
        color = isFocused ? Colors.purpleAccent : Colors.deepPurple;
        icon  = Icons.groups_rounded;
        break;
      case NodeType.teacherNode:
        color = isFocused ? Colors.orangeAccent : Colors.orange;
        icon  = Icons.school_rounded;
        break;
      case NodeType.studentNode:
        color = Colors.blue;
        icon  = Icons.person;
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
            color: color.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              node.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          if (node.type == NodeType.teacherNode)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                (node.data as Teacher).subjects.join(', '),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Centre canvas on first frame
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
          'Class Intelligence Network',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ── Firestore streams ────────────────────────────
      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getStudentsStream(),
        builder: (context, studentSnap) {
          if (studentSnap.hasError) {
            return Center(
                child: Text('Error: ${studentSnap.error}',
                    style: const TextStyle(color: Colors.red)));
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
            );
          }).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _service.getTeachersStream(),
            builder: (context, teacherSnap) {
              if (teacherSnap.hasError) {
                return Center(
                    child: Text('Error: ${teacherSnap.error}',
                        style: const TextStyle(color: Colors.red)));
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
                  classesTaught: List<String>.from(d['classesTaught'] ?? []),
                );
              }).toList();

              return StreamBuilder<QuerySnapshot>(
                stream: _service.getClassesStream(),
                builder: (context, classSnap) {
                  if (classSnap.hasError) {
                    return Center(
                        child: Text('Error: ${classSnap.error}',
                            style: const TextStyle(color: Colors.red)));
                  }
                  if (!classSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Build classes from Firestore; fallback to unique classNames from students
                  _classes = classSnap.data!.docs.isNotEmpty
                      ? classSnap.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return ClassGroup(
                              className: d['className'] ?? doc.id);
                        }).toList()
                      : _students
                          .map((s) => s.className)
                          .toSet()
                          .where((c) => c != 'Unassigned')
                          .map((c) => ClassGroup(className: c))
                          .toList();

                  // Rebuild graph whenever data changes
                  _rebuildGraph(_students, _teachers, _classes);

                  if (_allNodes.isEmpty) {
                    return const Center(
                      child: Text(
                        'No data yet.\nAdd students via the assessment link first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                      ),
                    );
                  }

                  return _buildCanvas();
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
                  onPressed: () => setState(() {
                    _expandedClassIds.clear();
                    _focusedTeacherId = null;
                    _filterVisibleElements();
                  }),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Reset Network',
                      style: TextStyle(color: Colors.white)),
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
              // Edges
              CustomPaint(
                size: Size(canvasWidth, canvasHeight),
                painter: EdgePainter(
                    edges: visibleEdges, nodeSize: nodeSize),
              ),
              // Nodes
              ...visibleNodes.map((node) {
                final floating = sin(
                        _breathController.value * pi * 2 + node.randomPhase) *
                    8;
                return Positioned(
                  left: node.position.dx,
                  top: node.position.dy + floating,
                  child: GestureDetector(
                    onTap: () => _handleNodeTap(node),
                    child: _buildNodeWidget(node),
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