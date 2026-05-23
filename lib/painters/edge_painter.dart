import 'dart:math';
import 'package:flutter/material.dart';
import '../models/graph_edge.dart';
import '../models/graph_node.dart';

class EdgePainter extends CustomPainter {

  final List<GraphEdge> edges;

  EdgePainter(this.edges);

  @override
  void paint(Canvas canvas, Size size) {

    final random = Random(10);

    for (var edge in edges) {

      final start = edge.source.position + const Offset(55, 40);
      final end = edge.target.position + const Offset(55, 40);

      final mid = Offset(
        (start.dx + end.dx) / 2,
        (start.dy + end.dy) / 2,
      );

      final control = Offset(
        mid.dx + random.nextDouble() * 60 - 30,
        mid.dy - 40,
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          control.dx,
          control.dy,
          end.dx,
          end.dy,
        );

      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.5)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}