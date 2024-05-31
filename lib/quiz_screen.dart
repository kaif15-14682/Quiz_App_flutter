import 'dart:math';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key, this.mode = "default"})
      : super(key: key); // Default value provided for mode
  final String? mode;

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  SharedPreferences? sharedPreferences;
  int highestScore = 0;
  int quizNumber = 1;
  int questionIndex = 0;
  int score = 0;
  bool isAnswered = false;

  String selectedCategory = "General Knowledge"; // Default category

  int quizTimeInSeconds = 15 * 60; // 15 minutes in seconds
  int timeRemaining = 15 * 60; // Initially set to quiz time

  List<String> categories = ["General Knowledge", "Science", "History"];
  Map<String, List<String>> categoryQuestions = {
    "General Knowledge": [
      'What is the capital of France?',
      'Who painted the Mona Lisa?',
      'What is the largest planet in our solar system?',
      'How many continents are there in the world?',
      'What is the largest mammal?',
    ],
    "Science": [
      'What is the largest planet in our solar system?',
      'Which gas do plants absorb from the atmosphere?',
      'What is the powerhouse of the cell?',
      'Who developed the theory of relativity?',
      'What is the chemical symbol for water?',
    ],
    "History": [
      'In which year did Christopher Columbus discover America?',
      'Who is known as the "Father of Modern Physics"?',
      'Who was the first President of the United States?',
      'When did World War II end?',
      'Who wrote "Romeo and Juliet"?',
    ],
  };

  Map<String, List<List<String>>> categoryOptions = {
    "General Knowledge": [
      ['Paris', 'London', 'Madrid', 'Rome'],
      [
        'Leonardo da Vinci',
        'Pablo Picasso',
        'Vincent van Gogh',
        'Claude Monet'
      ],
      ['Saturn', 'Mars', 'Earth', 'Jupiter'],
      ['5', '6', '7', '8'],
      ['Elephant', 'Giraffe', 'Blue Whale', 'Hippopotamus'],
    ],
    "Science": [
      ['Jupiter', 'Mars', 'Earth', 'Saturn'],
      ['Oxygen', 'Carbon Dioxide', 'Nitrogen', 'Hydrogen'],
      ['Mitochondria', 'Nucleus', 'Ribosome', 'Endoplasmic Reticulum'],
      ['Albert Einstein', 'Isaac Newton', 'Galileo Galilei', 'Niels Bohr'],
      ['H2O', 'CO2', 'O2', 'N2'],
    ],
    "History": [
      ['1492', '1607', '1776', '1789'],
      ['Albert Einstein', 'Isaac Newton', 'Galileo Galilei', 'Niels Bohr'],
      ['George Washington', 'John Adams', 'Thomas Jefferson', 'James Madison'],
      ['1945', '1940', '1949', '1939'],
      ['William Shakespeare', 'Jane Austen', 'Charles Dickens', 'Mark Twain'],
    ],
  };

  Map<String, List<String>> categoryCorrectAnswers = {
    "General Knowledge": [
      'Paris',
      'Leonardo da Vinci',
      'Jupiter',
      '7',
      'Blue Whale',
    ],
    "Science": [
      'Jupiter',
      'Carbon Dioxide',
      'Mitochondria',
      'Albert Einstein',
      'H2O',
    ],
    "History": [
      '1492',
      'Albert Einstein',
      'George Washington',
      '1945',
      'William Shakespeare',
    ],
  };

  List<String> questions = [];
  List<List<String>> options = [];
  List<String> correctAnswers = [];
  List<String> selectedAnswers = [];

  void shuffleQuestionsAndOptions() {
    final random = Random();
    for (var i = questions.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);

      // Swap questions
      final tempQuestion = questions[i];
      questions[i] = questions[j];
      questions[j] = tempQuestion;

      // Swap options
      final tempOptions = options[i];
      options[i] = options[j];
      options[j] = tempOptions;

      // Swap correct answers
      final tempAnswer = correctAnswers[i];
      correctAnswers[i] = correctAnswers[j];
      correctAnswers[j] = tempAnswer;
    }
  }

  void initializeQuestions() {
    questions = categoryQuestions[selectedCategory]!;
    options = categoryOptions[selectedCategory]!;
    correctAnswers = categoryCorrectAnswers[selectedCategory]!;
  }

  Future<void> getHighestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      highestScore = prefs.getInt('highestScore') ?? 0;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeSharedPreferences();
    initializeQuestions();
    shuffleQuestionsAndOptions();
    startQuizTimer();
    loadHighestScore();
    getHighestScore();
  }

  Future<void> loadHighestScore() async {
    sharedPreferences = await SharedPreferences.getInstance();
    highestScore = sharedPreferences!.getInt('highestScore') ?? 0;
  }

  Future<void> _saveHighestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highestScore', highestScore);
  }

  void handleAnswer(bool isCorrect) {
    if (isCorrect) {
      setState(() {
        score++;
      });
    }
    setState(() {
      isAnswered = true;
    });
  }

  void handleNextQuestion() {
    if (questionIndex < categoryQuestions[selectedCategory]!.length - 1) {
      setState(() {
        questionIndex++;
        isAnswered = false;
      });
    } else {
      showResults();
    }
  }

  void showResults() {
    updateHighScore(); // Update the highest score if necessary

    int timeUsed = quizTimeInSeconds - timeRemaining;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Quiz Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Score: $score/${categoryQuestions[selectedCategory]!.length}'),
              Text('Highest Score: $highestScore'),
              Text(
                  'Time Used: ${timeUsed ~/ 60}:${(timeUsed % 60).toString().padLeft(2, '0')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                resetQuiz();
                Navigator.pop(context);
              },
              child: Text('Next Quiz'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Go Back'),
            ),
          ],
        );
      },
    );
  }

  void handleQuizTime(int seconds) {
    if (seconds == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Time\'s Up!'),
            content: Text('You ran out of time.'),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    timeRemaining = quizTimeInSeconds;
                  });
                  Navigator.pop(context);
                },
                child: Text('Restart Quiz'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Go Back'),
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        timeRemaining = seconds;
      });
    }
  }

  void initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      highestScore = sharedPreferences?.getInt('highestScore') ?? 0;
    });
  }

  void updateHighestScore() async {
    final currentScore = sharedPreferences?.getInt('highestScore');
    if (currentScore != null) {
      if (score > currentScore) {
        await sharedPreferences?.setInt('highestScore', score);
        await _saveHighestScore();
        setState(() {
          highestScore = score;
        });
      }
    } else {
      await sharedPreferences?.setInt('highestScore', score);
      setState(() {
        highestScore = score;
      });
    }
  }

  void checkAnswer(String selectedOption) {
    if (isAnswered) {
      return; // Prevent multiple answer selections
    }

    String correctAnswer = correctAnswers[questionIndex];
    bool isCorrect = selectedOption == correctAnswer;

    setState(() {
      selectedAnswers.add(selectedOption);
    });

    handleAnswer(isCorrect);

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        if (questionIndex < questions.length - 1) {
          questionIndex++;
          isAnswered = false;
        } else {
          // Quiz completed, perform any desired actions
          showResults(); // Show quiz results
        }
      });
    });
  }

  void resetQuiz() {
    setState(() {
      questionIndex = 0;
      score = 0;
      isAnswered = false;
      timeRemaining = quizTimeInSeconds; // Reset timer
      shuffleQuestionsAndOptions(); // Shuffle questions and options
    });
  }

  void saveHighestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highestScore', highestScore);
  }

  void updateHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    int storedHighScore = prefs.getInt('highestScore') ?? 0;
    if (score > storedHighScore) {
      await prefs.setInt('highestScore', score);
      setState(() {
        highestScore = score;
      });
    }
  }

  void startQuizTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (timeRemaining > 0) {
        setState(() {
          timeRemaining--;
        });
        startQuizTimer();
      } else {
        handleQuizTime(0); // Time's up, handle it
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              Share.share('Check out this amazing quiz app!');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Category: $selectedCategory',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Time Remaining: ${timeRemaining ~/ 60}:${(timeRemaining % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 20),
              Text(
                questions[questionIndex],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Column(
                children: List.generate(options[questionIndex].length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: isAnswered
                          ? null
                          : () => checkAnswer(options[questionIndex][index]),
                      child: Text(
                        options[questionIndex][index],
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Text(
                'Question ${questionIndex + 1} of ${questions.length}',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Score: $score',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Highest Score: $highestScore',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (isAnswered)
                ElevatedButton(
                  onPressed: handleNextQuestion,
                  child: Text('Next Question'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
