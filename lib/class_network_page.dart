import 'package:flutter/material.dart';
import 'dart:math';

// ==========================================
// 1. Data Models
// ==========================================

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
  ClassGroup({required this.className});
}

// ==========================================
// 2. Graph Models
// ==========================================

enum NodeType { classNode, teacherNode, studentNode }

class GraphNode {
  final String id;
  final String label;
  final NodeType type;
  final dynamic data; 
  Offset position;
  final double randomPhase; // For organic breathing animation

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

  GraphEdge({required this.source, required this.target});
}

// ==========================================
// 3. Main Interactive Graph Page
// ==========================================

class ClassNetworkPage extends StatefulWidget {
  const ClassNetworkPage({Key? key}) : super(key: key);

  @override
  State<ClassNetworkPage> createState() => _ClassNetworkPageState();
}

class _ClassNetworkPageState extends State<ClassNetworkPage> with TickerProviderStateMixin {
  final List<GraphNode> _allNodes = [];
  final List<GraphEdge> _allEdges = [];

  List<GraphNode> visibleNodes = [];
  List<GraphEdge> visibleEdges = [];
  
  Set<String> _expandedClassIds = {};
  String? _focusedTeacherId;

  final double canvasWidth = 3000.0;
  final double canvasHeight = 3000.0;
  final double nodeSize = 95.0; 

  final TransformationController _transformationController = TransformationController();
  bool _isCanvasCentered = false;
  late AnimationController _breathController;

  @override
  void initState() {
    super.initState();
    _generateMasterGraphData();
    _filterVisibleElements(); 

    // Animation controller for breathing effect
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  void _generateMasterGraphData() {
    final center = Offset(canvasWidth / 2, canvasHeight / 2);
    final random = Random();

    // Init Classes
    final classA = ClassGroup(className: 'Class A');
    final classB = ClassGroup(className: 'Class B');
    
    final classNodeA = GraphNode(id: 'C_A', label: 'Class A', type: NodeType.classNode, data: classA, position: center + const Offset(-450, 0), randomPhase: random.nextDouble() * 2 * pi);
    final classNodeB = GraphNode(id: 'C_B', label: 'Class B', type: NodeType.classNode, data: classB, position: center + const Offset(450, 0), randomPhase: random.nextDouble() * 2 * pi);
    _allNodes.addAll([classNodeA, classNodeB]);

    // Init Teachers
    final t1 = Teacher(id: 'T001', name: 'Mr. Anderson', subjects: ['Mathematics'], classesTaught: ['Class A', 'Class B']);
    final t2 = Teacher(id: 'T002', name: 'Ms. Sarah', subjects: ['English Lit'], classesTaught: ['Class A']);
    
    final tNode1 = GraphNode(id: t1.id, label: t1.name, type: NodeType.teacherNode, data: t1, position: center + const Offset(0, -350), randomPhase: random.nextDouble() * 2 * pi);
    final tNode2 = GraphNode(id: t2.id, label: t2.name, type: NodeType.teacherNode, data: t2, position: classNodeA.position + const Offset(-200, -250), randomPhase: random.nextDouble() * 2 * pi);
    _allNodes.addAll([tNode1, tNode2]);

    _allEdges.addAll([
      GraphEdge(source: tNode1, target: classNodeA),
      GraphEdge(source: tNode1, target: classNodeB),
      GraphEdge(source: tNode2, target: classNodeA),
    ]);

    // Init Students
    final studentsPool = [
      Student(id: 'S101', name: 'Alice Brown', className: 'Class A', grades: 'A (94%)', basicInfo: 'Age 15, Female', emergencyContact: 'Mom: 012-3456789', specialConditions: 'None', aiCognitiveAnalysis: 'Exceptional logic.', aiAdaptivePath: 'Advanced problem sets.'),
      Student(id: 'S102', name: 'Charlie Davis', className: 'Class A', grades: 'C- (61%)', basicInfo: 'Age 16, Male', emergencyContact: 'Dad: 019-8765432', specialConditions: 'ADHD (Mild)', aiCognitiveAnalysis: 'Creative, short attention span.', aiAdaptivePath: 'Micro-tasking instruction.'),
      Student(id: 'S103', name: 'Diana Evans', className: 'Class A', grades: 'B+ (87%)', basicInfo: 'Age 15, Female', emergencyContact: 'Aunt: 011-2223334', specialConditions: 'None', aiCognitiveAnalysis: 'Strong leadership.', aiAdaptivePath: 'Peer-mentorship.'),
      Student(id: 'S201', name: 'Ethan Foster', className: 'Class B', grades: 'B (82%)', basicInfo: 'Age 16, Male', emergencyContact: 'Mom: 014-5556667', specialConditions: 'Autism Spectrum', aiCognitiveAnalysis: 'Hyper-focused.', aiAdaptivePath: 'Routine transparency.'),
      Student(id: 'S202', name: 'Fiona Garcia', className: 'Class B', grades: 'A+ (98%)', basicInfo: 'Age 15, Female', emergencyContact: 'Dad: 016-9998887', specialConditions: 'None', aiCognitiveAnalysis: 'High retention.', aiAdaptivePath: 'Independent exploration.'),
    ];

    Map<String, List<Student>> groupedByClass = {};
    for (var s in studentsPool) groupedByClass.putIfAbsent(s.className, () => []).add(s);

    groupedByClass.forEach((className, students) {
      final targetClassNode = _allNodes.firstWhere((n) => n.label == className);
      for (int i = 0; i < students.length; i++) {
        double angle = (i * 2 * pi) / students.length;
        double radius = 250.0 + random.nextInt(30);
        Offset studentPos = targetClassNode.position + Offset(cos(angle) * radius, sin(angle) * radius);
        _allNodes.add(GraphNode(id: students[i].id, label: students[i].name, type: NodeType.studentNode, data: students[i], position: studentPos, randomPhase: random.nextDouble() * 2 * pi));
        _allEdges.add(GraphEdge(source: targetClassNode, target: _allNodes.last));
      }
    });
  }

  void _filterVisibleElements() {
    setState(() {
      visibleNodes.clear();
      visibleEdges.clear();

      if (_focusedTeacherId == null && _expandedClassIds.isEmpty) {
        visibleNodes.addAll(_allNodes.where((n) => n.type == NodeType.classNode || n.type == NodeType.teacherNode));
      } else if (_focusedTeacherId == null && _expandedClassIds.isNotEmpty) {
        final expandedClassNodes = _allNodes.where((n) => n.type == NodeType.classNode && _expandedClassIds.contains(n.id));
        visibleNodes.addAll(expandedClassNodes);
        final expandedClassNames = expandedClassNodes.map((n) => (n.data as ClassGroup).className).toList();
        visibleNodes.addAll(_allNodes.where((n) => n.type == NodeType.studentNode && expandedClassNames.contains((n.data as Student).className)));
        visibleNodes.addAll(_allNodes.where((n) => n.type == NodeType.teacherNode && (n.data as Teacher).classesTaught.any((c) => expandedClassNames.contains(c))));
      } else if (_focusedTeacherId != null) {
        final focusedTeacherNode = _allNodes.firstWhere((n) => n.id == _focusedTeacherId);
        final teacher = focusedTeacherNode.data as Teacher;
        visibleNodes.add(focusedTeacherNode);
        visibleNodes.addAll(_allNodes.where((n) => n.type == NodeType.classNode && teacher.classesTaught.contains((n.data as ClassGroup).className)));
        if (_expandedClassIds.isNotEmpty) {
          for (String classId in _expandedClassIds) {
            final className = (_allNodes.firstWhere((n) => n.id == classId).data as ClassGroup).className;
            if (teacher.classesTaught.contains(className)) {
              visibleNodes.addAll(_allNodes.where((n) => n.type == NodeType.studentNode && (n.data as Student).className == className));
            }
          }
        }
      }

      for (var edge in _allEdges) {
        if (visibleNodes.any((n) => n.id == edge.source.id) && visibleNodes.any((n) => n.id == edge.target.id)) {
          visibleEdges.add(edge);
        }
      }
    });
  }

  void _handleNodeTap(GraphNode node) {
    if (node.type == NodeType.classNode) {
      if (_expandedClassIds.contains(node.id)) _expandedClassIds.remove(node.id); else _expandedClassIds.add(node.id);
      _filterVisibleElements(); 
    } else if (node.type == NodeType.teacherNode) {
      if (_focusedTeacherId == node.id) _focusedTeacherId = null; else { _focusedTeacherId = node.id; _expandedClassIds.clear(); }
      _filterVisibleElements();
    } else if (node.type == NodeType.studentNode) {
      _showStudentProfile(node.data as Student);
    }
  }

  void _showStudentProfile(Student student) {
    Color conditionColor = student.specialConditions.toLowerCase() == 'none' ? Colors.green.shade600 : Colors.red.shade600;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.blue.shade100, radius: 24, child: const Icon(Icons.person, color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), Text(student.className, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))])),
          ],
        ),
        content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.purple.shade50, Colors.blue.shade50]), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('AI Intelligence Insights', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)), const SizedBox(height: 8), Text(student.aiCognitiveAnalysis, style: const TextStyle(fontSize: 13)), const SizedBox(height: 8), Text(student.aiAdaptivePath, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple.shade900))])),
          const SizedBox(height: 20),
          _buildProfileRow(Icons.grade_rounded, 'Grades', student.grades),
          _buildProfileRow(Icons.contact_phone_outlined, 'Emergency', student.emergencyContact),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dismiss'))],
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String title, String value) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [Icon(icon, color: Colors.blueGrey), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 12)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]))]));

  @override
  Widget build(BuildContext context) {
    if (!_isCanvasCentered) {
      final screenSize = MediaQuery.of(context).size;
      final initialMatrix = Matrix4.identity();
      initialMatrix.translate(-(canvasWidth / 2) + (screenSize.width / 2), -(canvasHeight / 2) + (screenSize.height / 2));
      _transformationController.value = initialMatrix;
      _isCanvasCentered = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Intelligence Network', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F9D58)),
      backgroundColor: const Color(0xFFF8FAFC),
      body: InteractiveViewer(
        constrained: false, boundaryMargin: const EdgeInsets.all(double.infinity), minScale: 0.2, maxScale: 1.5, transformationController: _transformationController,
        child: SizedBox(width: canvasWidth, height: canvasHeight, child: AnimatedBuilder(animation: _breathController, builder: (context, child) => Stack(clipBehavior: Clip.none, children: [
          CustomPaint(size: Size(canvasWidth, canvasHeight), painter: EdgePainter(edges: visibleEdges, nodeSize: nodeSize)),
          ...visibleNodes.map((node) => Positioned(left: node.position.dx, top: node.position.dy + sin((_breathController.value * 2 * pi) + node.randomPhase) * 8.0, child: GestureDetector(onTap: () => _handleNodeTap(node), child: _buildBeautifulNodeWidget(node)))),
        ]))),
      ),
      floatingActionButton: (_expandedClassIds.isEmpty && _focusedTeacherId == null) ? null : FloatingActionButton.extended(onPressed: () => setState(() { _expandedClassIds.clear(); _focusedTeacherId = null; _filterVisibleElements(); }), icon: const Icon(Icons.blur_circular, color: Colors.white), label: const Text('Reset Network', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: const Color(0xFF0F9D58)),
    );
  }

  Widget _buildBeautifulNodeWidget(GraphNode node) {
    Color p = Colors.blue; IconData i = Icons.face;
    bool isFocused = _expandedClassIds.contains(node.id) || _focusedTeacherId == node.id;
    if(node.type == NodeType.classNode) { p = isFocused ? Colors.purple : Colors.deepPurple; i = Icons.meeting_room; }
    else if(node.type == NodeType.teacherNode) { p = isFocused ? Colors.redAccent : Colors.orange; i = Icons.school; }
    
    return Container(width: nodeSize, height: nodeSize * 1.1, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: p.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: p.withOpacity(0.1), shape: BoxShape.circle), child: Icon(i, color: p, size: 26)), const SizedBox(height: 8), Text(node.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]));
  }
}

class EdgePainter extends CustomPainter {
  final List<GraphEdge> edges; final double nodeSize;
  EdgePainter({required this.edges, required this.nodeSize});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blueGrey.withOpacity(0.2)..strokeWidth = 2.5..style = PaintingStyle.stroke;
    for (var edge in edges) {
      final p1 = edge.source.position + Offset(nodeSize / 2, nodeSize * 0.55);
      final p2 = edge.target.position + Offset(nodeSize / 2, nodeSize * 0.55);
      final path = Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo((p1.dx + p2.dx) / 2 - (p2.dy - p1.dy) * 0.2, (p1.dy + p2.dy) / 2 + (p2.dx - p1.dx) * 0.2, p2.dx, p2.dy);
      canvas.drawPath(path, paint);
    }
  }
  @override bool shouldRepaint(covariant EdgePainter oldDelegate) => true;
}