import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'modern_quiz_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<dynamic> quizzes = [];
  List<dynamic> filteredQuizzes = [];
  List<dynamic> userResults = [];
  Map<int, Map<String, dynamic>> completionStatus = {}; // quizId -> {score, attempts}
  bool isLoading = true;
  String? selectedCategory;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'GK',
    'Nepali',
    'English',
    'IT',
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await Future.wait([
      fetchQuizzes(),
      fetchUserResults(),
    ]);
  }

  Future<void> fetchUserResults() async {
    try {
      final results = await ApiService.getResults();
      if (!mounted) return;
      setState(() {
        userResults = results;
        _calculateCompletionStatus();
      });
    } catch (e) {
      // User might not be logged in or no results yet
      print('Error fetching results: $e');
    }
  }

  void _calculateCompletionStatus() {
    completionStatus.clear();
    for (var result in userResults) {
      final quizId = result['quiz'];
      final score = (result['score'] ?? 0.0).toDouble();
      
      if (!completionStatus.containsKey(quizId) || 
          completionStatus[quizId]!['bestScore'] < score) {
        completionStatus[quizId] = {
          'bestScore': score,
          'attempts': completionStatus.containsKey(quizId) 
              ? completionStatus[quizId]!['attempts'] + 1 
              : 1,
        };
      } else {
        completionStatus[quizId]!['attempts']++;
      }
    }
  }

  void _filterQuizzes() {
    setState(() {
      filteredQuizzes = quizzes.where((quiz) {
        final matchesSearch = searchQuery.isEmpty ||
            quiz['title'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
            (quiz['topic'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
        
        final matchesCategory = selectedCategory == null ||
            quiz['category'] == selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> fetchQuizzes({String? category}) async {
    if (mounted) {
      setState(() {
        isLoading = true;
        selectedCategory = category == 'All' ? null : category;
      });
    }

    try {
      final data = await ApiService.getQuizzes(category: selectedCategory);
      if (!mounted) return;
      setState(() {
        quizzes = data;
        filteredQuizzes = data;
        isLoading = false;
      });
      _filterQuizzes();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Color getCategoryColor(String category) {
    final colors = {
      'GK': AppTheme.primaryBlue,
      'Nepali': AppTheme.errorRed,
      'English': AppTheme.successGreen,
      'IT': AppTheme.accentTeal,
    };
    return colors[category] ?? AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quizzes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => fetchQuizzes(category: selectedCategory ?? 'All'),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quizzes...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                          _filterQuizzes();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                _filterQuizzes();
              },
            ),
          ),
          // Category Filter
          Container(
            height: 60,
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category ||
                    (selectedCategory == null && category == 'All');

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => fetchQuizzes(category: category),
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          // Quizzes List
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading quizzes...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : quizzes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.quiz_rounded,
                              size: 80,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No quizzes available',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            fetchQuizzes(category: selectedCategory ?? 'All'),
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: filteredQuizzes.length,
                          itemBuilder: (context, index) {
                            final quiz = filteredQuizzes[index];
                            final quizId = quiz['id'];
                            final isCompleted = completionStatus.containsKey(quizId);
                            final bestScore = isCompleted ? completionStatus[quizId]!['bestScore'] : 0.0;
                            
                            return AnimatedCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ModernQuizScreen(
                                      quizId: quiz['id'],
                                      quizTitle: quiz['title'],
                                      duration: quiz['duration'],
                                    ),
                                  ),
                                ).then((_) => fetchData()); // Refresh after quiz
                              },
                              padding: EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              getCategoryColor(quiz['category'])
                                                  .withOpacity(0.2),
                                              getCategoryColor(quiz['category'])
                                                  .withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isCompleted ? Icons.check_circle_rounded : Icons.quiz_rounded,
                                          color: isCompleted 
                                              ? AppTheme.successGreen 
                                              : getCategoryColor(quiz['category']),
                                          size: 32,
                                        ),
                                      ),
                                      if (isCompleted)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successGreen,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 2),
                                            ),
                                            child: Icon(
                                              Icons.done,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                quiz['title'],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (isCompleted)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: bestScore >= 80
                                                      ? AppTheme.successGreen.withOpacity(0.1)
                                                      : bestScore >= 60
                                                          ? AppTheme.warningOrange.withOpacity(0.1)
                                                          : AppTheme.errorRed.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: bestScore >= 80
                                                        ? AppTheme.successGreen
                                                        : bestScore >= 60
                                                            ? AppTheme.warningOrange
                                                            : AppTheme.errorRed,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.star_rounded,
                                                      size: 14,
                                                      color: bestScore >= 80
                                                          ? AppTheme.successGreen
                                                          : bestScore >= 60
                                                              ? AppTheme.warningOrange
                                                              : AppTheme.errorRed,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '${bestScore.toInt()}%',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: bestScore >= 80
                                                            ? AppTheme.successGreen
                                                            : bestScore >= 60
                                                                ? AppTheme.warningOrange
                                                                : AppTheme.errorRed,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (quiz['topic'] != null && quiz['topic'].toString().isNotEmpty) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            quiz['topic'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: getCategoryColor(
                                                        quiz['category'])
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                quiz['category'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: getCategoryColor(
                                                      quiz['category']),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.help_outline_rounded,
                                                  size: 14,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  '${quiz['total_questions']}Q',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.timer_rounded,
                                                  size: 14,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  '${quiz['duration']}m',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isCompleted)
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.replay_rounded,
                                                      size: 11,
                                                      color: AppTheme.primaryBlue,
                                                    ),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'Retake',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: AppTheme.primaryBlue,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
