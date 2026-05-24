import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class SpecialRequestFormPage extends StatefulWidget {
  const SpecialRequestFormPage({super.key});

  @override
  State<SpecialRequestFormPage> createState() => _SpecialRequestFormPageState();
}

class _SpecialRequestFormPageState extends State<SpecialRequestFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _othersController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  final Map<String, bool> _conditions = {
    "ADHD": false,
    "Dyslexia": false,
    "ASD": false,
    "Visual / Hearing Impairment": false,
    "None": false,
  };

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the student's name")),
      );
      return;
    }
    if (_classController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the student's class")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> selectedConditions = [];
      _conditions.forEach((key, isSelected) {
        if (isSelected) selectedConditions.add(key);
      });

      await _firestoreService.submitSpecialRequest(
        studentName: _nameController.text.trim(),
        className: _classController.text.trim(),
        conditions: selectedConditions,
        others: _othersController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text("Submitted Successfully"),
              ],
            ),
            content: Text(
              "Special request for ${_nameController.text} has been synced. "
              "The student profile is now flagged for special needs in all reports.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting request: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _othersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text("Special Request Form"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF6A1B9A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Special Request",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Does your child have any special requests or conditions?\n"
              "(This information is confidential.)\n\n"
              "Please use the same name and class as the pre-admission test "
              "so the request links to your child's profile.",
              style: TextStyle(color: Colors.blueGrey, height: 1.4),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Student Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _classController,
              decoration: const InputDecoration(
                labelText: "Class Name (e.g. Year 1 - Class A)",
                prefixIcon: Icon(Icons.class_outlined),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Conditions:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            ..._conditions.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: _conditions[key],
                activeColor: const Color(0xFF6A1B9A),
                onChanged: (val) {
                  setState(() {
                    _conditions[key] = val ?? false;

                    if (key == "None" && val == true) {
                      _conditions.updateAll((k, v) => false);
                      _conditions["None"] = true;
                    } else if (key != "None" && val == true) {
                      _conditions["None"] = false;
                    }
                  });
                },
              );
            }),

            TextField(
              controller: _othersController,
              decoration: const InputDecoration(
                labelText: "Others (optional)",
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Submit",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}