from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes, renderer_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.authtoken.models import Token
from rest_framework.renderers import JSONRenderer
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.db.models import Q, Avg, Count
from .models import Quiz, Question, Result, StudyMaterial, Notification, UserProfile, Subject, Badge, Streak
from .serializers import (
    QuizSerializer, QuestionSerializer, ResultSerializer, UserSerializer,
    StudyMaterialSerializer, NotificationSerializer, UserProfileSerializer,
    SubjectSerializer, BadgeSerializer, StreakSerializer
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
    streak = None
    try:
        s = Streak.objects.get(user=user)
        streak = {
            'current_streak': s.current_streak,
            'longest_streak': s.longest_streak,
        }
    except Streak.DoesNotExist:
        streak = {'current_streak': 0, 'longest_streak': 0}

    badges = list(Badge.objects.filter(user=user).values('type', 'date_awarded'))

    return Response({
        'total_quizzes': total_results,
        'average_score': round(avg_score, 2),
        'category_stats': list(category_stats),
        'recent_scores': recent_scores,
        'weak_topics': list(weak_topics),
        'streak': streak,
        'badges': badges,
    })
