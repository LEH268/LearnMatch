import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/placement_engine.dart';

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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // States: idle | creating_classes | previewing | confirming | done | error
  String _state = 'idle';
  String _errorMsg = '';

  List<PlacementResult> _previewResults = [];

  // ── Existing classes from Firestore ───────────────
  List<Map<String, dynamic>> _existingClasses = [];
  bool _loadingClasses = true;

  // ── New class creation ────────────────────────────
  final TextEditingController _classNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExistingClasses();
  }

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final snap = await _db.collection('classes').get();
      setState(() {
        _existingClasses = snap.docs.map((d) {
          final data = d.data();
          return {
            'id': d.id,
            'className': data['className'] ?? d.id,
            'studentCount': data['studentCount'] ?? 0,
            'learningStyle': data['learningStyle'] ?? '',
          };
        }).toList();
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() => _loadingClasses = false);
    }
  }

  // ── Create a new class ────────────────────────────
  Future<void> _createClass(String className) async {
    if (className.trim().isEmpty) return;
    try {
      await _db.collection('classes').doc(className.trim()).set({
        'className': className.trim(),
        'studentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _classNameController.clear();
      await _loadExistingClasses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Class "$className" created!'),
            backgroundColor: const Color(0xFF0F9D58),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Delete a class ────────────────────────────────
  Future<void> _deleteClass(String classId, String className) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Class'),
        content: Text('Are you sure you want to delete "$className"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('classes').doc(classId).delete();
      await _loadExistingClasses();
    }
  }

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
    if (_existingClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create at least one class before placement.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _state = 'previewing');
    try {
      final results = await _engine.previewPlacement(_existingClasses);
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
      await _engine.runPlacement(_existingClasses);
      await _loadExistingClasses();
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

  // ── Idle (Main screen with class management) ───
  Widget _buildIdleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Placement',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'First create your classes, then run the AI placement to assign students based on VARK scores and personality.',
          style: TextStyle(fontSize: 14, color: Colors.blueGrey, height: 1.5),
        ),
        const SizedBox(height: 24),

        // ── Step 1: Create Classes ───────────────
        _buildSectionHeader('Step 1: Create Classes', Icons.add_circle_outline_rounded, const Color(0xFF0F9D58)),
        const SizedBox(height: 12),

        // Create class input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _classNameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Class A, Kelas Bijak...',
                  hintStyle: const TextStyle(color: Colors.blueGrey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0F9D58)),
                  ),
                ),
                onSubmitted: (v) => _createClass(v),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _createClass(_classNameController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Existing classes list
        if (_loadingClasses)
          const Center(child: CircularProgressIndicator(color: Color(0xFF0F9D58)))
        else if (_existingClasses.isEmpty)
          _buildEmptyClassesHint()
        else
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_existingClasses.length} class(es) created',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: _existingClasses.length,
                    itemBuilder: (_, i) => _buildClassTile(_existingClasses[i]),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('Step 2: Run Placement', Icons.auto_awesome_rounded, Colors.deepPurple),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _runPreview,
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text('Preview Placement',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyClassesHint() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No classes yet. Create at least one class above before running placement.',
              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTile(Map<String, dynamic> classData) {
    final name = classData['className'] as String;
    final count = classData['studentCount'] as int;
    final style = classData['learningStyle'] as String;

    // Pick color based on known VARK class names or just cycle
    Color color = const Color(0xFF0F9D58);
    if (_classColor.containsKey(name)) {
      color = _classColor[name]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _classIcon[name] ?? Icons.class_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    )),
                if (style.isNotEmpty)
                  Text(style,
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count students',
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteClass(classData['id'], name),
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
              final color = _classColor[entry.key] ?? Colors.grey;
              final icon = _classIcon[entry.key] ?? Icons.group;
              return _buildClassPreviewCard(
                  entry.key, entry.value, color, icon);
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
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
              onPressed: () {
                setState(() => _state = 'idle');
                _loadExistingClasses();
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to Classes',
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