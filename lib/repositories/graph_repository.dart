import 'dart:math';
import 'package:flutter/material.dart';

import '../models/graph_node.dart';
import '../models/graph_edge.dart';
import '../models/student.dart' hide GraphNode, Teacher, ClassGroup, NodeType, GraphEdge;
import '../models/teacher.dart';
import '../models/class_group.dart';

class GraphRepository {
  static List<GraphNode> buildNodes(
    List<Student> students,
    List<Teacher> teachers,
    List<ClassGroup> classes,
  ) {
    final nodes = <GraphNode>[];
    final random = Random();

    final double canvasCenterX = 1600;
    final double canvasCenterY = 1600;

    // ── CLASS NODES ────────────────────────────────────
    for (int i = 0; i < classes.length; i++) {
      final angle = (2 * pi * i) / classes.length;
      final radius = 520.0;

      nodes.add(GraphNode(
        id: 'CLASS_${classes[i].className}',
        label: classes[i].className,
        type: NodeType.classNode,
        data: classes[i],
        position: Offset(
          canvasCenterX + cos(angle) * radius,
          canvasCenterY + sin(angle) * radius,
        ),
        randomPhase: random.nextDouble() * pi * 2,
      ));
    }

    // ── TEACHER NODES ──────────────────────────────────
    for (int i = 0; i < teachers.length; i++) {
      final angle = (2 * pi * i) / teachers.length - pi / 2;
      final radius = 280.0;

      nodes.add(GraphNode(
        id: teachers[i].id,
        label: teachers[i].name,
        type: NodeType.teacherNode,
        data: teachers[i],
        position: Offset(
          canvasCenterX + cos(angle) * radius,
          canvasCenterY + sin(angle) * radius,
        ),
        randomPhase: random.nextDouble() * pi * 2,
      ));
    }

    // ── STUDENT NODES ──────────────────────────────────
    // Group by className
    final Map<String, List<Student>> grouped = {};
    for (var s in students) {
      grouped.putIfAbsent(s.className, () => []).add(s);
    }

    grouped.forEach((className, studentList) {
      // Find the parent class node
      final classNodeMatches = nodes.where(
        (n) => n.type == NodeType.classNode && n.label == className,
      ).toList();

      if (classNodeMatches.isEmpty) return;
      final classNode = classNodeMatches.first;

      for (int i = 0; i < studentList.length; i++) {
        final angle = (2 * pi * i) / studentList.length;
        final radius = 260 + random.nextInt(80).toDouble();

        nodes.add(GraphNode(
          id: studentList[i].id,
          label: studentList[i].name,
          type: NodeType.studentNode,
          data: studentList[i],
          position: classNode.position +
              Offset(
                cos(angle) * radius,
                sin(angle) * radius,
              ),
          randomPhase: random.nextDouble() * pi * 2,
        ));
      }
    });

    return nodes;
  }

  static List<GraphEdge> buildEdges(List<GraphNode> nodes) {
    final edges = <GraphEdge>[];

    final classNodes = nodes.where((n) => n.type == NodeType.classNode).toList();
    final teacherNodes = nodes.where((n) => n.type == NodeType.teacherNode).toList();
    final studentNodes = nodes.where((n) => n.type == NodeType.studentNode).toList();

    // Student → Class edges
    for (var sNode in studentNodes) {
      final student = sNode.data as Student;
      final classMatches = classNodes.where((c) => c.label == student.className).toList();
      if (classMatches.isNotEmpty) {
        edges.add(GraphEdge(source: classMatches.first, target: sNode));
      }
    }

    // Teacher → Class edges
    for (var tNode in teacherNodes) {
      final teacher = tNode.data as Teacher;
      for (var className in teacher.classesTaught) {
        final classMatches = classNodes.where((c) => c.label == className).toList();
        if (classMatches.isNotEmpty) {
          edges.add(GraphEdge(source: tNode, target: classMatches.first));
        }
      }
    }

    return edges;
  }
}