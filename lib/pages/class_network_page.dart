import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student.dart' hide GraphNode, EdgePainter, Teacher, ClassGroup, GraphEdge;
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

class _ClassNetworkPageState extends State<ClassNetworkPage> {
  final FirestoreService _service = FirestoreService();

  List<GraphNode> nodes = [];
  List<GraphEdge> edges = [];

  bool _isLoading = true;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Class Intelligence Network"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _service.getStudentsStream(),

        builder: (context, studentSnapshot) {

          // =========================
          // ERROR HANDLING
          // =========================
          if (studentSnapshot.hasError) {
            return Center(
              child: Text(
                "Firestore Error: ${studentSnapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!studentSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // =========================
          // STUDENTS
          // =========================
          final students = studentSnapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            return Student(
              id: doc.id,
              name: data['name'] ?? 'Unknown',
              className: data['className'] ?? 'Class A',
              grades: data['grades'] ?? '',
              basicInfo: '',
              emergencyContact: '',
              specialConditions: '',
              aiCognitiveAnalysis: '',
              aiAdaptivePath: '',
            );
          }).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: _service.getTeachersStream(),

            builder: (context, teacherSnapshot) {

              if (teacherSnapshot.hasError) {
                return Center(
                  child: Text(
                    "Teacher Stream Error: ${teacherSnapshot.error}",
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!teacherSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // =========================
              // TEACHERS
              // =========================
              final teachers = teacherSnapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return Teacher(
                  id: doc.id,
                  name: data['name'] ?? '',
                  subjects: List<String>.from(data['subjects'] ?? []),
                  classesTaught: List<String>.from(data['classesTaught'] ?? []),
                );
              }).toList();

              // =========================
              // CLASSES (STATIC FOR NOW)
              // =========================
              final classes = [
                ClassGroup(className: "Class A"),
                ClassGroup(className: "Class B"),
              ];

              // =========================
              // BUILD GRAPH
              // =========================
              nodes = GraphRepository.buildNodes(
                students,
                teachers,
                classes,
              );

              edges = GraphRepository.buildEdges(nodes);

              // =========================
              // EMPTY STATE HANDLING
              // =========================
              if (nodes.isEmpty) {
                return const Center(
                  child: Text(
                    "No data found in Firestore.\nAdd students/teachers first.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              // =========================
              // MAIN GRAPH UI
              // =========================
              return Stack(
                children: [
                  // EDGES
                  CustomPaint(
                    size: Size.infinite,
                    painter: EdgePainter(edges),
                  ),

                  // NODES
                  ...nodes.map((node) {
                    return Positioned(
                      left: 80 + (node.id.hashCode.abs() % 600),
                      top: 120 + (node.id.hashCode.abs() % 800),

                      child: GestureDetector(
                        onTap: () {
                          _showNodeDialog(node);
                        },

                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Text(
                            node.label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // =========================
  // NODE POPUP
  // =========================
  void _showNodeDialog(GraphNode node) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(node.label),
        content: Text("Type: ${node.type}\nID: ${node.id}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          )
        ],
      ),
    );
  }
}