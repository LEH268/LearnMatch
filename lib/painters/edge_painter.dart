import 'dart:math';
import 'package:flutter/material.dart';

import '../models/graph_edge.dart';
import '../models/graph_node.dart';

// =====================================================
// EDGE PAINTER
// Matches the original hardcoded design:
//   Teacher ↔ Class  → soft orange line with orangeAccent glow
//   Student ↔ Class  → vivid blue line with cyan glow
// =====================================================

class EdgePainter extends CustomPainter {
  final List<GraphEdge> edges;
  final double nodeSize;

  EdgePainter({
    required this.edges,
    this.nodeSize = 110,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(10);

    for (var edge in edges) {
      // A teacher edge is any edge that has a teacher node on either side.
      final bool isTeacherConnection =
          edge.source.type == NodeType.teacherNode ||
              edge.target.type == NodeType.teacherNode;

      // Icon center on the node card
      final start = edge.source.position + Offset(nodeSize / 2, 34);
      final end = edge.target.position + Offset(nodeSize / 2, 34);

      // Build a softly curved Bezier
      final midPoint = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final curveOffset = random.nextDouble() * 80 - 40;

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

      // GLOW layer
      final glowPaint = Paint()
        ..color = isTeacherConnection
            ? Colors.orangeAccent.withOpacity(0.22)
            : Colors.cyanAccent.withOpacity(0.20)
        ..strokeWidth = 14
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          12,
        );

      // MAIN line
      final linePaint = Paint()
        ..color = isTeacherConnection
            ? Colors.orange.shade200
            : const Color.fromARGB(255, 0, 102, 255).withOpacity(0.78)
        ..strokeWidth = 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}