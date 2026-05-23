import 'dart:math';
import 'package:flutter/material.dart';

import '../models/student.dart' hide GraphEdge, NodeType, GraphNode, Teacher, ClassGroup;
import '../models/teacher.dart';
import '../models/class_group.dart';
import '../models/graph_node.dart';
import '../models/graph_edge.dart';

class GraphBuilder {

  static Map<String, dynamic> buildGraph() {

    final List<GraphNode> nodes = [];
    final List<GraphEdge> edges = [];

    final center = const Offset(1600, 1600);
    final random = Random();

    // ================= CLASS =================
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

    nodes.addAll([classNodeA, classNodeB]);

    // ================= TEACHERS =================
    final teacher1 = Teacher(
      id: 'T001',
      name: 'Mr. Anderson',
      subjects: ['Math'],
      classesTaught: ['Class A', 'Class B'],
    );

    final teacherNode1 = GraphNode(
      id: teacher1.id,
      label: teacher1.name,
      type: NodeType.teacherNode,
      data: teacher1,
      position: center + const Offset(0, -420),
      randomPhase: random.nextDouble() * pi * 2,
    );

    nodes.add(teacherNode1);

    // edges teacher → class
    edges.add(GraphEdge(source: teacherNode1, target: classNodeA));
    edges.add(GraphEdge(source: teacherNode1, target: classNodeB));

    // ================= STUDENTS =================
    final students = [
      Student(
        id: 'S1',
        name: 'Alice',
        className: 'Class A',
        grades: 'A',
        basicInfo: '',
        emergencyContact: '',
        specialConditions: '',
        aiCognitiveAnalysis: 'Strong logic',
        aiAdaptivePath: 'Advanced path',
      ),
    ];

    for (var s in students) {

      final classNode = s.className == 'Class A'
          ? classNodeA
          : classNodeB;

      final node = GraphNode(
        id: s.id,
        label: s.name,
        type: NodeType.studentNode,
        data: s,
        position: classNode.position + Offset(100, 100),
        randomPhase: random.nextDouble() * pi * 2,
      );

      nodes.add(node);
      edges.add(GraphEdge(source: classNode, target: node));
    }

    return {
      "nodes": nodes,
      "edges": edges,
    };
  }
}