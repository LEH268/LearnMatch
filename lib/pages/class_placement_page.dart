import 'package:flutter/material.dart';
import '../services/placement_engine.dart';

// ── Colour per VARK class ──────────────────────────
const Map<String, Color> _classColor = {
  'Class V': Color(0xFF1565C0), // Blue   — Visual
  'Class A': Color(0xFF2E7D32), // Green  — Auditory
  'Class R': Color(0xFF6A1B9A), // Purple — Read/Write
  'Class K': Color(0xFFE65100), // Orange — Kinesthetic
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

  // States: idle | previewing | confirming | done | error
  String _state = 'idle';
  String _errorMsg = '';

  List<PlacementResult> _previewResults = [];

  // Group results by class for display
  Map<String, List<PlacementResult>> get _grouped {
    final map = <String, List<PlacementResult>>{};
    for (final r in _previewResults) {
      map.putIfAbsent(r.assignedClass, () => []).add(r);
    }
    return map;
  }

  // ── Step 1: Preview ────────────────────────────
  Future<void> _runPreview() async {
    setState(() => _state = 'previewing');
    try {
      final results = await _engine.previewPlacement();
      setState(() {
        _previewResults = results;
        _state = results.isEmpty ? 'error' : 'preview_ready';
        if (results.isEmpty) _errorMsg = 'No students with assessment data found.';
      });
    } catch (e) {
      setState(() {
        _state = 'error';
        _errorMsg = e.toString();
      });
    }
  }

  // ── Step 2: Confirm & Save ─────────────────────
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

  // ── Idle ───────────────────────────────────────
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
          'LearnMatch will analyse each student\'s VARK assessment scores and automatically assign them to the most suitable class.',
          style: TextStyle(fontSize: 15, color: Colors.blueGrey, height: 1.5),
        ),
        const SizedBox(height: 32),

        // VARK legend
        ..._classColor.entries.map((e) => _buildLegendRow(e.key)),

        const Spacer(),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _runPreview,
            icon: const Icon(Icons.preview_rounded),
            label: const Text('Preview Placement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow(String className) {
    final color = _classColor[className]!;
    final icon  = _classIcon[className]!;
    const styleDesc = {
      'Class V': 'Visual learners — learn best through diagrams & videos',
      'Class A': 'Auditory learners — learn best through listening & discussion',
      'Class R': 'Read/Write learners — learn best through text & notes',
      'Class K': 'Kinesthetic learners — learn best through hands-on activities',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(className,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(styleDesc[className]!,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading ────────────────────────────────────
  Widget _buildLoadingView() {
    final msg = _state == 'confirming'
        ? 'Saving placement results...'
        : 'Analysing student profiles...';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0F9D58)),
          const SizedBox(height: 24),
          Text(msg,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Preview Ready ──────────────────────────────
  Widget _buildPreviewView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Placement Preview',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(),
            Text('${_previewResults.length} students',
                style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Review the proposed placement below. Tap Confirm to save.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            children: _grouped.entries.map((entry) {
              final color  = _classColor[entry.key] ?? Colors.grey;
              final icon   = _classIcon[entry.key]  ?? Icons.group;
              return _buildClassPreviewCard(
                  entry.key, entry.value, color, icon);
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            // Cancel
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _state = 'idle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            // Confirm
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _confirmPlacement,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Confirm Placement',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassPreviewCard(
    String className,
    List<PlacementResult> students,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(className,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 16)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${students.length} students',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ],
            ),
          ),

          // Student list
          ...students.map((s) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.10),
                  child: Text(
                    s.studentName.isNotEmpty
                        ? s.studentName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(s.studentName,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'V:${s.varkScores['V'] ?? 0}  '
                  'A:${s.varkScores['A'] ?? 0}  '
                  'R:${s.varkScores['R'] ?? 0}  '
                  'K:${s.varkScores['K'] ?? 0}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s.dominantStyle,
                      style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ),
    );
  }

  // ── Done ───────────────────────────────────────
  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F9D58).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF0F9D58), size: 72),
          ),
          const SizedBox(height: 28),
          const Text('Placement Complete! 🎉',
              style:
                  TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            '${_previewResults.length} students have been assigned to their classes.\nFirestore has been updated.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.blueGrey, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 64),
          const SizedBox(height: 20),
          const Text('Something went wrong',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _state = 'idle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}