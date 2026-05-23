import 'dart:math';
import 'package:flutter/material.dart';

import '../models/graph_edge.dart';
import '../models/graph_node.dart';

class EdgePainter extends CustomPainter {
  final List<GraphEdge> edges;
  final double nodeSize;

  EdgePainter({
    required this.edges,
    this.nodeSize = 110,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    for (var edge in edges) {
      final bool isTeacherEdge = edge.source.type == NodeType.teacherNode || edge.target.type == NodeType.teacherNode;

      final start = edge.source.position + Offset(nodeSize / 2, 34);
      final end   = edge.target.position + Offset(nodeSize / 2, 34);

      final mid = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final curveOffset = random.nextDouble() * 80 - 40;
      final control = Offset(mid.dx + curveOffset, mid.dy - 40);

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);

      // Glow layer
      canvas.drawPath(
        path,
        Paint()
          ..color = isTeacherEdge
              ? Colors.orangeAccent.withOpacity(0.22)
              : Colors.cyanAccent.withOpacity(0.20)
          ..strokeWidth = 14
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Main line
      canvas.drawPath(
        path,
        Paint()
          ..color = isTeacherEdge
              ? Colors.orange.shade200
              : const Color(0xFF0066FF).withOpacity(0.78)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}