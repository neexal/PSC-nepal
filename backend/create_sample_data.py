import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'psc_nepal.settings')
django.setup()

from quizzes.models import Quiz, Question

# Create sample quiz
quiz = Quiz.objects.create(
    title='GK Quiz',
    category='GK',
    total_questions=2,
    duration=10
)

# Create questions
Question.objects.create(
    quiz=quiz,
    question_text='What is the capital of Nepal?',
    options=['Kathmandu', 'Pokhara', 'Lalitpur', 'Bhaktapur'],
    correct_option=0,
    explanation='Kathmandu is the capital.',
    difficulty='Easy'
)

Question.objects.create(
    quiz=quiz,
    question_text='Who is the first PM of Nepal?',
    options=['BP Koirala', 'Jung Bahadur Rana', 'Madan Mohan Malaviya', 'Surya Bahadur Thapa'],
    correct_option=0,
    explanation='BP Koirala was the first PM.',
    difficulty='Medium'
)

print('Sample data created successfully!')
