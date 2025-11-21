from rest_framework import serializers
from django.contrib.auth.models import User
from .models import (
    Quiz, Question, Result, StudyMaterial, Notification,
    UserProfile, Subject, Badge, Streak, Bookmark, QuestionReport,
    Achievement, UserAnalytics, DailyChallenge, ChallengeParticipation,
    QuestionFeedback, ForumPost, ForumComment
)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']

class UserProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = UserProfile
        fields = '__all__'

class SubjectSerializer(serializers.ModelSerializer):
    class Meta:
        model = Subject
        fields = '__all__'

class QuizSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    class Meta:
        model = Quiz
        fields = '__all__'

class QuestionSerializer(serializers.ModelSerializer):
    subject_name = serializers.CharField(source='subject.name', read_only=True)
    class Meta:
        model = Question
        fields = '__all__'

class ResultSerializer(serializers.ModelSerializer):
    quiz_title = serializers.CharField(source='quiz.title', read_only=True)
    quiz_category = serializers.CharField(source='quiz.category', read_only=True)
    user_name = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = Result
        fields = '__all__'

class StudyMaterialSerializer(serializers.ModelSerializer):
    class Meta:
        model = StudyMaterial
        fields = '__all__'

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = '__all__'

class BadgeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Badge
        fields = '__all__'

class StreakSerializer(serializers.ModelSerializer):
    class Meta:
        model = Streak
        fields = '__all__'

class BookmarkSerializer(serializers.ModelSerializer):
    question_text = serializers.CharField(source='question.question_text', read_only=True)
    quiz_title = serializers.CharField(source='question.quiz.title', read_only=True)
    quiz_id = serializers.IntegerField(source='question.quiz.id', read_only=True)
    
    class Meta:
        model = Bookmark
        fields = '__all__'
        read_only_fields = ['user', 'created_at']

class QuestionReportSerializer(serializers.ModelSerializer):
    question_text = serializers.CharField(source='question.question_text', read_only=True)
    quiz_title = serializers.CharField(source='question.quiz.title', read_only=True)
    user_name = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = QuestionReport
        fields = '__all__'
        read_only_fields = ['user', 'created_at', 'status']

class AchievementSerializer(serializers.ModelSerializer):
    class Meta:
        model = Achievement
        fields = '__all__'
        read_only_fields = ['user', 'date_earned']

class UserAnalyticsSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    class Meta:
        model = UserAnalytics
        fields = '__all__'
        read_only_fields = ['user', 'last_updated', 'rank']

class DailyChallengeSerializer(serializers.ModelSerializer):
    quiz_title = serializers.CharField(source='quiz.title', read_only=True)
    class Meta:
        model = DailyChallenge
        fields = '__all__'

class ChallengeParticipationSerializer(serializers.ModelSerializer):
    challenge_title = serializers.CharField(source='challenge.title', read_only=True)
    quiz_id = serializers.IntegerField(source='challenge.quiz.id', read_only=True)
    class Meta:
        model = ChallengeParticipation
        fields = '__all__'
        read_only_fields = ['user', 'completed_at', 'rank']

class LeaderboardEntrySerializer(serializers.Serializer):
    rank = serializers.IntegerField()
    username = serializers.CharField()
    total_score = serializers.FloatField()
    quizzes_taken = serializers.IntegerField()
    average_score = serializers.FloatField()
    profile_picture = serializers.CharField(allow_null=True)
    is_current_user = serializers.BooleanField()

class QuestionFeedbackSerializer(serializers.ModelSerializer):
    question_text = serializers.CharField(source='question.question_text', read_only=True)
    class Meta:
        model = QuestionFeedback
        fields = '__all__'
        read_only_fields = ['user', 'created_at']

class ForumCommentSerializer(serializers.ModelSerializer):
    author_username = serializers.CharField(source='author.username', read_only=True)
    class Meta:
        model = ForumComment
        fields = '__all__'
        read_only_fields = ['author', 'created_at', 'updated_at', 'likes']

class ForumPostSerializer(serializers.ModelSerializer):
    author_username = serializers.CharField(source='author.username', read_only=True)
    comments_count = serializers.IntegerField(source='comments.count', read_only=True)
    likes_count = serializers.IntegerField(source='likes.count', read_only=True)
    class Meta:
        model = ForumPost
        fields = '__all__'
        read_only_fields = ['author', 'created_at', 'updated_at', 'views', 'likes']
