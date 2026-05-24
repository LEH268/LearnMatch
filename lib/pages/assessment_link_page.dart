import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'pre_admission_report.dart';
import 'class_placement_page.dart';

class AssessmentLinkPage extends StatefulWidget {
  const AssessmentLinkPage({super.key});

  @override
  State<AssessmentLinkPage> createState() => _AssessmentLinkPageState();
}

class _AssessmentLinkPageState extends State<AssessmentLinkPage> {
  static const String _assessmentLink =
      "https://learnmatch-2b5c4.web.app/#/pre-admission-test";

  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text(
          "Assessment Link 🔗",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────
            const Text(
              "Share Assessment with Students",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Send this link to students so they can complete the pre-admission assessment online. Students can access the test directly without creating an account.",
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // ── Link Card ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link_rounded, color: Color(0xFF0F9D58)),
                      SizedBox(width: 8),
                      Text(
                        "Assessment Access Link",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F9D58),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Link box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2FBFA),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: SelectableText(
                      _assessmentLink,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Copy button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            const ClipboardData(text: _assessmentLink));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text("Assessment link copied successfully!")),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text("Copy Link",
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

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ClassPlacementPage()),
                        );
                      },
                      icon: const Icon(Icons.settings_suggest_rounded),
                      label: const Text(
                        "Configure & Run Placement",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Student Reports Section ────────────
            const Text(
              "Student Reports 📋",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by student name...',
                prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Firestore stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('students')
                  .orderBy('testCompletedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final classSet = <String>{};
                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cName = data['className'] ?? 'Unassigned';
                  if (cName != 'Unassigned') classSet.add(cName);
                }
                final classList = classSet.toList()..sort();
                final filterOptions = ['All', 'Unassigned', ...classList];

                // filter and search logic
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final className = data['className'] ?? 'Unassigned';

                  // Search match
                  bool matchesSearch =
                      name.contains(_searchQuery.toLowerCase());

                  // Filter match
                  bool matchesFilter = true;
                  if (_selectedFilter == 'Unassigned') {
                    matchesFilter = className == 'Unassigned';
                  } else if (_selectedFilter != 'All') {
                    matchesFilter = className == _selectedFilter;
                  }

                  return matchesSearch && matchesFilter;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: filterOptions.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0F9D58).withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? const Color(0xFF0F9D58)
                                    : Colors.blueGrey,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (filteredDocs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.inbox_rounded,
                                size: 48, color: Colors.blueGrey),
                            SizedBox(height: 12),
                            Text(
                              "No students found matching your criteria.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: filteredDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown';
                          final className = data['className'] ?? 'Unassigned';
                          final varkRaw =
                              Map<String, int>.from(data['varkScores'] ?? {});
                          final pRaw = Map<String, int>.from(
                              data['personalityScores'] ?? {});

                          // Special-needs flag — set by special_request form
                          final hasSpecialNeeds =
                              data['hasSpecialNeeds'] == true;
                          final List<String> conditions =
                              (data['specialConditions'] as List?)
                                      ?.map((e) => e.toString())
                                      .where((s) => s != 'None')
                                      .toList() ??
                                  const [];
                          final String otherCondition =
                              (data['specialConditionsOthers'] ?? '')
                                  .toString();

                          String dominant = '-';
                          if (varkRaw.isNotEmpty) {
                            dominant = varkRaw.entries
                                .reduce((a, b) => a.value > b.value ? a : b)
                                .key;
                          }

                          final isUnassigned = className == 'Unassigned';

                          // Outline priority: special-needs > unassigned > none
                          final Border? cardBorder = hasSpecialNeeds
                              ? Border.all(
                                  color: const Color(0xFFD32F2F), width: 1.5)
                              : isUnassigned
                                  ? Border.all(
                                      color: Colors.orange.shade200)
                                  : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: cardBorder,
                              boxShadow: [
                                BoxShadow(
                                  color: hasSpecialNeeds
                                      ? const Color(0xFFD32F2F)
                                          .withOpacity(0.10)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              leading: CircleAvatar(
                                backgroundColor: hasSpecialNeeds
                                    ? const Color(0xFFD32F2F).withOpacity(0.12)
                                    : isUnassigned
                                        ? Colors.orange.shade50
                                        : Colors.blue.shade50,
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: hasSpecialNeeds
                                        ? const Color(0xFFD32F2F)
                                        : isUnassigned
                                            ? Colors.orange
                                            : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (hasSpecialNeeds)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD32F2F),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.flag_rounded,
                                              size: 12,
                                              color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'Special Needs',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    'Style: $dominant  •  Class: $className',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUnassigned
                                          ? Colors.orange.shade800
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                  if (hasSpecialNeeds &&
                                      (conditions.isNotEmpty ||
                                          otherCondition.isNotEmpty))
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '⚠ ${[...conditions, if (otherCondition.isNotEmpty) otherCondition].join(", ")}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFD32F2F),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Colors.blueGrey),
                              onTap: () {
                                final pScores = {
                                  'S': pRaw['Structured'] ?? 0,
                                  'E': pRaw['Exploratory'] ?? 0,
                                  'I': pRaw['Introvert'] ?? 0,
                                  'X': pRaw['Extrovert'] ?? 0,
                                  'P': pRaw['Impulsivity'] ?? 0,
                                  'R': pRaw['Reflectivity'] ?? 0,
                                };

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReportPage(
                                      studentName: name,
                                      varkScores: varkRaw,
                                      pScores: pScores,
                                      hasSpecialNeeds: hasSpecialNeeds,
                                      specialConditions: conditions,
                                      specialConditionsOthers:
                                          otherCondition,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}