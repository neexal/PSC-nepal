import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'results_screen.dart';

class ModernQuizScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;
  final int duration;

  const ModernQuizScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.duration,
  });

  @override
  State<ModernQuizScreen> createState() => _ModernQuizScreenState();
}

class _ModernQuizScreenState extends State<ModernQuizScreen> with TickerProviderStateMixin {
  List<dynamic> questions = [];
  Map<String, int> answers = {};
  int currentQuestion = 0;
  bool isLoading = true;
  bool isSubmitting = false;
  Timer? _timer;
  int remainingSeconds = 0;
  
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  Set<int> bookmarkedQuestions = {};

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.duration * 60;
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    
    fetchQuestions();
    fetchBookmarks();
    startTimer();
    _slideController.forward();
    _scaleController.forward();
  }

  Future<void> fetchBookmarks() async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        final bookmarks = await ApiService.getBookmarks(token);
        setState(() {
          bookmarkedQuestions = bookmarks
              .map((b) => b['question'] is int ? b['question'] as int : (b['question']['id'] as int))
              .toSet();
        });
      }
    } catch (e) {
      print('Error fetching bookmarks: $e');
    }
  }

  Future<void> toggleBookmark(int questionId) async {
    try {
      final token = await ApiService.getToken();
      if (token != null) {
        // Optimistic update
        setState(() {
          if (bookmarkedQuestions.contains(questionId)) {
            bookmarkedQuestions.remove(questionId);
          } else {
            bookmarkedQuestions.add(questionId);
          }
        });
        
        await ApiService.toggleBookmark(token, questionId);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (bookmarkedQuestions.contains(questionId)) {
          bookmarkedQuestions.remove(questionId);
        } else {
          bookmarkedQuestions.add(questionId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update bookmark')),
        );
      }
    }
  }

  Future<void> fetchQuestions() async {
    try {
      final data = await ApiService.getQuizQuestions(widget.quizId);
      setState(() {
        questions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void selectAnswer(int optionIndex) async {
    setState(() {
      answers[questions[currentQuestion]['id'].toString()] = optionIndex;
    });
    
    // Animate selection
    await _scaleController.reverse();
    await _scaleController.forward();
    
    // Auto-advance after short delay
    await Future.delayed(Duration(milliseconds: 600));
    if (currentQuestion < questions.length - 1) {
      nextQuestion();
    }
  }

  void nextQuestion() async {
    if (currentQuestion < questions.length - 1) {
      await _slideController.reverse();
      setState(() => currentQuestion++);
      await _slideController.forward();
    }
  }

  void previousQuestion() async {
    if (currentQuestion > 0) {
      await _slideController.reverse();
      setState(() => currentQuestion--);
      await _slideController.forward();
    }
  }

  Future<void> submitQuiz() async {
    if (isSubmitting) return;

    setState(() => isSubmitting = true);
    _timer?.cancel();

    try {
      final result = await ApiService.submitQuiz(widget.quizId, answers);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(showResult: result),
          ),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting quiz: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'Loading questions...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('No Questions')),
        body: Center(child: Text('No questions available')),
      );
    }

    final question = questions[currentQuestion];
    final progress = (currentQuestion + 1) / questions.length;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(progress),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildQuestionCard(question),
                  ),
                ),
              ),
              _buildNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final timeColor = remainingSeconds < 60 ? Colors.red : Colors.white;

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: timeColor, size: 18),
                    SizedBox(width: 6),
                    Text(
                      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: timeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestion + 1}/${questions.length}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question) {
    final options = List<String>.from(question['options'] ?? []);
    final selectedAnswer = answers[question['id'].toString()];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    question['difficulty']?.toString().toUpperCase() ?? 'MEDIUM',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    bookmarkedQuestions.contains(question['id']) 
                        ? Icons.bookmark_rounded 
                        : Icons.bookmark_border_rounded,
                    color: bookmarkedQuestions.contains(question['id']) 
                        ? Color(0xFF667eea) 
                        : Color(0xFFCBD5E0),
                  ),
                  onPressed: () => toggleBookmark(question['id']),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            question['question_text'] ?? '',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
              height: 1.4,
            ),
          ),
          SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (context, index) {
                final isSelected = selectedAnswer == index;
                return _buildOptionCard(options[index], index, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String option, int index, bool isSelected) {
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    
    return GestureDetector(
      onTap: () => selectAnswer(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isSelected ? null : Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Color(0xFF4A5568),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.white : Color(0xFF2D3748),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigation() {
    final canGoBack = currentQuestion > 0;
    final canGoNext = currentQuestion < questions.length - 1;
    final isLastQuestion = currentQuestion == questions.length - 1;
    final hasAnsweredCurrent = answers.containsKey(questions[currentQuestion]['id'].toString());

    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          if (canGoBack)
            Expanded(
              child: ElevatedButton(
                onPressed: previousQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Previous'),
              ),
            ),
          if (canGoBack) SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : (isLastQuestion ? submitQuiz : (hasAnsweredCurrent ? nextQuestion : null)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF667eea),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
              ),
              child: isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isLastQuestion ? 'Submit Quiz' : 'Next',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
