from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from django.utils import timezone
from datetime import timedelta
from .models import Quiz, Question, Result, Achievement, DailyChallenge, UserAnalytics, ForumPost, ForumComment, QuestionFeedback

class QuizFlowTests(TestCase):
	def setUp(self):
		self.user = User.objects.create_user(username='tester', password='pass123')
		self.client = APIClient()
		self.client.force_authenticate(user=self.user)
		self.quiz = Quiz.objects.create(title='Sample Quiz', category='GK', total_questions=2, duration=5)
		self.q1 = Question.objects.create(quiz=self.quiz, question_text='Q1', options=['A','B'], correct_option=0)
		self.q2 = Question.objects.create(quiz=self.quiz, question_text='Q2', options=['A','B'], correct_option=1)

	def test_submit_quiz_awards_achievement_and_badge(self):
		payload = {
			'quiz_id': self.quiz.id,
			'answers': {str(self.q1.id): 0, str(self.q2.id): 1}
		}
		resp = self.client.post('/api/results/submit/', payload, format='json')
		self.assertEqual(resp.status_code, 201)
		# Perfect score achievement
		self.assertTrue(Achievement.objects.filter(user=self.user, achievement_type='perfect_score').exists())
		# Result created
		self.assertEqual(Result.objects.filter(user=self.user).count(), 1)

	def test_leaderboard_basic(self):
		# Create a result for scoring
		Result.objects.create(user=self.user, quiz=self.quiz, score=80, correct_count=1, wrong_count=1, answers={})
		resp = self.client.get('/api/leaderboard/')
		self.assertEqual(resp.status_code, 200)
		data = resp.json()
		self.assertGreaterEqual(len(data), 1)
		self.assertEqual(data[0]['username'], 'tester')

	def test_analytics_recalculate(self):
		Result.objects.create(user=self.user, quiz=self.quiz, score=50, correct_count=1, wrong_count=1, answers={})
		resp = self.client.post('/api/analytics/user/recalculate/')
		self.assertEqual(resp.status_code, 200)
		self.assertTrue(UserAnalytics.objects.filter(user=self.user).exists())
		analytics = UserAnalytics.objects.get(user=self.user)
		self.assertEqual(analytics.total_quizzes, 1)

class ChallengeTests(TestCase):
	def setUp(self):
		self.user = User.objects.create_user(username='challenger', password='pass123')
		self.client = APIClient()
		self.client.force_authenticate(user=self.user)
		self.quiz = Quiz.objects.create(title='Challenge Quiz', category='GK', total_questions=1, duration=5)
		self.challenge = DailyChallenge.objects.create(
			title='Daily Challenge', description='Test', challenge_type='daily', quiz=self.quiz,
			start_date=timezone.now() - timedelta(hours=1), end_date=timezone.now() + timedelta(hours=1), reward_points=25
		)

	def test_active_challenges_list(self):
		resp = self.client.get('/api/challenges/')
		self.assertEqual(resp.status_code, 200)
		data = resp.json()
		self.assertEqual(len(data), 1)
		self.assertEqual(data[0]['title'], 'Daily Challenge')

class ForumFeedbackTests(TestCase):
	def setUp(self):
		self.user = User.objects.create_user(username='poster', password='pass123')
		self.client = APIClient()
		self.client.force_authenticate(user=self.user)
		self.quiz = Quiz.objects.create(title='Forum Quiz', category='GK', total_questions=1, duration=5)
		self.question = Question.objects.create(quiz=self.quiz, question_text='What?', options=['A','B'], correct_option=0)

	def test_create_post_and_comment_like(self):
		post_resp = self.client.post('/api/forum/posts/', {'title':'Help','content':'Need explanation','post_type':'question'}, format='json')
		self.assertEqual(post_resp.status_code, 201)
		post_id = post_resp.json()['id']
		like_resp = self.client.post(f'/api/forum/posts/{post_id}/like/')
		self.assertEqual(like_resp.status_code, 200)
		comment_resp = self.client.post('/api/forum/comments/', {'post':post_id,'content':'Answer here'}, format='json')
		self.assertEqual(comment_resp.status_code, 201)
		comment_id = comment_resp.json()['id']
		comment_like = self.client.post(f'/api/forum/comments/{comment_id}/like/')
		self.assertEqual(comment_like.status_code, 200)

	def test_question_feedback_once(self):
		fb_resp = self.client.post('/api/feedback/', {'question': self.question.id, 'difficulty_rating':3, 'is_helpful':True}, format='json')
		self.assertEqual(fb_resp.status_code, 201)
		# Duplicate should update existing (same count)
		fb_resp2 = self.client.post('/api/feedback/', {'question': self.question.id, 'difficulty_rating':4}, format='json')
		self.assertEqual(fb_resp2.status_code, 201)
		self.assertEqual(QuestionFeedback.objects.filter(user=self.user, question=self.question).count(), 1)
		updated = QuestionFeedback.objects.get(user=self.user, question=self.question)
		self.assertEqual(updated.difficulty_rating, 4)
