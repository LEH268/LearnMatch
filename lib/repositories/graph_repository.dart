import 'dart:ui';

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

    // CLASSES
    for (var c in classes) {
      nodes.add(GraphNode(
        id: c.className,
        label: c.className,
        type: NodeType.classNode,
        data: c,
        position: const Offset(0, 0),
        randomPhase: 0,
      ));
    }

    // TEACHERS
    for (var t in teachers) {
      nodes.add(GraphNode(
        id: t.id,
        label: t.name,
        type: NodeType.teacherNode,
        data: t,
        position: const Offset(0, 0),
        randomPhase: 0,
      ));
    }

    // STUDENTS
    for (var s in students) {
      nodes.add(GraphNode(
        id: s.id,
        label: s.name,
        type: NodeType.studentNode,
        data: s,
        position: const Offset(0, 0),
        randomPhase: 0,
      ));
    }

    return nodes;
  }

  static List<GraphEdge> buildEdges(List<GraphNode> nodes) {
    final edges = <GraphEdge>[];

    final classNodes = nodes.where((n) => n.type == NodeType.classNode);
    final studentNodes = nodes.where((n) => n.type == NodeType.studentNode);

    for (var s in studentNodes) {
      final student = s.data as Student;

      final classNode = classNodes.firstWhere(
        (c) => c.label == student.className,
      );

      edges.add(GraphEdge(
        source: classNode,
        target: s,
      ));
    }

    return edges;
  }
}