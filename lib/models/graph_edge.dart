import 'graph_node.dart';

class GraphEdge {
  final GraphNode source;
  final GraphNode target;

  GraphEdge({
    required this.source,
    required this.target,
  });
}