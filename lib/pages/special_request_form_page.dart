import 'package:flutter/material.dart';

class SpecialRequestFormPage extends StatefulWidget {
  const SpecialRequestFormPage({super.key});

  @override
  State<SpecialRequestFormPage> createState() => _SpecialRequestFormPageState();
}

class _SpecialRequestFormPageState extends State<SpecialRequestFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _othersController = TextEditingController();

  final Map<String, bool> _conditions = {
    "ADHD": false,
    "Dyslexia": false,
    "ASD": false,
    "Visual / Hearing Impairment": false,
    "None": false,
  };

  void _submit() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submitted"),
        content: const Text("Special request has been recorded."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
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
              "Do your child have any special requests or conditions?\n(This information is confidential.)",
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Student Name"),
            ),

            TextField(
              controller: _contactController,
              decoration: const InputDecoration(labelText: "Emergency Contact"),
            ),

            const SizedBox(height: 20),

            const Text("Conditions:", style: TextStyle(fontWeight: FontWeight.bold)),

            ..._conditions.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: _conditions[key],
                onChanged: (val) {
                  setState(() {
                    _conditions[key] = val ?? false;

                    if (key == "None" && val == true) {
                      _conditions.updateAll((k, v) => false);
                      _conditions["None"] = true;
                    }
                  });
                },
              );
            }),

            TextField(
              controller: _othersController,
              decoration: const InputDecoration(labelText: "Others (optional)"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}