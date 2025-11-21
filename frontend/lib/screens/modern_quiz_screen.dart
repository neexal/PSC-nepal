import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
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
  bool feedbackSubmitting = false;
  Set<int> feedbackSubmittedQuestions = {};

  void _openFeedbackSheet(int questionId) {
    if (feedbackSubmittedQuestions.contains(questionId)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback already submitted for this question')));
      return;
    }
    final difficultyController = ValueNotifier<int>(3);
    final helpfulController = ValueNotifier<bool>(true);
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Question Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Difficulty (1-5)'),
                    Slider(
                      value: difficultyController.value.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: difficultyController.value.toString(),
                      onChanged: (v) => setModalState(() => difficultyController.value = v.toInt()),
                    ),
                    Row(
                      children: [
                        const Text('Helpful?'),
                        const SizedBox(width: 8),
                        Switch(
                          value: helpfulController.value,
                          onChanged: (val) => setModalState(() => helpfulController.value = val),
                        ),
                      ],
                    ),
                    TextField(
                      controller: commentController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Comment (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: feedbackSubmitting ? null : () async {
                          if (feedbackSubmitting) return;
                          setState(() { feedbackSubmitting = true; });
                          try {
                            await ApiService.giveQuestionFeedback(
                              questionId: questionId,
                              difficultyRating: difficultyController.value,
                              isHelpful: helpfulController.value,
                              comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted')));
                              setState(() { feedbackSubmittedQuestions.add(questionId); });
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
                            }
                          } finally {
                            if (mounted) setState(() { feedbackSubmitting = false; });
                          }
                        },
                        icon: const Icon(Icons.send_rounded),
                        label: Text(feedbackSubmitting ? 'Submitting...' : 'Submit Feedback'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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
        if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        questions = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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

    if (!mounted) return;
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

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds <= 0) {
        timer.cancel();
        if (!isSubmitting) {
          await submitQuiz();
        }
      } else {
        if (!mounted) return;
        setState(() {
          remainingSeconds -= 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
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
          Row(
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
              IconButton(
                tooltip: feedbackSubmittedQuestions.contains(question['id']) ? 'Feedback submitted' : 'Give feedback',
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: feedbackSubmittedQuestions.contains(question['id']) 
                        ? Colors.green.shade100 
                        : Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    feedbackSubmittedQuestions.contains(question['id']) 
                        ? Icons.check_circle_rounded 
                        : Icons.feedback_rounded,
                    color: feedbackSubmittedQuestions.contains(question['id']) 
                        ? Colors.green.shade700 
                        : Colors.purple.shade400,
                    size: 20,
                  ),
                ),
                onPressed: feedbackSubmittedQuestions.contains(question['id']) ? null : () => _openFeedbackSheet(question['id']),
              ),
            ],
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
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
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
                    color: Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                    spreadRadius: -2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
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
