import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ResultDetailScreen extends StatefulWidget {
  final int resultId;
  final String quizTitle;

  const ResultDetailScreen({
    super.key,
    required this.resultId,
    required this.quizTitle,
  });

  @override
  State<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends State<ResultDetailScreen> {
  Map<String, dynamic>? resultData;
  bool isLoading = true;
  Set<int> bookmarkedQuestions = {};

  @override
  void initState() {
    super.initState();
    fetchResultDetails();
  }

  Future<void> fetchResultDetails() async {
    try {
      final data = await ApiService.getResultDetails(widget.resultId);
      setState(() {
        resultData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Color getScoreColor(double score) {
    if (score >= 80) return AppTheme.successGreen;
    if (score >= 60) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  Future<void> toggleBookmark(int questionId) async {
    try {
      final result = await ApiService.toggleBookmark(questionId);
      setState(() {
        if (result['bookmarked'] == true) {
          bookmarkedQuestions.add(questionId);
        } else {
          bookmarkedQuestions.remove(questionId);
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.successGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to bookmark'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void showReportDialog(int questionId, String questionText) {
    String? issueType = 'wrong_answer';
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Report Question'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report an issue with this question:',
                  style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: issueType,
                  decoration: InputDecoration(
                    labelText: 'Issue Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(value: 'wrong_answer', child: Text('Wrong Correct Answer')),
                    DropdownMenuItem(value: 'typo', child: Text('Typo/Grammar Error')),
                    DropdownMenuItem(value: 'unclear', child: Text('Unclear Question')),
                    DropdownMenuItem(value: 'wrong_options', child: Text('Wrong Options')),
                    DropdownMenuItem(value: 'other', child: Text('Other Issue')),
                  ],
                  onChanged: (val) => setState(() => issueType = val),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Explain the issue in detail...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descriptionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please provide a description'),
                      backgroundColor: AppTheme.warningOrange,
                    ),
                  );
                  return;
                }
                
                try {
                  await ApiService.reportQuestion(
                    questionId: questionId,
                    issueType: issueType!,
                    description: descriptionController.text.trim(),
                  );
                  
                  Navigator.pop(context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you! Report submitted successfully.'),
                        backgroundColor: AppTheme.successGreen,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit report'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
              child: Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Review Answers',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : resultData == null
              ? Center(child: Text('Failed to load result details'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Score Summary Card
                      Container(
                        margin: EdgeInsets.all(16),
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.quizTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildScoreStat(
                                  'Score',
                                  '${resultData!['score'].toStringAsFixed(1)}%',
                                  getScoreColor(resultData!['score']),
                                  Icons.score_rounded,
                                ),
                                _buildScoreStat(
                                  'Correct',
                                  '${resultData!['correct_count']}',
                                  AppTheme.successGreen,
                                  Icons.check_circle_rounded,
                                ),
                                _buildScoreStat(
                                  'Wrong',
                                  '${resultData!['wrong_count']}',
                                  AppTheme.errorRed,
                                  Icons.cancel_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Questions List
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question Review',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 12),
                            ...List.generate(
                              resultData!['questions'].length,
                              (index) => _buildQuestionCard(
                                index,
                                resultData!['questions'][index],
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Map<String, dynamic> question) {
    bool isCorrect = question['is_correct'];
    int? userAnswer = question['user_answer'];
    int correctAnswer = question['correct_option'];
    List<dynamic> options = question['options'];
    String? explanation = question['explanation'];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect 
              ? AppTheme.successGreen.withOpacity(0.3) 
              : AppTheme.errorRed.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect 
                      ? AppTheme.successGreen.withOpacity(0.1)
                      : AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                    SizedBox(width: 4),
                    Text(
                      isCorrect ? 'Correct' : 'Wrong',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          // Action Buttons
          Row(
            children: [
              // Bookmark Button
              TextButton.icon(
                onPressed: () => toggleBookmark(question['id']),
                icon: Icon(
                  bookmarkedQuestions.contains(question['id'])
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  size: 18,
                  color: bookmarkedQuestions.contains(question['id'])
                      ? Colors.orange
                      : AppTheme.textSecondary,
                ),
                label: Text(
                  'Bookmark',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              SizedBox(width: 8),
              // Report Button
              TextButton.icon(
                onPressed: () => showReportDialog(
                  question['id'],
                  question['question_text'],
                ),
                icon: Icon(
                  Icons.flag_outlined,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                label: Text(
                  'Report',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Question Text
          Text(
            question['question_text'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 16),

          // Options
          ...List.generate(options.length, (optionIndex) {
            bool isUserAnswer = userAnswer == optionIndex;
            bool isCorrectAnswer = correctAnswer == optionIndex;
            
            Color backgroundColor;
            Color borderColor;
            Color textColor;
            IconData? icon;

            if (isCorrectAnswer) {
              backgroundColor = AppTheme.successGreen.withOpacity(0.1);
              borderColor = AppTheme.successGreen;
              textColor = AppTheme.successGreen;
              icon = Icons.check_circle;
            } else if (isUserAnswer && !isCorrect) {
              backgroundColor = AppTheme.errorRed.withOpacity(0.1);
              borderColor = AppTheme.errorRed;
              textColor = AppTheme.errorRed;
              icon = Icons.cancel;
            } else {
              backgroundColor = AppTheme.backgroundLight;
              borderColor = Colors.grey.shade300;
              textColor = AppTheme.textSecondary;
              icon = null;
            }

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      options[optionIndex],
                      style: TextStyle(
                        fontSize: 14,
                        color: icon != null ? textColor : AppTheme.textPrimary,
                        fontWeight: icon != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    SizedBox(width: 8),
                    Icon(icon, size: 20, color: textColor),
                  ],
                ],
              ),
            );
          }),

          // Explanation
          if (explanation != null && explanation.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explanation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          explanation,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
