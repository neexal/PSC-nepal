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