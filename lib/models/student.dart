class Student {
  final String id;
  final String name;
  final String className;
  final String emergencyContact;
  final Map<String, int> varkScores;
  final Map<String, int> personalityScores;

  Student({
    required this.id,
    required this.name,
    required this.className,
    required this.emergencyContact,
    this.varkScores = const {},
    this.personalityScores = const {},
  });
}