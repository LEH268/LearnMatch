import 'dart:math';
import 'package:flutter/material.dart';

// =====================================================
// DATA MODELS
// =====================================================

class Student {
  final String id;
  final String name;
  final String className;
  final String grades;
  final String basicInfo;
  final String emergencyContact;
  final String specialConditions;
  final String aiCognitiveAnalysis;
  final String aiAdaptivePath;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.grades,
    required this.basicInfo,
    required this.emergencyContact,
    required this.specialConditions,
    required this.aiCognitiveAnalysis,
    required this.aiAdaptivePath,
  });
}

class Teacher {
  final String id;
  final String name;
  final List<String> subjects;
  final List<String> classesTaught;

  Teacher({
    required this.id,
    required this.name,
    required this.subjects,
    required this.classesTaught,
  });
}

class ClassGroup {
  final String className;

  ClassGroup({
    required this.className,
  });
}

// =====================================================
// GRAPH MODELS
// =====================================================

enum NodeType {
  classNode,
  teacherNode,
  studentNode,
}

class GraphNode {
  final String id;
  final String label;
  final NodeType type;
  final dynamic data;
  Offset position;
  final double randomPhase;

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.data,
    required this.position,
    required this.randomPhase,
  });
}

class GraphEdge {
  final GraphNode source;
  final GraphNode target;

  GraphEdge({
    required this.source,
    required this.target,
  });
}

// =====================================================
// MAIN PAGE
// =====================================================

class ClassNetworkPage extends StatefulWidget {
  const ClassNetworkPage({super.key});

  @override
  State<ClassNetworkPage> createState() => _ClassNetworkPageState();
}

class _ClassNetworkPageState extends State<ClassNetworkPage>
    with TickerProviderStateMixin {
  final List<GraphNode> _allNodes = [];
  final List<GraphEdge> _allEdges = [];

  List<GraphNode> visibleNodes = [];
  List<GraphEdge> visibleEdges = [];

  final Set<String> _expandedClassIds = {};

  String? _focusedTeacherId;

  final double canvasWidth = 3200;
  final double canvasHeight = 3200;

  final double nodeSize = 110;

  late AnimationController _breathController;

  final TransformationController _transformationController =
      TransformationController();

  bool _isCanvasCentered = false;

  @override
  void initState() {
    super.initState();

    _generateMasterGraphData();

    _filterVisibleElements();

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
  // GENERATE GRAPH
  // =====================================================

  void _generateMasterGraphData() {
    final center = Offset(
      canvasWidth / 2,
      canvasHeight / 2,
    );

    final random = Random();

    // =================================================
    // CLASS NODES
    // =================================================

    final classA = ClassGroup(className: 'Class A');
    final classB = ClassGroup(className: 'Class B');

    final classNodeA = GraphNode(
      id: 'CLASS_A',
      label: 'Class A',
      type: NodeType.classNode,
      data: classA,
      position: center + const Offset(-520, 0),
      randomPhase: random.nextDouble() * pi * 2,
    );

    final classNodeB = GraphNode(
      id: 'CLASS_B',
      label: 'Class B',
      type: NodeType.classNode,
      data: classB,
      position: center + const Offset(520, 0),
      randomPhase: random.nextDouble() * pi * 2,
    );

    _allNodes.addAll([
      classNodeA,
      classNodeB,
    ]);

    // =================================================
    // TEACHERS
    // =================================================

    final teacher1 = Teacher(
      id: 'T001',
      name: 'Mr. Anderson',
      subjects: ['Mathematics'],
      classesTaught: ['Class A', 'Class B'],
    );

    final teacher2 = Teacher(
      id: 'T002',
      name: 'Ms. Sarah',
      subjects: ['English Literature'],
      classesTaught: ['Class A'],
    );

    final teacherNode1 = GraphNode(
      id: teacher1.id,
      label: teacher1.name,
      type: NodeType.teacherNode,
      data: teacher1,
      position: center + const Offset(0, -420),
      randomPhase: random.nextDouble() * pi * 2,
    );

    final teacherNode2 = GraphNode(
      id: teacher2.id,
      label: teacher2.name,
      type: NodeType.teacherNode,
      data: teacher2,
      position: center + const Offset(-900, -250),
      randomPhase: random.nextDouble() * pi * 2,
    );

    _allNodes.addAll([
      teacherNode1,
      teacherNode2,
    ]);

    // =================================================
    // TEACHER CONNECTIONS
    // =================================================

    _allEdges.addAll([
      GraphEdge(
        source: teacherNode1,
        target: classNodeA,
      ),
      GraphEdge(
        source: teacherNode1,
        target: classNodeB,
      ),
      GraphEdge(
        source: teacherNode2,
        target: classNodeA,
      ),
    ]);

    // =================================================
    // STUDENTS
    // =================================================

    final students = [
      Student(
        id: 'S101',
        name: 'Alice Brown',
        className: 'Class A',
        grades: 'A (94%)',
        basicInfo: '15 Years Old',
        emergencyContact: 'Mother: 012-3456789',
        specialConditions: 'None',
        aiCognitiveAnalysis:
            'Excellent logical reasoning ability.',
        aiAdaptivePath:
            'Advanced mathematics exploration.',
      ),
      Student(
        id: 'S102',
        name: 'Charlie Davis',
        className: 'Class A',
        grades: 'C- (61%)',
        basicInfo: '16 Years Old',
        emergencyContact: 'Father: 019-8765432',
        specialConditions: 'Mild ADHD',
        aiCognitiveAnalysis:
            'Creative learner with short attention span.',
        aiAdaptivePath:
            'Micro-task learning system.',
      ),
      Student(
        id: 'S103',
        name: 'Diana Evans',
        className: 'Class A',
        grades: 'B+ (87%)',
        basicInfo: '15 Years Old',
        emergencyContact: 'Aunt: 011-2223334',
        specialConditions: 'None',
        aiCognitiveAnalysis:
            'Strong communication and leadership.',
        aiAdaptivePath:
            'Collaborative peer mentorship.',
      ),
      Student(
        id: 'S201',
        name: 'Ethan Foster',
        className: 'Class B',
        grades: 'B (82%)',
        basicInfo: '16 Years Old',
        emergencyContact: 'Mother: 014-5556667',
        specialConditions: 'Autism Spectrum',
        aiCognitiveAnalysis:
            'Exceptional focus and pattern recognition.',
        aiAdaptivePath:
            'Routine-based adaptive structure.',
      ),
      Student(
        id: 'S202',
        name: 'Fiona Garcia',
        className: 'Class B',
        grades: 'A+ (98%)',
        basicInfo: '15 Years Old',
        emergencyContact: 'Father: 016-9998887',
        specialConditions: 'None',
        aiCognitiveAnalysis:
            'High memory retention capability.',
        aiAdaptivePath:
            'Independent research pathway.',
      ),
    ];

    Map<String, List<Student>> groupedStudents = {};

    for (var student in students) {
      groupedStudents
          .putIfAbsent(student.className, () => [])
          .add(student);
    }

    groupedStudents.forEach((className, studentList) {
      final classNode = _allNodes.firstWhere(
        (n) => n.label == className,
      );

      for (int i = 0; i < studentList.length; i++) {
        final angle = (2 * pi * i) / studentList.length;

        final radius = 280 + random.nextInt(90);

        final position = classNode.position +
            Offset(
              cos(angle) * radius,
              sin(angle) * radius,
            );

        final studentNode = GraphNode(
          id: studentList[i].id,
          label: studentList[i].name,
          type: NodeType.studentNode,
          data: studentList[i],
          position: position,
          randomPhase: random.nextDouble() * pi * 2,
        );

        _allNodes.add(studentNode);

        _allEdges.add(
          GraphEdge(
            source: classNode,
            target: studentNode,
          ),
        );
      }
    });
  }

  // =====================================================
  // FILTER VISIBLE ELEMENTS
  // =====================================================

  void _filterVisibleElements() {
    setState(() {
      visibleNodes.clear();
      visibleEdges.clear();

      // ===============================================
      // DEFAULT VIEW
      // ===============================================

      if (_focusedTeacherId == null &&
          _expandedClassIds.isEmpty) {
        visibleNodes.addAll(
          _allNodes.where(
            (n) =>
                n.type == NodeType.classNode ||
                n.type == NodeType.teacherNode,
          ),
        );
      }

      // ===============================================
      // EXPANDED CLASS VIEW
      // ===============================================

      else if (_focusedTeacherId == null &&
          _expandedClassIds.isNotEmpty) {
        final expandedClassNodes = _allNodes.where(
          (n) =>
              n.type == NodeType.classNode &&
              _expandedClassIds.contains(n.id),
        );

        visibleNodes.addAll(expandedClassNodes);

        final expandedClassNames = expandedClassNodes
            .map(
              (n) =>
                  (n.data as ClassGroup).className,
            )
            .toList();

        visibleNodes.addAll(
          _allNodes.where(
            (n) =>
                n.type == NodeType.studentNode &&
                expandedClassNames.contains(
                  (n.data as Student).className,
                ),
          ),
        );

        visibleNodes.addAll(
          _allNodes.where(
            (n) =>
                n.type == NodeType.teacherNode &&
                (n.data as Teacher)
                    .classesTaught
                    .any(
                      (c) =>
                          expandedClassNames.contains(c),
                    ),
          ),
        );
      }

      // ===============================================
      // FOCUSED TEACHER VIEW
      // ===============================================

      else if (_focusedTeacherId != null) {
        final focusedTeacherNode =
            _allNodes.firstWhere(
          (n) => n.id == _focusedTeacherId,
        );

        final teacher =
            focusedTeacherNode.data as Teacher;

        visibleNodes.add(focusedTeacherNode);

        final teacherClassNodes = _allNodes.where(
          (n) =>
              n.type == NodeType.classNode &&
              teacher.classesTaught.contains(
                (n.data as ClassGroup).className,
              ),
        );

        visibleNodes.addAll(teacherClassNodes);

        // IMPORTANT:
        // Show students when class expanded
        for (String classId in _expandedClassIds) {
          final classNode =
              _allNodes.firstWhere(
            (n) => n.id == classId,
          );

          final className =
              (classNode.data as ClassGroup)
                  .className;

          if (teacher.classesTaught
              .contains(className)) {
            visibleNodes.addAll(
              _allNodes.where(
                (n) =>
                    n.type ==
                        NodeType.studentNode &&
                    (n.data as Student)
                            .className ==
                        className,
              ),
            );
          }
        }
      }

      // ===============================================
      // FILTER EDGES
      // ===============================================

      for (var edge in _allEdges) {
        if (visibleNodes.any(
              (n) => n.id == edge.source.id,
            ) &&
            visibleNodes.any(
              (n) => n.id == edge.target.id,
            )) {
          visibleEdges.add(edge);
        }
      }
    });
  }

  // =====================================================
  // NODE TAP
  // =====================================================

  void _handleNodeTap(GraphNode node) {
    if (node.type == NodeType.classNode) {
      if (_expandedClassIds.contains(node.id)) {
        _expandedClassIds.remove(node.id);
      } else {
        _expandedClassIds.add(node.id);
      }

      _filterVisibleElements();
    }

    else if (node.type ==
        NodeType.teacherNode) {
      if (_focusedTeacherId == node.id) {
        _focusedTeacherId = null;
      } else {
        _focusedTeacherId = node.id;
        _expandedClassIds.clear();
      }

      _filterVisibleElements();
    }

    else if (node.type ==
        NodeType.studentNode) {
      _showStudentProfile(node.data as Student);
    }
  }

  // =====================================================
  // PROFILE DIALOG
  // =====================================================

  void _showStudentProfile(Student student) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                    Colors.blue.withOpacity(0.12),
                child: const Icon(
                  Icons.person,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      student.className,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
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
                  _buildInsightCard(student),

                  const SizedBox(height: 20),

                  _buildProfileRow(
                    Icons.grade,
                    'Academic Grade',
                    student.grades,
                  ),

                  _buildProfileRow(
                    Icons.info_outline,
                    'Basic Information',
                    student.basicInfo,
                  ),

                  _buildProfileRow(
                    Icons.phone,
                    'Emergency Contact',
                    student.emergencyContact,
                  ),

                  _buildProfileRow(
                    Icons.health_and_safety,
                    'Special Conditions',
                    student.specialConditions,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInsightCard(Student student) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade50,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'AI Cognitive Analysis',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  Colors.deepPurple.shade700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            student.aiCognitiveAnalysis,
          ),
          const SizedBox(height: 12),
          Text(
            student.aiAdaptivePath,
            style: TextStyle(
              color:
                  Colors.deepPurple.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
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
      final screenSize =
          MediaQuery.of(context).size;

      final matrix = Matrix4.identity();

      matrix.translate(
        -(canvasWidth / 2) +
            (screenSize.width / 2),
        -(canvasHeight / 2) +
            (screenSize.height / 2),
      );

      _transformationController.value =
          matrix;

      _isCanvasCentered = true;
    }

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9FC),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'AI Class Intelligence Network',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: InteractiveViewer(
        constrained: false,
        boundaryMargin:
            const EdgeInsets.all(
          double.infinity,
        ),
        minScale: 0.2,
        maxScale: 1.7,
        transformationController:
            _transformationController,

        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,

          child: AnimatedBuilder(
            animation: _breathController,
            builder: (context, child) {
              return Stack(
                clipBehavior: Clip.none,
                children: [

                  // CONNECTIONS
                  CustomPaint(
                    size: Size(
                      canvasWidth,
                      canvasHeight,
                    ),
                    painter: EdgePainter(
                      edges: visibleEdges,
                      nodeSize: nodeSize,
                    ),
                  ),

                  // NODES
                  ...visibleNodes.map((node) {
                    final floating =
                        sin(
                              (_breathController
                                          .value *
                                      pi *
                                      2) +
                                  node.randomPhase,
                            ) *
                            8;

                    return Positioned(
                      left: node.position.dx,
                      top: node.position.dy +
                          floating,
                      child: GestureDetector(
                        onTap: () {
                          _handleNodeTap(node);
                        },
                        child:
                            _buildBeautifulNodeWidget(
                          node,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),

      floatingActionButton:
          (_expandedClassIds.isEmpty &&
                  _focusedTeacherId == null)
              ? null
              : FloatingActionButton.extended(
                  backgroundColor:
                      const Color(0xFF0F9D58),
                  onPressed: () {
                    setState(() {
                      _expandedClassIds.clear();
                      _focusedTeacherId = null;
                      _filterVisibleElements();
                    });
                  },
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Reset Network',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
    );
  }

  // =====================================================
  // NODE UI
  // =====================================================

  Widget _buildBeautifulNodeWidget(
    GraphNode node,
  ) {
    Color primaryColor = Colors.blue;

    IconData icon = Icons.person;

    bool isFocused =
        _expandedClassIds.contains(node.id) ||
            _focusedTeacherId == node.id;

    switch (node.type) {
      case NodeType.classNode:
        primaryColor = isFocused
            ? Colors.purpleAccent
            : Colors.deepPurple;
        icon = Icons.groups_rounded;
        break;

      case NodeType.teacherNode:
        primaryColor = isFocused
            ? Colors.orangeAccent
            : Colors.orange;
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
        borderRadius:
            BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color:
                primaryColor.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [

          // ICON
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  primaryColor.withOpacity(0.12),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 28,
            ),
          ),

          const SizedBox(height: 10),

          // TITLE
          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
            ),
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

          // SUBJECTS
          if (node.type ==
              NodeType.teacherNode)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 5,
              ),
              child: Text(
                (node.data as Teacher)
                    .subjects
                    .join(', '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  color:
                      Colors.grey.shade600,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =====================================================
// EDGE PAINTER
// =====================================================

class EdgePainter extends CustomPainter {
  final List<GraphEdge> edges;
  final double nodeSize;

  EdgePainter({
    required this.edges,
    required this.nodeSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(10);

    for (var edge in edges) {

      // =================================================
      // LINE TYPE
      // =================================================

      bool isTeacherConnection =
          edge.source.type ==
              NodeType.teacherNode;

      // =================================================
      // ICON CENTER
      // =================================================

      final start = edge.source.position +
          Offset(nodeSize / 2, 34);

      final end = edge.target.position +
          Offset(nodeSize / 2, 34);

      // =================================================
      // CURVE
      // =================================================

      final midPoint = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final curveOffset =
          random.nextDouble() * 80 - 40;

      final controlPoint = Offset(
        midPoint.dx + curveOffset,
        midPoint.dy - 40,
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          end.dx,
          end.dy,
        );

      // =================================================
      // GLOW
      // =================================================

      final glowPaint = Paint()
        ..color = isTeacherConnection
            ? Colors.orangeAccent
                .withOpacity(0.22)
            : Colors.cyanAccent
                .withOpacity(0.20)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          12,
        );

      // =================================================
      // MAIN LINE
      // =================================================

      final linePaint = Paint()
        ..color = isTeacherConnection
            ? Colors.orange.shade200
            : Colors.white.withOpacity(0.78)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // =================================================
      // DRAW
      // =================================================

      canvas.drawPath(path, glowPaint);

      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return true;
  }
}