import 'package:flutter/material.dart';
import '../services/placement_engine.dart';
import '../services/auth_service.dart';

// ── Colour per VARK class ──────────────────────────
const Map<String, Color> _classColor = {
  'Class V': Color(0xFF1565C0),
  'Class A': Color(0xFF2E7D32),
  'Class R': Color(0xFF6A1B9A),
  'Class K': Color(0xFFE65100),
};

const Map<String, IconData> _classIcon = {
  'Class V': Icons.visibility_rounded,
  'Class A': Icons.hearing_rounded,
  'Class R': Icons.menu_book_rounded,
  'Class K': Icons.directions_run_rounded,
};

// ══════════════════════════════════════════════════
// CLASS PLACEMENT PAGE
// ══════════════════════════════════════════════════

class ClassPlacementPage extends StatefulWidget {
  const ClassPlacementPage({super.key});

  @override
  State<ClassPlacementPage> createState() => _ClassPlacementPageState();
}

class _ClassPlacementPageState extends State<ClassPlacementPage> {
  final PlacementEngine _engine = PlacementEngine();

  String _state = 'checking'; // IMPORTANT: start with checking
  String _errorMsg = '';

  List<PlacementResult> _previewResults = [];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  // ══════════════════════════════════════════════
  // ADMIN GUARD (SECURITY LAYER)
  // ══════════════════════════════════════════════
  Future<void> _checkAdmin() async {
    try {
      final role = await AuthService.getCurrentUserRole();

      if (role != 'admin') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access denied: Admin only')),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _state = 'idle';
      });
    } catch (e) {
      setState(() {
        _state = 'error';
        _errorMsg = e.toString();
      });
    }
  }

  // ── Preview ────────────────────────────────────
  Future<void> _runPreview() async {
    setState(() => _state = 'previewing');
    try {
      final results = await _engine.previewPlacement();

      setState(() {
        _previewResults = results;
        _state = results.isEmpty ? 'error' : 'preview_ready';
        if (results.isEmpty) {
          _errorMsg = 'No students with assessment data found.';
        }
      });
    } catch (e) {
      setState(() {
        _state = 'error';
        _errorMsg = e.toString();
      });
    }
  }

  // ── Confirm ────────────────────────────────────
  Future<void> _confirmPlacement() async {
    setState(() => _state = 'confirming');
    try {
      await _engine.runPlacement();
      setState(() => _state = 'done');
    } catch (e) {
      setState(() {
        _state = 'error';
        _errorMsg = e.toString();
      });
    }
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_state == 'checking') {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF0F9D58),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Class Placement 🚀',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        foregroundColor: const Color(0xFF0F9D58),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case 'idle':
        return _buildIdleView();
      case 'previewing':
      case 'confirming':
        return _buildLoadingView();
      case 'preview_ready':
        return _buildPreviewView();
      case 'done':
        return _buildDoneView();
      case 'error':
        return _buildErrorView();
      default:
        return _buildIdleView();
    }
  }

  // ── Idle View ──────────────────────────────────
  Widget _buildIdleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'One-Click Class Placement',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        const Text(
          'AI will analyse student VARK profiles and assign optimal classes.',
          style: TextStyle(fontSize: 15, color: Colors.blueGrey),
        ),
        const SizedBox(height: 32),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _runPreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text(
              "Preview Placement",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loading ────────────────────────────────────
  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0F9D58),
      ),
    );
  }

  // ── Preview ────────────────────────────────────
  Widget _buildPreviewView() {
    return Column(
      children: [
        const Text(
          "Preview Ready",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: _previewResults.length,
            itemBuilder: (context, index) {
              final s = _previewResults[index];
              return ListTile(
                title: Text(s.studentName),
                subtitle: Text(s.assignedClass),
              );
            },
          ),
        ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _state = 'idle'),
                child: const Text("Cancel"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmPlacement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                ),
                child: const Text("Confirm"),
              ),
            ),
          ],
        )
      ],
    );
  }

  // ── Done ───────────────────────────────────────
  Widget _buildDoneView() {
    return const Center(
      child: Text(
        "Placement Completed 🎉",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Error ──────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Text(_errorMsg),
    );
  }
}