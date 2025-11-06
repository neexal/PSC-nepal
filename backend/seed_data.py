"""
Seed script to populate database with sample data
Run with: python seed_data.py
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'psc_nepal.settings')
django.setup()

from django.contrib.auth.models import User
from quizzes.models import Subject, Quiz, Question, StudyMaterial, Notification

def create_subjects():
    """Create sample subjects"""
    subjects_data = [
        {'name': 'General Knowledge', 'description': 'General Knowledge and Current Affairs'},
        {'name': 'Nepali', 'description': 'Nepali Language and Literature'},
        {'name': 'English', 'description': 'English Language and Grammar'},
        {'name': 'Mathematics', 'description': 'Mathematics and Quantitative Aptitude'},
        {'name': 'Computer/IT', 'description': 'Computer Science and Information Technology'},
        {'name': 'Constitution', 'description': 'Constitution of Nepal'},
        {'name': 'History', 'description': 'History of Nepal'},
        {'name': 'Geography', 'description': 'Geography of Nepal'},
    ]
    
    subjects = []
    for data in subjects_data:
        subject, created = Subject.objects.get_or_create(
            name=data['name'],
            defaults={'description': data['description']}
        )
        subjects.append(subject)
        if created:
            print(f"✓ Created subject: {subject.name}")
        else:
            print(f"- Subject already exists: {subject.name}")
    
    return subjects

def create_sample_quiz(subject):
    """Create a sample quiz with questions"""
    quiz, created = Quiz.objects.get_or_create(
        title=f'{subject.name} - Practice Quiz 1',
        defaults={
            'category': 'GK',
            'total_questions': 5,
            'duration': 15,
            'subject': subject
        }
    )
    
    if created:
        print(f"✓ Created quiz: {quiz.title}")
        
        # Sample questions
        questions_data = [
            {
                'question_text': 'What is the capital of Nepal?',
                'options': ['Kathmandu', 'Pokhara', 'Lalitpur', 'Bhaktapur'],
                'correct_option': 0,
                'explanation': 'Kathmandu is the capital city of Nepal.',
                'difficulty': 'easy'
            },
            {
                'question_text': 'Who is known as the "Father of the Nation" in Nepal?',
                'options': ['King Prithvi Narayan Shah', 'BP Koirala', 'King Tribhuvan', 'Madan Bhandari'],
                'correct_option': 0,
                'explanation': 'King Prithvi Narayan Shah unified Nepal.',
                'difficulty': 'medium'
            },
            {
                'question_text': 'In which year did Nepal become a federal democratic republic?',
                'options': ['2006', '2007', '2008', '2015'],
                'correct_option': 2,
                'explanation': 'Nepal became a federal democratic republic in 2008.',
                'difficulty': 'medium'
            },
            {
                'question_text': 'What is the highest peak in Nepal?',
                'options': ['Mount Everest', 'Kanchenjunga', 'Lhotse', 'Makalu'],
                'correct_option': 0,
                'explanation': 'Mount Everest (Sagarmatha) is the highest peak.',
                'difficulty': 'easy'
            },
            {
                'question_text': 'How many provinces are there in Nepal?',
                'options': ['5', '6', '7', '8'],
                'correct_option': 2,
                'explanation': 'Nepal has 7 provinces as per the 2015 constitution.',
                'difficulty': 'easy'
            }
        ]
        
        for q_data in questions_data:
            Question.objects.create(
                quiz=quiz,
                subject=subject,
                **q_data
            )
        print(f"  ✓ Added {len(questions_data)} questions")
    else:
        print(f"- Quiz already exists: {quiz.title}")

def create_study_materials():
    """Create sample study materials"""
    materials_data = [
        {
            'title': 'PSC Preparation Guide 2024',
            'topic': 'Complete Guide',
            'category': 'GK',
            'material_type': 'PDF',
            'file_url': 'https://example.com/psc-guide.pdf',
            'description': 'Comprehensive guide for PSC exam preparation covering all major topics.'
        },
        {
            'title': 'Nepali Grammar Basics',
            'topic': 'Grammar',
            'category': 'Nepali',
            'material_type': 'PDF',
            'file_url': 'https://example.com/nepali-grammar.pdf',
            'description': 'Essential Nepali grammar rules and examples for PSC exams.'
        },
        {
            'title': 'Constitution of Nepal Summary',
            'topic': 'Constitution',
            'category': 'GK',
            'material_type': 'Note',
            'description': 'Key points and articles from the Constitution of Nepal 2015.'
        }
    ]
    
    for data in materials_data:
        material, created = StudyMaterial.objects.get_or_create(
            title=data['title'],
            defaults=data
        )
        if created:
            print(f"✓ Created study material: {material.title}")
        else:
            print(f"- Study material already exists: {material.title}")

def create_notifications():
    """Create sample notifications"""
    notifications_data = [
        {
            'title': 'Welcome to PSC Nepal Prep!',
            'message': 'Start your preparation journey with our comprehensive quizzes and study materials.',
            'notification_type': 'news',
            'is_active': True
        },
        {
            'title': 'New Quizzes Added',
            'message': 'Check out the latest practice quizzes for General Knowledge and Nepali subjects.',
            'notification_type': 'update',
            'is_active': True
        }
    ]
    
    for data in notifications_data:
        notification, created = Notification.objects.get_or_create(
            title=data['title'],
            defaults=data
        )
        if created:
            print(f"✓ Created notification: {notification.title}")
        else:
            print(f"- Notification already exists: {notification.title}")

def create_admin_user():
    """Create admin user if it doesn't exist"""
    username = 'admin'
    email = 'admin@pscnepal.com'
    password = 'admin123'
    
    if not User.objects.filter(username=username).exists():
        User.objects.create_superuser(username=username, email=email, password=password)
        print(f"✓ Created admin user: {username} (password: {password})")
    else:
        print(f"- Admin user already exists: {username}")

def main():
    print("=" * 50)
    print("PSC Nepal - Database Seeding")
    print("=" * 50)
    print()
    
    # Create admin user
    print("Creating admin user...")
    create_admin_user()
    print()
    
    # Create subjects
    print("Creating subjects...")
    subjects = create_subjects()
    print()
    
    # Create sample quiz for first subject
    print("Creating sample quiz...")
    if subjects:
        create_sample_quiz(subjects[0])
    print()
    
    # Create study materials
    print("Creating study materials...")
    create_study_materials()
    print()
    
    # Create notifications
    print("Creating notifications...")
    create_notifications()
    print()
    
    print("=" * 50)
    print("✓ Database seeding completed!")
    print("=" * 50)
    print()
    print("You can now:")
    print("1. Run the server: python manage.py runserver")
    print("2. Access admin panel: http://localhost:8000/admin")
    print("   Username: admin")
    print("   Password: admin123")
    print()

if __name__ == '__main__':
    main()
