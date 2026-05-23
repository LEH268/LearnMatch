import 'package:flutter/material.dart';

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