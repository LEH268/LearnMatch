import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // IMPORT: Firestore database
import 'pre_admission_report.dart';

class PreAdmissionTestPage extends StatefulWidget {
  const PreAdmissionTestPage({super.key});

  @override
  State<PreAdmissionTestPage> createState() => _PreAdmissionTestPageState();
}

class _PreAdmissionTestPageState extends State<PreAdmissionTestPage> {
  int _currentIndex = 0;

  final Map<String, int> _varkScores = {'V': 0, 'A': 0, 'R': 0, 'K': 0};

  int _structuredScore = 0;
  int _exploratoryScore = 0;
  int _introvertScore = 0;
  int _extrovertScore = 0;
  int _impulsivityScore = 0;
  int _reflectivityScore = 0;

  // Student Info Variables
  String _studentName = "";
  String _emergencyContact = "";
  bool _started = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'theme': 'Theme 1: Acquiring New Knowledge',
      'question': '1. You just bought a complicated new board game. How do you learn the rules?',
      'options': [
        {'text': 'Read the printed rulebook carefully from start to finish before touching the pieces.', 'tags': ['R', 'Structured', 'Reflectivity']},
        {'text': 'Watch an animated YouTube tutorial showing how the game is played.', 'tags': ['V', 'Introvert']},
        {'text': 'Ask a friend who already knows the game to explain it to you.', 'tags': ['A', 'Extrovert']},
        {'text': 'Just set up the board and figure it out as you play the first round.', 'tags': ['K', 'Exploratory', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 1: Acquiring New Knowledge',
      'question': '2. You are studying for a major History exam. Which method works best for you?',
      'options': [
        {'text': 'Redrawing timelines and color-coding maps of historical events.', 'tags': ['V', 'Structured']},
        {'text': 'Listening to a history podcast or discussing the events with classmates.', 'tags': ['A', 'Extrovert']},
        {'text': 'Rewriting your textbook notes and summarizing paragraphs.', 'tags': ['R', 'Reflectivity', 'Introvert']},
        {'text': 'Walking around the room while reciting facts or acting out the events.', 'tags': ['K', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 1: Acquiring New Knowledge',
      'question': '3. You are visiting a large, unfamiliar city. How do you navigate?',
      'options': [
        {'text': 'Write down a detailed itinerary with a list of street names and subway stops.', 'tags': ['R', 'Structured', 'Reflectivity']},
        {'text': 'Look at the city map to understand the overall layout and landmarks.', 'tags': ['V', 'Structured']},
        {'text': 'Walk around and ask locals for directions when you need to.', 'tags': ['A', 'Extrovert', 'Exploratory']},
        {'text': 'Put your phone away and just wander around to see where you end up.', 'tags': ['K', 'Exploratory', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 1: Acquiring New Knowledge',
      'question': '4. The teacher introduces a brand new, complex science concept. How do you confirm you understand it?',
      'options': [
        {'text': 'You write a detailed summary of the concept in your notebook.', 'tags': ['R', 'Reflectivity']},
        {'text': 'You picture the scientific diagram or model in your head.', 'tags': ['V', 'Introvert']},
        {'text': 'You try to explain the concept aloud to the person sitting next to you.', 'tags': ['A', 'Extrovert']},
        {'text': 'You immediately start an experiment or try solving a practice question.', 'tags': ['K', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 1: Acquiring New Knowledge',
      'question': '5. How do you prefer to memorize a new password?',
      'options': [
        {'text': 'Picture the pattern your fingers make on the keyboard.', 'tags': ['V', 'Kinesthetic']},
        {'text': 'Repeat the numbers/letters aloud several times.', 'tags': ['A', 'Impulsivity']},
        {'text': 'Write the password down on a piece of paper to lock it into your memory.', 'tags': ['R', 'Reflectivity']},
        {'text': 'Break it down into logical blocks (like birthdays) to remember it.', 'tags': ['Structured', 'Reflectivity']},
      ]
    },
    {
      'theme': 'Theme 2: Problem Solving & Execution',
      'question': '6. You have to assemble a new piece of IKEA furniture. What is your strategy?',
      'options': [
        {'text': 'Lay out all the parts and follow the instruction manual step-by-step.', 'tags': ['R', 'Structured', 'Reflectivity']},
        {'text': 'Look at the picture of the final product and figure out how it connects.', 'tags': ['V', 'Exploratory']},
        {'text': 'Assemble it with a friend so you can talk through the process together.', 'tags': ['A', 'Extrovert']},
        {'text': 'Start screwing things together immediately and fix mistakes later.', 'tags': ['K', 'Impulsivity', 'Exploratory']},
      ]
    },
    {
      'theme': 'Theme 2: Problem Solving & Execution',
      'question': '7. The teacher gives you an "open-ended" project with no strict rules. What is your reaction?',
      'options': [
        {'text': 'Great! I love the freedom to experiment and do whatever I want.', 'tags': ['K', 'Exploratory', 'Impulsivity']},
        {'text': 'I feel anxious. I prefer having a clear grading rubric to follow.', 'tags': ['R', 'Structured', 'Reflectivity']},
        {'text': "I'll form a group immediately so we can brainstorm ideas together.", 'tags': ['A', 'Extrovert']},
        {'text': 'I will search online for visual examples of what past students did.', 'tags': ['V', 'Reflectivity']},
      ]
    },
    {
      'theme': 'Theme 2: Problem Solving & Execution',
      'question': '8. Your laptop suddenly freezes while you are doing homework. What do you do?',
      'options': [
        {'text': 'Get frustrated and randomly click the mouse or mash the keyboard.', 'tags': ['K', 'Impulsivity']},
        {'text': 'Look up the error code and read tech support forums.', 'tags': ['R', 'Structured', 'Introvert']},
        {'text': 'Call a tech-savvy friend and ask them what to do.', 'tags': ['A', 'Extrovert']},
        {'text': 'Calmly retrace your last few steps to see what caused the crash.', 'tags': ['V', 'Reflectivity']},
      ]
    },
    {
      'theme': 'Theme 2: Problem Solving & Execution',
      'question': '9. You are trying to solve a very difficult logic puzzle. What is your approach?',
      'options': [
        {'text': 'Immediately guess an answer just to see what happens.', 'tags': ['Impulsivity', 'Exploratory']},
        {'text': 'Draw a diagram or a chart to map out the clues.', 'tags': ['V', 'Reflectivity']},
        {'text': 'Carefully read the text multiple times and underline key words.', 'tags': ['R', 'Structured']},
        {'text': 'Read the puzzle aloud or talk it through with someone.', 'tags': ['A', 'Extrovert']},
      ]
    },
    {
      'theme': 'Theme 2: Problem Solving & Execution',
      'question': '10. You want to cook a dish you have never made before. How do you do it?',
      'options': [
        {'text': 'Find a recipe blog, read the ingredients, and measure everything exactly.', 'tags': ['R', 'Structured', 'Reflectivity']},
        {'text': 'Watch a TikTok or YouTube cooking video to see what the dish should look like.', 'tags': ['V', 'Exploratory']},
        {'text': 'Call your mom or a friend to guide you through the steps.', 'tags': ['A', 'Extrovert']},
        {'text': 'Just throw ingredients into the pan based on what smells and tastes right.', 'tags': ['K', 'Impulsivity', 'Exploratory']},
      ]
    },
    {
      'theme': 'Theme 3: Teamwork & Communication',
      'question': '11. What is your ideal role in a group project?',
      'options': [
        {'text': 'The "Planner": Writing the outline and assigning tasks.', 'tags': ['R', 'Structured']},
        {'text': 'The "Designer": Creating the slides and formatting the graphics.', 'tags': ['V', 'Introvert']},
        {'text': 'The "Communicator": Leading discussions and presenting to the class.', 'tags': ['A', 'Extrovert']},
        {'text': 'The "Doer": Building the physical model or running the experiment.', 'tags': ['K', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 3: Teamwork & Communication',
      'question': '12. When presenting your project to the class, which format do you prefer?',
      'options': [
        {'text': 'Reading from a well-structured, written script.', 'tags': ['R', 'Structured', 'Introvert']},
        {'text': 'Pointing to charts, graphs, and animations on the screen.', 'tags': ['V', 'Structured']},
        {'text': 'Speaking naturally like a talk show host and taking questions from the crowd.', 'tags': ['A', 'Extrovert', 'Exploratory']},
        {'text': 'Doing a live demonstration or interactive game with the audience.', 'tags': ['K', 'Extrovert']},
      ]
    },
    {
      'theme': 'Theme 3: Teamwork & Communication',
      'question': '13. How do you usually express yourself when you are upset with a friend?',
      'options': [
        {'text': 'Write them a long text message explaining exactly why I am upset.', 'tags': ['R', 'Introvert', 'Reflectivity']},
        {'text': 'Call them or meet face-to-face to talk (or argue) it out immediately.', 'tags': ['A', 'Extrovert', 'Impulsivity']},
        {'text': 'Give them the "silent treatment" and show my anger through facial expressions.', 'tags': ['V', 'Introvert']},
        {'text': 'Stomp around, slam doors, or go for a run to burn off the anger.', 'tags': ['K', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 3: Teamwork & Communication',
      'question': '14. If you have to choose a study buddy, who would you pick?',
      'options': [
        {'text': 'Someone who sits quietly with me in the library while we read our own books.', 'tags': ['R', 'Introvert']},
        {'text': 'Someone who quizzes me verbally and discusses topics with me.', 'tags': ['A', 'Extrovert']},
        {'text': 'Someone who color-codes mind maps with me.', 'tags': ['V', 'Structured']},
        {'text': "Someone who keeps me on a strict timer so I don't get distracted.", 'tags': ['Structured', 'Reflectivity']},
      ]
    },
    {
      'theme': 'Theme 3: Teamwork & Communication',
      'question': '15. In a group discussion, what frustrates you the most?',
      'options': [
        {'text': 'When people go off-topic and ignore the main agenda.', 'tags': ['Structured', 'Reflectivity']},
        {'text': 'When someone stays silent and refuses to share their opinions.', 'tags': ['Extrovert', 'A']},
        {'text': "When it's all talk but nobody actually starts doing the work.", 'tags': ['K', 'Impulsivity']},
        {'text': 'When ideas are messy and not written down on a whiteboard.', 'tags': ['V', 'R']},
      ]
    },
    {
      'theme': 'Theme 4: Environment & Cognitive Pacing',
      'question': '16. The teacher suddenly announces a "Pop Quiz". What is your immediate reaction?',
      'options': [
        {'text': 'I scan the whole paper quickly and immediately start answering the easy ones.', 'tags': ['Impulsivity', 'Exploratory']},
        {'text': 'I take a deep breath, read the instructions carefully, and plan my time.', 'tags': ['Reflectivity', 'Structured']},
        {'text': 'I panic a little and look around to see how my classmates are reacting.', 'tags': ['Extrovert', 'V']},
        {'text': 'I tap my pen nervously and just want to get it over with.', 'tags': ['K', 'Impulsivity']},
      ]
    },
    {
      'theme': 'Theme 4: Environment & Cognitive Pacing',
      'question': '17. What is your perfect learning environment?',
      'options': [
        {'text': 'A completely silent room with blank walls and no distractions.', 'tags': ['Introvert', 'V']},
        {'text': 'A cafe or a room where I can play background music.', 'tags': ['A', 'Exploratory']},
        {'text': 'A dynamic space where I can walk around or stand while working.', 'tags': ['K', 'Exploratory']},
        {'text': 'A highly organized desk with a clear schedule and a ticking clock.', 'tags': ['Structured', 'Reflectivity']},
      ]
    },
    {
      'theme': 'Theme 4: Environment & Cognitive Pacing',
      'question': '18. When answering a multiple-choice question that you are unsure about, you usually:',
      'options': [
        {'text': 'Go with your first gut feeling and move on quickly.', 'tags': ['Impulsivity', 'Exploratory']},
        {'text': 'Eliminate the wrong answers one by one until you are completely sure.', 'tags': ['Reflectivity', 'Structured']},
        {'text': 'Read the options aloud softly to see which one "sounds" right.', 'tags': ['A', 'Extrovert']},
        {'text': 'Try to visualize the page in the textbook where the answer was written.', 'tags': ['V', 'Introvert']},
      ]
    },
    {
      'theme': 'Theme 4: Environment & Cognitive Pacing',
      'question': '19. How do you prefer to spend a free weekend?',
      'options': [
        {'text': 'Staying home alone to read a book or write in my journal.', 'tags': ['R', 'Introvert']},
        {'text': 'Going out with a big group of friends to chat and hang out.', 'tags': ['A', 'Extrovert']},
        {'text': 'Watching movies, playing video games, or visiting an art gallery.', 'tags': ['V', 'Introvert']},
        {'text': 'Trying a new physical activity, like rock climbing or a dance class.', 'tags': ['K', 'Exploratory']},
      ]
    },
    {
      'theme': 'Theme 4: Environment & Cognitive Pacing',
      'question': '20. Be honest: How did you answer these 20 questions?',
      'options': [
        {'text': 'I clicked through them as fast as possible without thinking too much.', 'tags': ['Impulsivity', 'K']},
        {'text': 'I thought carefully about every single scenario before choosing.', 'tags': ['Reflectivity', 'Structured']},
        {'text': 'I imagined the scenes in my head like a movie while answering.', 'tags': ['V', 'Exploratory']},
        {'text': 'I imagined someone asking me these questions in an interview.', 'tags': ['A', 'Extrovert']},
      ]
    },
  ];

  void _answerQuestion(List<String> tags) {
    setState(() {
      for (var tag in tags) {
        if (_varkScores.containsKey(tag)) {
          _varkScores[tag] = _varkScores[tag]! + 1;
        }
        if (tag == 'Structured') _structuredScore++;
        if (tag == 'Exploratory') _exploratoryScore++;
        if (tag == 'Introvert') _introvertScore++;
        if (tag == 'Extrovert') _extrovertScore++;
        if (tag == 'Impulsivity') _impulsivityScore++;
        if (tag == 'Reflectivity') _reflectivityScore++;
      }

      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else {
        _submitTest();
      }
    });
  }

  // ASYNC FUNCTION: Save data to Firebase when the test is completed
  void _submitTest() async {
    try {
      // 1. Create a 'students' collection in Firestore and add this user's data
      await FirebaseFirestore.instance.collection('students').add({
        'name': _studentName,
        'emergencyContact': _emergencyContact,
        'varkScores': _varkScores,
        'personalityScores': {
          'Structured': _structuredScore,
          'Exploratory': _exploratoryScore,
          'Introvert': _introvertScore,
          'Extrovert': _extrovertScore,
          'Impulsivity': _impulsivityScore,
          'Reflectivity': _reflectivityScore,
        },
        'testCompletedAt': FieldValue.serverTimestamp(), // Automatically record submission time
      });

      // 2. Navigate to the report page ONLY after successful save
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReportPage(
              studentName: _studentName,
              varkScores: _varkScores,
              pScores: {
                'S': _structuredScore,
                'E': _exploratoryScore,
                'I': _introvertScore,
                'X': _extrovertScore,
                'P': _impulsivityScore,
                'R': _reflectivityScore,
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Show an error popup if saving to Firebase fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save results: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        _questions.isEmpty ? 0 : (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FBFA),
      appBar: AppBar(
        title: const Text(
          "Pre-Admission Test",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF0F9D58),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _started ? _buildQuestionUI(progress) : _buildStartUI(),
        ),
      ),
    );
  }

  // START SCREEN UI
  Widget _buildStartUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Before you start",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        TextField(
          decoration: const InputDecoration(labelText: "Student Name"),
          onChanged: (v) => _studentName = v,
        ),

        const SizedBox(height: 20),

        TextField(
          decoration: const InputDecoration(labelText: "Emergency Contact"),
          onChanged: (v) => _emergencyContact = v,
        ),

        const SizedBox(height: 30),

        ElevatedButton(
          onPressed: () {
            if (_studentName.isEmpty || _emergencyContact.isEmpty) return;

            setState(() {
              _started = true;
            });
          },
          style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFF0F9D58),
             foregroundColor: Colors.white,
          ),
          child: const Text("Start Test"),
        ),
      ],
    );
  }

  // QUESTION SCREEN UI
  Widget _buildQuestionUI(double progress) {
    final currentQ = _questions[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: const Color(0xFF0F9D58),
            minHeight: 12,
          ),
        ),
        const SizedBox(height: 24),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                currentQ['theme'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                currentQ['question'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              ...((currentQ['options'] as List).map((opt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () => _answerQuestion(opt['tags']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(opt['text'],
                        style: const TextStyle(fontSize: 16)),
                  ),
                );
              })),
            ],
          ),
        ),
      ],
    );
  }
}