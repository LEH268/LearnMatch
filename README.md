# LearnMatch

> An AI-powered class management system for teachers and school administrators. Match every student with the class, classmates, and learning style that fit them best.

LearnMatch is a Flutter web application that helps schools move beyond intuition-based class assignment. It uses learning-style assessments, special-needs flagging, and Google Gemini AI to give teachers a clear picture of each student and an evidence-backed recommendation for class placement.

🔗 **Live demo:** https://learnmatch-2b5c4.web.app

---

## ✨ Features

### 📝 Pre-admission Assessment
A login-free link parents and incoming students can open on any device. The form measures:
- **VARK learning style** — Visual, Auditory, Read/Write, Kinesthetic
- **Personality profile** — Structured/Exploratory, Introvert/Extrovert, Impulsivity/Reflectivity

Results are saved to Firestore and used as the foundation for placement.

### 🎯 AI-Driven Class Placement
Admin defines the school's classes (e.g. *Year 1 - Class A*, *Year 2 - Bijak*) and the VARK style each class is best suited for. With **one click**, the system:
- Pulls every unassigned student's dominant VARK
- Matches them to the best class
- Load-balances across same-VARK classes (useful for multi-year schools)
- Leaves already-placed students alone — no shuffling

### 🕸️ Class Intelligence Network
A draggable, zoomable graph that visualises the relationships between classes, teachers, and students.
- 🟣 Class nodes — tap to expand and reveal students
- 🟠 Teacher nodes — tap to focus on classes they teach
- 🔵 Student nodes — tap for full AI cognitive profile
- 🔴 Special-needs students are highlighted in red
- Glowing orange edges = teacher↔class; glowing blue edges = student↔class
- Long-press a teacher to delete; admin can also add teachers via the toolbar

### 📊 Class Fit Analyzer (Annual Re-streaming)
At year end, the system combines three independent signals to decide whether a student should stay or move:

| Signal | Source | Weight |
|--------|--------|--------|
| **Academic Performance** | Teacher-entered grades (H1 + H2) | 40% |
| **Student AI Score** | Gemini reads the student's written end-of-year reflection and scores 1–5 per question | 30% |
| **Teacher AI Score** | Gemini reads the teacher's free-text observation and scores it 0–100 | 30% |

The blended **Class Fit Score** (0–100) drives the final recommendation: *Great fit / Acceptable / Mismatch / Serious mismatch.*

### 🫂 Special Request Form
A private link for parents to declare conditions like ADHD, Dyslexia, ASD, or sensory impairments. The system:
- Matches the submission to the existing student record (name + class)
- Flags the student in red across **every** report and the network graph
- Lists the specific conditions in the student's profile

### 📋 Student Reports Dashboard
A searchable, filterable list of every student. Filter by class or status (submitted/pending), search by name, and see at a glance:
- 🚩 Red badge if special needs are flagged
- 🟠 Orange outline if unassigned
- Dominant VARK letter and current class

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart SDK ^3.11) |
| State | StatefulWidget + StreamBuilder (no external state lib) |
| Backend | Firebase (Auth + Cloud Firestore) |
| AI | Google Generative AI (Gemini 2.5 Flash) |
| Hosting | Firebase Hosting |
| Platforms | Web (primary), Android, iOS, macOS, Linux, Windows |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.11 or higher
- [Firebase CLI](https://firebase.google.com/docs/cli) for deployment
- A Firebase project with Firestore enabled
- A [Google AI Studio](https://aistudio.google.com/) API key for Gemini (free tier works)

### 1. Clone & install dependencies
```bash
git clone https://github.com/LEH268/LearnMatch.git
cd LearnMatch
flutter pub get
```

### 2. Configure Firebase
The repo already contains a `firebase_options.dart` for the demo project. To run against your own Firebase project:
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
This regenerates `lib/firebase_options.dart` with your project's credentials.

### 3. Add your Gemini API key
The Gemini API key is empty by default. Open these three files and paste your key into the `apiKey: ''` field:

- `lib/pages/pre_admission_report.dart`
- `lib/pages/student_follow_up_page.dart`
- `lib/pages/student_evaluation_form.dart`

> ⚠️ For production, move the key into environment variables or a backend proxy. Embedding API keys in client code is fine for school-internal projects but **never** for public apps.

### 4. Run locally
```bash
# Chrome
flutter run -d chrome

# Or pick a platform
flutter run -d macos     # or windows, linux, android, ios
```

### 5. Deploy to Firebase Hosting
```bash
flutter build web
firebase deploy --only hosting
```

---

## 📁 Project Structure

```
lib/
├── main.dart                       # App entry & routing
├── firebase_options.dart           # Auto-generated Firebase config
│
├── pages/                          # All screens
│   ├── login_page.dart             # Teacher login
│   ├── signup_page.dart            # Teacher signup
│   ├── home_page.dart              # Teacher dashboard (4 feature cards)
│   │
│   ├── assessment_link_page.dart   # Pre-admission link + reports list
│   ├── pre_admission_test.dart     # Student-facing VARK/personality test
│   ├── pre_admission_report.dart   # Individual student AI profile
│   │
│   ├── class_placement_page.dart   # Admin: create classes + run placement
│   ├── class_network_page.dart     # Class intelligence graph
│   │
│   ├── student_follow_up_page.dart # Year-end re-streaming with 3-source AI fit
│   ├── student_evaluation_form.dart # Student end-of-year reflection
│   │
│   ├── special_request_link_page.dart   # Admin: share special-request link
│   └── special_request_form_page.dart   # Parent-facing conditions form
│
├── models/                         # Plain data classes
│   ├── student.dart
│   ├── teacher.dart
│   ├── class_group.dart
│   └── graph_node.dart / graph_edge.dart
│
├── services/
│   ├── firestore_service.dart      # All Firestore reads/writes
│   └── placement_engine.dart       # VARK-matching + load-balancing logic
│
├── repositories/
│   └── graph_repository.dart       # Builds nodes/edges from Firestore
│
└── painters/
    └── edge_painter.dart           # Custom-painted glowing connections
```

---

## 🗄️ Data Model

The entire app runs on three Firestore collections.

### `students` (one doc per student)
```json
{
  "name": "Alice Brown",
  "className": "Year 1 - Class A",
  "emergencyContact": "012-3456789",
  "varkScores":         { "V": 8, "A": 3, "R": 5, "K": 2 },
  "personalityScores":  { "Structured": 6, "Exploratory": 4, ... },
  "dominantStyle": "Visual",
  "hasSpecialNeeds": true,
  "specialConditions": ["ADHD"],
  "hasSubmittedForm": true,
  "evaluationScore": 21,
  "detailedAnswers": [4, 5, 4, 5, 3],
  "writtenAnswers": [ "I enjoyed working with my friends...", ... ],
  "testCompletedAt": <timestamp>,
  "placedAt": <timestamp>
}
```

### `classes` (one doc per class, doc id = class name)
```json
{
  "className": "Year 1 - Class A",
  "varkType": "V",
  "studentIds": [ "abc123", "def456", ... ],
  "studentCount": 18
}
```

### `teachers`
```json
{
  "name": "Mr. Anderson",
  "subjects": ["Mathematics"],
  "classesTaught": ["Year 1 - Class A", "Year 1 - Class B"]
}
```

---

## 🔄 Typical Workflow

1. **Set up classes** — Admin opens *Configure & Run Placement* → adds class names and picks a VARK type for each.
2. **Send the assessment link** — Each incoming student fills the pre-admission test from any device.
3. **Run placement** — One click; unassigned students get matched to their best-fit class.
4. **Collect special requests** — Parents submit conditions via the special-request link; flagged in red everywhere.
5. **Build the network graph** — Teachers get added through *Add Teacher* on the network page.
6. **Year-end re-streaming** — Teacher enters grades, syncs the student's evaluation, writes their own observation; AI returns a combined Class Fit Score and recommendation.

---

## 🤝 Contributing

This started as a school project, but contributions are welcome.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/awesome-thing`)
3. Commit your changes with descriptive messages
4. Open a pull request

If you're filing a bug, please include:
- What you expected to happen
- What actually happened
- A screenshot if it's a UI issue
- Your platform (web/android/ios) and Flutter version

---

## 📜 License

Licensed for educational use by the LearnMatch authors. Contact the maintainers for commercial use.

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev/) for the cross-platform framework
- [Firebase](https://firebase.google.com/) for auth, Firestore, and hosting
- [Google Generative AI](https://ai.google.dev/) for Gemini
- The VARK learning-style framework by Neil Fleming
