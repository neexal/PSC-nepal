from django.db import models
from django.contrib.auth.models import User

class Subject(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name

class Quiz(models.Model):
    CATEGORY_CHOICES = [
        ('GK', 'General Knowledge'),
        ('Nepali', 'Nepali'),
        ('English', 'English'),
        ('IT', 'Information Technology'),
    ]
    title = models.CharField(max_length=200)
    topic = models.CharField(max_length=300, blank=True, help_text="Brief topic/description shown in the app")
    category = models.CharField(max_length=10, choices=CATEGORY_CHOICES)
    total_questions = models.IntegerField()
    duration = models.IntegerField(help_text="Duration in minutes")
    subject = models.ForeignKey('Subject', on_delete=models.SET_NULL, null=True, blank=True, related_name='quizzes')

    def __str__(self):
        return self.title

class Question(models.Model):
    DIFFICULTY_CHOICES = [
        ('easy', 'Easy'),
        ('medium', 'Medium'),
        ('hard', 'Hard'),
    ]
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='questions')
    question_text = models.TextField()
    options = models.JSONField()  # List of options
    correct_option = models.IntegerField()  # Index of correct option
    explanation = models.TextField(blank=True)
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='medium')
    subject = models.ForeignKey('Subject', on_delete=models.SET_NULL, null=True, blank=True, related_name='questions')

    def __str__(self):
        return self.question_text[:50]

class Result(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE)
    score = models.FloatField()
    correct_count = models.IntegerField()
    wrong_count = models.IntegerField()
    date_taken = models.DateTimeField(auto_now_add=True)
    answers = models.JSONField(default=dict, blank=True)  # Stores {question_id: user_answer}

    def __str__(self):
        return f"{self.user.username} - {self.quiz.title} - {self.score}"

class StudyMaterial(models.Model):
    CATEGORY_CHOICES = [
        ('GK', 'General Knowledge'),
        ('Nepali', 'Nepali'),
        ('English', 'English'),
        ('IT', 'Information Technology'),
        ('Math', 'Mathematics'),
        ('Science', 'Science'),
        ('History', 'History'),
        ('Geography', 'Geography'),
    ]
    
    TYPE_CHOICES = [
        ('PDF', 'PDF'),
        ('Link', 'Link'),
        ('Note', 'Note'),
    ]
    
    title = models.CharField(max_length=200)
    topic = models.CharField(max_length=200, blank=True)
    category = models.CharField(max_length=20, choices=CATEGORY_CHOICES)
    material_type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='PDF')
    file_url = models.URLField(blank=True, null=True, help_text="URL for PDF or file")
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    download_count = models.IntegerField(default=0)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title

class Notification(models.Model):
    TYPE_CHOICES = [
        ('reminder', 'Reminder'),
        ('news', 'News'),
        ('update', 'Update'),
        ('exam', 'Exam Alert'),
    ]
    
    title = models.CharField(max_length=200)
    message = models.TextField()
    notification_type = models.CharField(max_length=20, choices=TYPE_CHOICES, default='news')
    timestamp = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    target_users = models.ManyToManyField(User, blank=True, help_text="Leave empty for all users")
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return self.title

class UserProfile(models.Model):
    ROLE_CHOICES = [
        ('student', 'Student'),
        ('admin', 'Admin'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='student')
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    target_post = models.CharField(max_length=200, blank=True, help_text="Target PSC post")
    profile_picture = models.URLField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"

class Badge(models.Model):
    BADGE_TYPES = [
        ('score_90', 'Scored 90%+'),
        ('streak_7', '7-day Streak'),
        ('attempt_10', '10 Quizzes Attempted'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='badges')
    type = models.CharField(max_length=50, choices=BADGE_TYPES)
    date_awarded = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_awarded']

    def __str__(self):
        return f"{self.user.username} - {self.type}"

class Streak(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='streak')
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_active_date = models.DateField(null=True, blank=True)

    def __str__(self):
        return f"{self.user.username} - {self.current_streak}"

class Bookmark(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='bookmarks')
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='bookmarks')
    result = models.ForeignKey(Result, on_delete=models.CASCADE, null=True, blank=True, related_name='bookmarks')
    notes = models.TextField(blank=True, help_text="Personal notes for this question")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['user', 'question']
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} - {self.question.question_text[:30]}"

class QuestionReport(models.Model):
    ISSUE_TYPES = [
        ('wrong_answer', 'Wrong Correct Answer'),
        ('typo', 'Typo/Grammar Error'),
        ('unclear', 'Unclear Question'),
        ('wrong_options', 'Wrong Options'),
        ('other', 'Other Issue'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reports')
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='reports')
    issue_type = models.CharField(max_length=20, choices=ISSUE_TYPES)
    description = models.TextField(help_text="Detailed description of the issue")
    status = models.CharField(max_length=20, default='pending', choices=[
        ('pending', 'Pending'),
        ('reviewing', 'Under Review'),
        ('resolved', 'Resolved'),
        ('rejected', 'Rejected'),
    ])
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    admin_notes = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Report by {self.user.username} - {self.issue_type}"

class Achievement(models.Model):
    """Extended achievement system with milestones"""
    ACHIEVEMENT_TYPES = [
        ('first_quiz', 'First Quiz Completed'),
        ('perfect_score', '100% Score'),
        ('quiz_master', '50 Quizzes Completed'),
        ('category_expert', 'Category Expert (20+ in one category)'),
        ('streak_warrior', '30-day Streak'),
        ('fast_learner', 'Completed 10 quizzes in a week'),
        ('bookworm', '100 Questions Bookmarked'),
        ('helpful', '10 Questions Reported'),
        ('consistent', '100 Quizzes Completed'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='achievements')
    achievement_type = models.CharField(max_length=50, choices=ACHIEVEMENT_TYPES)
    category = models.CharField(max_length=20, blank=True, help_text="For category-specific achievements")
    title = models.CharField(max_length=200)
    description = models.TextField()
    icon = models.CharField(max_length=50, default='trophy')
    points = models.IntegerField(default=10, help_text="Points awarded")
    date_earned = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-date_earned']
        unique_together = ['user', 'achievement_type', 'category']
    
    def __str__(self):
        return f"{self.user.username} - {self.title}"

class UserAnalytics(models.Model):
    """Aggregated user performance analytics"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='analytics')
    total_quizzes = models.IntegerField(default=0)
    total_questions_answered = models.IntegerField(default=0)
    average_score = models.FloatField(default=0.0)
    best_category = models.CharField(max_length=20, blank=True)
    worst_category = models.CharField(max_length=20, blank=True)
    total_study_time = models.IntegerField(default=0, help_text="Total time in minutes")
    points = models.IntegerField(default=0, help_text="Gamification points")
    rank = models.IntegerField(null=True, blank=True, help_text="Global rank")
    last_updated = models.DateTimeField(auto_now=True)
    
    # Category-wise stats (stored as JSON for flexibility)
    category_stats = models.JSONField(default=dict, blank=True)
    # Format: {"GK": {"quizzes": 10, "avg_score": 85.5, "best_score": 95}, ...}
    
    def __str__(self):
        return f"{self.user.username} Analytics"

class QuestionFeedback(models.Model):
    """User feedback on questions for quality improvement"""
    DIFFICULTY_RATING = [
        (1, 'Very Easy'),
        (2, 'Easy'),
        (3, 'Medium'),
        (4, 'Hard'),
        (5, 'Very Hard'),
    ]
    
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='question_feedbacks')
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='feedbacks')
    difficulty_rating = models.IntegerField(choices=DIFFICULTY_RATING, null=True, blank=True)
    is_helpful = models.BooleanField(null=True, blank=True)
    comment = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ['user', 'question']
        ordering = ['-created_at']
    
    def __str__(self):
        return f"Feedback by {self.user.username} on Q-{self.question.id}"

class StudyGroup(models.Model):
    """Collaborative study groups"""
    name = models.CharField(max_length=200)
    description = models.TextField()
    category = models.CharField(max_length=20, blank=True, help_text="Focus category")
    creator = models.ForeignKey(User, on_delete=models.CASCADE, related_name='created_groups')
    members = models.ManyToManyField(User, related_name='study_groups', blank=True)
    is_private = models.BooleanField(default=False)
    invite_code = models.CharField(max_length=10, unique=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    member_limit = models.IntegerField(default=50)
    
    class Meta:
        ordering = ['-created_at']
    
    def __str__(self):
        return self.name

class ForumPost(models.Model):
    """Discussion forums for questions and topics"""
    POST_TYPES = [
        ('question', 'Question'),
        ('discussion', 'Discussion'),
        ('tip', 'Study Tip'),
        ('resource', 'Resource Share'),
    ]
    
    title = models.CharField(max_length=300)
    content = models.TextField()
    post_type = models.CharField(max_length=20, choices=POST_TYPES, default='discussion')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='forum_posts')
    category = models.CharField(max_length=20, blank=True)
    related_question = models.ForeignKey(Question, on_delete=models.SET_NULL, null=True, blank=True)
    study_group = models.ForeignKey(StudyGroup, on_delete=models.CASCADE, null=True, blank=True, related_name='posts')
    views = models.IntegerField(default=0)
    likes = models.ManyToManyField(User, related_name='liked_posts', blank=True)
    is_pinned = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['-is_pinned', '-created_at']
    
    def __str__(self):
        return self.title

class ForumComment(models.Model):
    """Comments on forum posts"""
    post = models.ForeignKey(ForumPost, on_delete=models.CASCADE, related_name='comments')
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='forum_comments')
    content = models.TextField()
    parent_comment = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True, related_name='replies')
    likes = models.ManyToManyField(User, related_name='liked_comments', blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['created_at']
    
    def __str__(self):
        return f"Comment by {self.author.username} on {self.post.title[:30]}"

class DailyChallenge(models.Model):
    """Daily/Weekly quiz challenges"""
    CHALLENGE_TYPES = [
        ('daily', 'Daily Challenge'),
        ('weekly', 'Weekly Challenge'),
        ('monthly', 'Monthly Challenge'),
    ]
    
    title = models.CharField(max_length=200)
    description = models.TextField()
    challenge_type = models.CharField(max_length=10, choices=CHALLENGE_TYPES)
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE, related_name='challenges')
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    reward_points = models.IntegerField(default=50)
    participants = models.ManyToManyField(User, through='ChallengeParticipation', related_name='challenges')
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['-start_date']
    
    def __str__(self):
        return f"{self.title} ({self.challenge_type})"

class ChallengeParticipation(models.Model):
    """Track user participation in challenges"""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='challenge_participations')
    challenge = models.ForeignKey(DailyChallenge, on_delete=models.CASCADE, related_name='participations')
    result = models.ForeignKey(Result, on_delete=models.CASCADE, null=True, blank=True)
    completed = models.BooleanField(default=False)
    rank = models.IntegerField(null=True, blank=True)
    points_earned = models.IntegerField(default=0)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        unique_together = ['user', 'challenge']
        ordering = ['-completed_at']
    
    def __str__(self):
        return f"{self.user.username} - {self.challenge.title}"

class MockExam(models.Model):
    """Full-length mock exams for exam simulation"""
    title = models.CharField(max_length=200)
    description = models.TextField()
    total_marks = models.IntegerField()
    duration = models.IntegerField(help_text="Duration in minutes")
    quizzes = models.ManyToManyField(Quiz, related_name='mock_exams')
    questions = models.ManyToManyField(Question, related_name='mock_exams', blank=True)
    passing_score = models.FloatField(default=40.0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return self.title

class UserPreference(models.Model):
    """User preferences for personalized experience"""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='preferences')
    daily_goal = models.IntegerField(default=3, help_text="Daily quiz goal")
    reminder_time = models.TimeField(null=True, blank=True)
    preferred_categories = models.JSONField(default=list, blank=True)
    difficulty_preference = models.CharField(max_length=10, default='medium')
    notifications_enabled = models.BooleanField(default=True)
    email_notifications = models.BooleanField(default=False)
    theme = models.CharField(max_length=10, default='light', choices=[('light', 'Light'), ('dark', 'Dark')])
    
    def __str__(self):
        return f"{self.user.username} Preferences"