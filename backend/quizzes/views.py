from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes, renderer_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from rest_framework.renderers import JSONRenderer
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.db.models import Q, Avg, Count, Sum, Max
from django.utils import timezone
from datetime import timedelta
from .models import (
    Quiz, Question, Result, StudyMaterial, Notification, UserProfile,
    Subject, Badge, Streak, Bookmark, QuestionReport, Achievement,
    UserAnalytics, DailyChallenge, ChallengeParticipation,
    QuestionFeedback, ForumPost, ForumComment
)
from .serializers import (
    QuizSerializer, QuestionSerializer, ResultSerializer, UserSerializer,
    StudyMaterialSerializer, NotificationSerializer, UserProfileSerializer,
    SubjectSerializer, BadgeSerializer, StreakSerializer, BookmarkSerializer,
    QuestionReportSerializer, AchievementSerializer, UserAnalyticsSerializer,
    DailyChallengeSerializer, ChallengeParticipationSerializer,
    LeaderboardEntrySerializer, QuestionFeedbackSerializer,
    ForumPostSerializer, ForumCommentSerializer
)

def update_user_streak(user):
    """Update user's streak based on their quiz activity"""
    streak, created = Streak.objects.get_or_create(user=user)
    today = timezone.now().date()
    
    if created or streak.last_active_date is None:
        # First time taking a quiz
        streak.current_streak = 1
        streak.longest_streak = 1
        streak.last_active_date = today
        streak.save()
        print(f"Streak initialized for {user.username}: 1 day")
        return
    
    # Check if already took a quiz today
    if streak.last_active_date == today:
        # Already took a quiz today, no change
        print(f"Streak unchanged for {user.username}: already active today")
        return
    
    # Check if it's consecutive days
    yesterday = today - timedelta(days=1)
    if streak.last_active_date == yesterday:
        # Consecutive day! Increment streak
        streak.current_streak += 1
        if streak.current_streak > streak.longest_streak:
            streak.longest_streak = streak.current_streak
        streak.last_active_date = today
        streak.save()
        print(f"Streak increased for {user.username}: {streak.current_streak} days")
        
        # Award 7-day streak badge
        if streak.current_streak >= 7:
            award_badge(user, 'streak_7')
    else:
        # Streak broken, reset to 1
        streak.current_streak = 1
        streak.last_active_date = today
        streak.save()
        print(f"Streak reset for {user.username}: was inactive since {streak.last_active_date}")

def award_badge(user, badge_type):
    """Award a badge to user if they don't have it already"""
    badge, created = Badge.objects.get_or_create(user=user, type=badge_type)
    if created:
        print(f"🏆 Badge '{badge_type}' awarded to {user.username}!")
        return True
    return False

def check_and_award_badges(user, score):
    """Check if user earned any badges and award them"""
    # Award 90%+ score badge
    if score >= 90:
        award_badge(user, 'score_90')
    
    # Award 10 quizzes badge
    total_quizzes = Result.objects.filter(user=user).count()
    if total_quizzes >= 10:
        award_badge(user, 'attempt_10')
    # Achievements integration (simple triggers)
    if total_quizzes == 1:
        Achievement.objects.get_or_create(
            user=user,
            achievement_type='first_quiz',
            defaults={
                'title': 'First Quiz Completed',
                'description': 'Completed the first quiz',
                'icon': 'rocket',
                'points': 10
            }
        )
    if score == 100:
        Achievement.objects.get_or_create(
            user=user,
            achievement_type='perfect_score',
            defaults={
                'title': 'Perfect Score',
                'description': 'Achieved a 100% score in a quiz',
                'icon': 'star',
                'points': 25
            }
        )

class QuizViewSet(viewsets.ModelViewSet):
    queryset = Quiz.objects.all()
    serializer_class = QuizSerializer
    permission_classes = [AllowAny]  # Allow viewing quizzes without auth

    @action(detail=True, methods=['get'])
    def questions(self, request, pk=None):
        quiz = self.get_object()
        questions = Question.objects.filter(quiz=quiz).order_by('id')
        serializer = QuestionSerializer(questions, many=True)
        return Response(serializer.data)

class QuestionViewSet(viewsets.ModelViewSet):
    queryset = Question.objects.all()
    serializer_class = QuestionSerializer
    permission_classes = [IsAuthenticated]

class ResultViewSet(viewsets.ModelViewSet):
    queryset = Result.objects.all()
    serializer_class = ResultSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Result.objects.filter(user=self.request.user).order_by('-date_taken')

    @action(detail=False, methods=['post'])
    def submit(self, request):
        quiz_id = request.data.get('quiz_id')
        answers = request.data.get('answers', {})

        try:
            quiz = Quiz.objects.get(id=quiz_id)
            questions = Question.objects.filter(quiz=quiz).order_by('id')

            correct_count = 0
            wrong_count = 0
            total_questions = len(questions)

            print(f"\n=== QUIZ SUBMISSION ===")
            print(f"Quiz ID: {quiz_id}, Total Questions: {total_questions}")
            print(f"Received answers: {answers}")

            for question in questions:
                user_answer = answers.get(str(question.id))
                # Also try integer key
                if user_answer is None:
                    user_answer = answers.get(question.id)
                
                is_correct = False
                if user_answer is not None:
                    user_answer_int = int(user_answer) if not isinstance(user_answer, int) else user_answer
                    is_correct = user_answer_int == question.correct_option
                    
                    print(f"Q{question.id}: user={user_answer_int}, correct={question.correct_option}, match={is_correct}")
                    
                    if is_correct:
                        correct_count += 1
                    else:
                        wrong_count += 1
                else:
                    print(f"Q{question.id}: No answer provided")
                    wrong_count += 1

            score = (correct_count / total_questions * 100) if total_questions > 0 else 0
            
            print(f"Final Score: {score}% (Correct: {correct_count}, Wrong: {wrong_count})")
            print(f"======================\n")

            result = Result.objects.create(
                user=request.user,
                quiz=quiz,
                score=score,
                correct_count=correct_count,
                wrong_count=wrong_count,
                answers=answers  # Store user answers
            )

            # Update user streak
            update_user_streak(request.user)
            
            # Check and award badges
            check_and_award_badges(request.user, score)

            serializer = ResultSerializer(result)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        except Quiz.DoesNotExist:
            return Response({'error': 'Quiz not found'}, status=status.HTTP_404_NOT_FOUND)
    
    @action(detail=True, methods=['get'])
    def details(self, request, pk=None):
        """Get detailed result with all questions, user answers, and correct answers"""
        try:
            result = self.get_object()
            quiz = result.quiz
            questions = Question.objects.filter(quiz=quiz).order_by('id')
            
            detailed_questions = []
            for question in questions:
                # Try to get user answer with both string and int keys
                user_answer = result.answers.get(str(question.id))
                if user_answer is None:
                    user_answer = result.answers.get(question.id)
                
                # Convert to int if it's not None
                if user_answer is not None:
                    user_answer_int = int(user_answer) if not isinstance(user_answer, int) else user_answer
                else:
                    user_answer_int = None
                
                # Check if answer is correct
                is_correct = user_answer_int == question.correct_option if user_answer_int is not None else False
                
                # Debug logging
                print(f"Question {question.id}: user_answer={user_answer}, user_answer_int={user_answer_int}, correct={question.correct_option}, is_correct={is_correct}")
                
                detailed_questions.append({
                    'id': question.id,
                    'question_text': question.question_text,
                    'options': question.options,
                    'correct_option': question.correct_option,
                    'user_answer': user_answer_int,
                    'is_correct': is_correct,
                    'explanation': question.explanation,
                    'difficulty': question.difficulty
                })
            
            return Response({
                'id': result.id,
                'quiz': {
                    'id': quiz.id,
                    'title': quiz.title,
                    'category': quiz.category
                },
                'score': result.score,
                'correct_count': result.correct_count,
                'wrong_count': result.wrong_count,
                'date_taken': result.date_taken,
                'questions': detailed_questions
            })
        except Result.DoesNotExist:
            return Response({'error': 'Result not found'}, status=status.HTTP_404_NOT_FOUND)

class SubjectViewSet(viewsets.ModelViewSet):
    queryset = Subject.objects.all().order_by('name')
    serializer_class = SubjectSerializer
    permission_classes = [AllowAny]

class BadgeViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = BadgeSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Badge.objects.filter(user=self.request.user)

class StreakViewSet(viewsets.ModelViewSet):
    serializer_class = StreakSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Streak.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class BookmarkViewSet(viewsets.ModelViewSet):
    serializer_class = BookmarkSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Bookmark.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=False, methods=['post'])
    def toggle(self, request):
        """Toggle bookmark for a question"""
        question_id = request.data.get('question_id')
        if not question_id:
            return Response({'error': 'question_id required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            question = Question.objects.get(id=question_id)
            bookmark = Bookmark.objects.filter(user=request.user, question=question).first()
            
            if bookmark:
                bookmark.delete()
                return Response({'message': 'Bookmark removed', 'bookmarked': False})
            else:
                bookmark = Bookmark.objects.create(user=request.user, question=question)
                return Response({
                    'message': 'Bookmark added',
                    'bookmarked': True,
                    'bookmark': BookmarkSerializer(bookmark).data
                }, status=status.HTTP_201_CREATED)
        except Question.DoesNotExist:
            return Response({'error': 'Question not found'}, status=status.HTTP_404_NOT_FOUND)

class QuestionReportViewSet(viewsets.ModelViewSet):
    serializer_class = QuestionReportSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        if self.request.user.is_staff:
            return QuestionReport.objects.all()
        return QuestionReport.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user, status='pending')

# Custom auth views
@api_view(['POST'])
@permission_classes([AllowAny])
@renderer_classes([JSONRenderer])
def register(request):
    username = request.data.get('username')
    email = request.data.get('email')
    password = request.data.get('password')

    if not username or not email or not password:
        response = Response({'error': 'Username, email, and password are required'}, status=400)
        response['Content-Type'] = 'application/json'
        return response

    if User.objects.filter(username=username).exists():
        response = Response({'error': 'Username already exists'}, status=400)
        response['Content-Type'] = 'application/json'
        return response

    if User.objects.filter(email=email).exists():
        response = Response({'error': 'Email already exists'}, status=400)
        response['Content-Type'] = 'application/json'
        return response

    user = User.objects.create_user(username=username, email=email, password=password)
    token, created = Token.objects.get_or_create(user=user)
    profile, _ = UserProfile.objects.get_or_create(user=user)
    
    response = Response({
        'token': token.key,
        'user': UserSerializer(user).data,
        'profile': UserProfileSerializer(profile).data
    }, status=201)
    response['Content-Type'] = 'application/json'
    return response

@api_view(['POST'])
@permission_classes([AllowAny])
@renderer_classes([JSONRenderer])
def login(request):
    username = request.data.get('username')
    password = request.data.get('password')

    user = authenticate(username=username, password=password)
    if user:
        token, created = Token.objects.get_or_create(user=user)
        profile, _ = UserProfile.objects.get_or_create(user=user)
        response = Response({
            'token': token.key,
            'user': UserSerializer(user).data,
            'profile': UserProfileSerializer(profile).data
        })
        response['Content-Type'] = 'application/json'
        return response
    response = Response({'error': 'Invalid credentials'}, status=400)
    response['Content-Type'] = 'application/json'
    return response

# Study Materials ViewSet
class StudyMaterialViewSet(viewsets.ModelViewSet):
    queryset = StudyMaterial.objects.all()
    serializer_class = StudyMaterialSerializer
    permission_classes = [AllowAny]  # Allow viewing without auth
    
    def get_queryset(self):
        queryset = StudyMaterial.objects.all()
        category = self.request.query_params.get('category', None)
        if category:
            queryset = queryset.filter(category=category)
        return queryset
    
    @action(detail=True, methods=['post'])
    def increment_download(self, request, pk=None):
        material = self.get_object()
        material.download_count += 1
        material.save()
        return Response({'download_count': material.download_count})

# Notifications ViewSet
class NotificationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        queryset = Notification.objects.filter(is_active=True)
        user = self.request.user
        if user.is_authenticated:
            # Get notifications for all users or specific user
            queryset = queryset.filter(
                Q(target_users__isnull=True) | Q(target_users=user)
            ).distinct()
        else:
            queryset = queryset.filter(target_users__isnull=True)
        return queryset

# User Profile ViewSet
class UserProfileViewSet(viewsets.ModelViewSet):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return UserProfile.objects.filter(user=self.request.user)
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

# Analytics API
class AchievementViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = AchievementSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Achievement.objects.filter(user=self.request.user)

class UserAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = UserAnalyticsSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserAnalytics.objects.filter(user=self.request.user)

    @action(detail=False, methods=['post'])
    def recalculate(self, request):
        user = request.user
        results = Result.objects.filter(user=user)
        total_quizzes = results.count()
        total_questions_answered = results.aggregate(total=Sum('correct_count') + Sum('wrong_count'))['total'] if total_quizzes else 0
        avg_score = results.aggregate(avg=Avg('score'))['avg'] or 0

        # Category stats
        category_stats = {}
        cat_rows = results.values('quiz__category').annotate(
            quizzes=Count('id'),
            avg_score=Avg('score'),
            best_score=Max('score')
        )
        for row in cat_rows:
            category_stats[row['quiz__category']] = {
                'quizzes': row['quizzes'],
                'avg_score': round(row['avg_score'] or 0, 2),
                'best_score': round(row['best_score'] or 0, 2)
            }

        best_category = None
        worst_category = None
        if category_stats:
            sorted_cats = sorted(category_stats.items(), key=lambda x: x[1]['avg_score'])
            worst_category = sorted_cats[0][0]
            best_category = sorted_cats[-1][0]

        analytics_obj, _ = UserAnalytics.objects.get_or_create(user=user)
        analytics_obj.total_quizzes = total_quizzes
        analytics_obj.total_questions_answered = total_questions_answered or 0
        analytics_obj.average_score = round(avg_score, 2)
        analytics_obj.best_category = best_category or ''
        analytics_obj.worst_category = worst_category or ''
        analytics_obj.category_stats = category_stats
        analytics_obj.save()
        # Recalculate global ranks based on average_score (descending)
        all_analytics = UserAnalytics.objects.all().order_by('-average_score')
        for idx, ua in enumerate(all_analytics, start=1):
            if ua.rank != idx:
                ua.rank = idx
                ua.save(update_fields=['rank'])
        return Response(UserAnalyticsSerializer(analytics_obj).data)

class DailyChallengeViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = DailyChallengeSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        now = timezone.now()
        return DailyChallenge.objects.filter(start_date__lte=now, end_date__gte=now, is_active=True)

class ChallengeParticipationViewSet(viewsets.ModelViewSet):
    serializer_class = ChallengeParticipationSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return ChallengeParticipation.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class QuestionFeedbackViewSet(viewsets.ModelViewSet):
    serializer_class = QuestionFeedbackSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return QuestionFeedback.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        # Prevent duplicate feedback gracefully
        question = serializer.validated_data.get('question')
        existing = QuestionFeedback.objects.filter(user=self.request.user, question=question).first()
        if existing:
            # Update existing instead of raising integrity error
            for field, value in serializer.validated_data.items():
                if field not in ['user', 'question']:
                    setattr(existing, field, value)
            existing.save()
            serializer.instance = existing
        else:
            serializer.save(user=self.request.user)

class ForumPostViewSet(viewsets.ModelViewSet):
    serializer_class = ForumPostSerializer
    permission_classes = [IsAuthenticated]
    queryset = ForumPost.objects.all()

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        post = self.get_object()
        if request.user in post.likes.all():
            post.likes.remove(request.user)
            return Response({'liked': False})
        post.likes.add(request.user)
        return Response({'liked': True})

    @action(detail=True, methods=['post'])
    def view(self, request, pk=None):
        post = self.get_object()
        post.views += 1
        post.save(update_fields=['views'])
        return Response({'views': post.views})

class ForumCommentViewSet(viewsets.ModelViewSet):
    serializer_class = ForumCommentSerializer
    permission_classes = [IsAuthenticated]
    queryset = ForumComment.objects.all()

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'])
    def like(self, request, pk=None):
        comment = self.get_object()
        if request.user in comment.likes.all():
            comment.likes.remove(request.user)
            return Response({'liked': False})
        comment.likes.add(request.user)
        return Response({'liked': True})

@api_view(['GET'])
def analytics(request):
    if not request.user.is_authenticated:
        return Response({'error': 'Authentication required'}, status=401)
    
    user = request.user
    
    # Overall stats
    total_results = Result.objects.filter(user=user).count()
    avg_score = Result.objects.filter(user=user).aggregate(Avg('score'))['score__avg'] or 0
    
    # Category-wise performance
    category_stats = Result.objects.filter(user=user).values('quiz__category').annotate(
        avg_score=Avg('score'),
        count=Count('id')
    )
    
    # Recent performance (last 5 quizzes)
    recent_results = Result.objects.filter(user=user).order_by('-date_taken')[:5]
    recent_scores = [r.score for r in recent_results]
    
    # Weak topics (categories with score < 50)
    weak_topics = Result.objects.filter(user=user, score__lt=50).values('quiz__category').annotate(
        count=Count('id'),
        avg_score=Avg('score')
    )
    
    # Streak and badges
    current_streak = 0
    longest_streak = 0
    try:
        s = Streak.objects.get(user=user)
        current_streak = s.current_streak
        longest_streak = s.longest_streak
    except Streak.DoesNotExist:
        pass

    badges = list(Badge.objects.filter(user=user).values('type', 'date_awarded'))

    return Response({
        'total_quizzes': total_results,
        'average_score': round(avg_score, 2),
        'category_stats': list(category_stats),
        'recent_scores': recent_scores,
        'weak_topics': list(weak_topics),
        'current_streak': current_streak,
        'longest_streak': longest_streak,
        'badges': badges,
        'user_name': user.username,
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def leaderboard(request):
    """Multi-mode leaderboard: global, category, timeframe"""
    category = request.query_params.get('category')  # e.g., GK
    period = request.query_params.get('period')  # daily, weekly, monthly

    results = Result.objects.all()
    if category:
        results = results.filter(quiz__category=category)

    now = timezone.now()
    if period == 'daily':
        results = results.filter(date_taken__date=now.date())
    elif period == 'weekly':
        week_ago = now - timedelta(days=7)
        results = results.filter(date_taken__gte=week_ago)
    elif period == 'monthly':
        month_ago = now - timedelta(days=30)
        results = results.filter(date_taken__gte=month_ago)

    # Aggregate per user
    aggregated = results.values('user').annotate(
        total_score=Sum('score'),
        quizzes_taken=Count('id'),
        average_score=Avg('score')
    ).order_by('-total_score')[:50]

    # Map user objects for efficiency
    user_map = {u.id: u for u in User.objects.filter(id__in=[a['user'] for a in aggregated])}
    data = []
    for rank, row in enumerate(aggregated, 1):
        user_obj = user_map[row['user']]
        profile = UserProfile.objects.filter(user=user_obj).first()
        data.append({
            'rank': rank,
            'username': user_obj.username,
            'total_score': round(row['total_score'] or 0, 2),
            'quizzes_taken': row['quizzes_taken'],
            'average_score': round(row['average_score'] or 0, 2),
            'profile_picture': profile.profile_picture if profile else None,
            'is_current_user': user_obj == request.user
        })
    serializer = LeaderboardEntrySerializer(data, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([AllowAny])
def google_login(request):
    """Handle Google Sign-In"""
    token = request.data.get('token')
    email = request.data.get('email')
    name = request.data.get('name')
    photo_url = request.data.get('photoUrl')
    
    if not email:
        return Response({'error': 'Email is required'}, status=400)
        
    # Check if user exists
    try:
        user = User.objects.get(email=email)
        created = False
    except User.DoesNotExist:
        # Create new user
        username = email.split('@')[0]
        # Ensure unique username
        base_username = username
        counter = 1
        while User.objects.filter(username=username).exists():
            username = f"{base_username}{counter}"
            counter += 1
            
        user = User.objects.create_user(
            username=username,
            email=email,
            password=User.objects.make_random_password()
        )
        created = True
        
    # Get or create profile
    profile, _ = UserProfile.objects.get_or_create(user=user)
    if photo_url and not profile.profile_picture:
        profile.profile_picture = photo_url
        profile.save()
        
    # Generate token
    token, _ = Token.objects.get_or_create(user=user)
    
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data,
        'profile': UserProfileSerializer(profile).data,
        'created': created
    })
