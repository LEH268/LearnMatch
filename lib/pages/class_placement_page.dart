import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/placement_engine.dart';

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

  String _state = 'idle';
  String _errorMsg = '';

  List<PlacementResult> _previewResults = [];
  List<Map<String, dynamic>> _existingClasses = [];
  bool _loadingClasses = true;

  final TextEditingController _classNameController = TextEditingController();
  String _selectedTargetVark = 'V'; // 默认目标群体是 V

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
            'targetVARK': data['targetVARK'] ?? 'V', // 获取偏好
          };
        }).toList();
        _loadingClasses = false;
      });
    } catch (e) {
      setState(() => _loadingClasses = false);
    }
  }

  // ── Create a new class with target VARK ─────────────
  Future<void> _createClass(String className) async {
    if (className.trim().isEmpty) return;
    try {
      await _db.collection('classes').doc(className.trim()).set({
        'className': className.trim(),
        'targetVARK': _selectedTargetVark, // 存储目标VARK群体
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

  Map<String, List<PlacementResult>> get _grouped {
    final map = <String, List<PlacementResult>>{};
    for (final r in _previewResults) {
      map.putIfAbsent(r.assignedClass, () => []).add(r);
    }
    return map;
  }

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
      case 'idle': return _buildIdleView();
      case 'previewing':
      case 'confirming': return _buildLoadingView();
      case 'preview_ready': return _buildPreviewView();
      case 'done': return _buildDoneView();
      case 'error': return _buildErrorView();
      default: return _buildIdleView();
    }
  }

  Widget _buildIdleView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Class Placement Settings',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create classes and configure their target VARK learning style before running the AI placement.',
          style: TextStyle(fontSize: 14, color: Colors.blueGrey, height: 1.5),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Step 1: Setup Classes', Icons.add_circle_outline_rounded, const Color(0xFF0F9D58)),
        const SizedBox(height: 12),

        // 班级创建输入框和类型下拉
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _classNameController,
                decoration: InputDecoration(
                  hintText: 'Class Name (e.g. Year 1 Alpha)',
                  hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                onSubmitted: (v) => _createClass(v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedTargetVark,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: const [
                  DropdownMenuItem(value: 'V', child: Text('Target: V')),
                  DropdownMenuItem(value: 'A', child: Text('Target: A')),
                  DropdownMenuItem(value: 'R', child: Text('Target: R')),
                  DropdownMenuItem(value: 'K', child: Text('Target: K')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTargetVark = val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _createClass(_classNameController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Add Class', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),

        const SizedBox(height: 20),

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
                  '${_existingClasses.length} class(es) configured',
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
                    label: const Text('Preview AI Placement',
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
              'No classes yet. Add classes and set their target VARK style before running placement.',
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
    final target = classData['targetVARK'] as String;

    Color color;
    IconData icon;
    switch(target) {
      case 'V': color = const Color(0xFF1565C0); icon = Icons.visibility_rounded; break;
      case 'A': color = const Color(0xFF2E7D32); icon = Icons.hearing_rounded; break;
      case 'R': color = const Color(0xFF6A1B9A); icon = Icons.menu_book_rounded; break;
      case 'K': color = const Color(0xFFE65100); icon = Icons.directions_run_rounded; break;
      default: color = Colors.blueGrey; icon = Icons.class_rounded; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
                Text('Target: $target Style', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count stds', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteClass(classData['id'], name),
          ),
        ],
      ),
    );
  }

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
          Text(msg, style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPreviewView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Placement Preview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(),
            Text('${_previewResults.length} students', style: const TextStyle(color: Colors.blueGrey)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Review the proposed placement based on target VARK. Tap Confirm to save.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: ListView(
            children: _grouped.entries.map((entry) {
              return _buildClassPreviewCard(entry.key, entry.value);
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                label: const Text('Confirm Placement', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F9D58),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClassPreviewCard(String className, List<PlacementResult> students) {
    Color color = Colors.blueGrey;
    if (className == 'Unassigned') color = Colors.orange;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.class_rounded, color: color),
                const SizedBox(width: 10),
                Text(className, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
                const Spacer(),
                Text('${students.length} students', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
          ...students.map((s) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.10),
                  child: Text(
                    s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(s.studentName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Score: V:${s.varkScores['V']} A:${s.varkScores['A']} R:${s.varkScores['R']} K:${s.varkScores['K']}', style: const TextStyle(fontSize: 12)),
                trailing: Text(s.dominantStyle, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              )),
        ],
      ),
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: const Color(0xFF0F9D58).withOpacity(0.10), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0F9D58), size: 72),
          ),
          const SizedBox(height: 28),
          const Text('Placement Complete! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            '${_previewResults.length} students have been assigned to their classes.\nFirestore has been updated.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 15, height: 1.5),
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
              label: const Text('Back to Classes', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F9D58),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
          const SizedBox(height: 20),
          const Text('Something went wrong', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_errorMsg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => setState(() => _state = 'idle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F9D58),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}