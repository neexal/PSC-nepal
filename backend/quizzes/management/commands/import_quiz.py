"""
Management command to import quiz data from JSON file

Usage:
    python manage.py import_quiz path/to/quiz.json
    python manage.py import_quiz quiz_data/*.json  (import multiple)
"""
import json
from django.core.management.base import BaseCommand, CommandError
from quizzes.models import Quiz, Question, Subject


class Command(BaseCommand):
    help = 'Import quiz and questions from JSON file'

    def add_arguments(self, parser):
        parser.add_argument('json_files', nargs='+', type=str, help='Path to JSON file(s)')
        parser.add_argument(
            '--update',
            action='store_true',
            help='Update quiz if it already exists (by title)',
        )

    def handle(self, *args, **options):
        success_count = 0
        error_count = 0

        for json_file in options['json_files']:
            try:
                self.stdout.write(f"\nProcessing: {json_file}")
                with open(json_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                
                # Validate data structure
                if not self.validate_json_structure(data):
                    self.stdout.write(self.style.ERROR(f"Invalid JSON structure in {json_file}"))
                    error_count += 1
                    continue
                
                # Import the quiz
                quiz = self.import_quiz_data(data, options['update'])
                self.stdout.write(self.style.SUCCESS(f"✓ Successfully imported quiz: {quiz.title}"))
                self.stdout.write(f"  - Category: {quiz.category}")
                self.stdout.write(f"  - Subject: {quiz.subject.name if quiz.subject else 'None'}")
                self.stdout.write(f"  - Questions: {quiz.questions.count()}")
                success_count += 1
                
            except FileNotFoundError:
                self.stdout.write(self.style.ERROR(f"File not found: {json_file}"))
                error_count += 1
            except json.JSONDecodeError as e:
                self.stdout.write(self.style.ERROR(f"Invalid JSON in {json_file}: {e}"))
                error_count += 1
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Error processing {json_file}: {e}"))
                error_count += 1
        
        # Summary
        self.stdout.write("\n" + "=" * 50)
        self.stdout.write(self.style.SUCCESS(f"✓ Successfully imported: {success_count}"))
        if error_count > 0:
            self.stdout.write(self.style.ERROR(f"✗ Failed: {error_count}"))
        self.stdout.write("=" * 50)

    def validate_json_structure(self, data):
        """Validate that JSON has required fields"""
        required_fields = ['title', 'category', 'duration', 'questions']
        for field in required_fields:
            if field not in data:
                self.stdout.write(self.style.ERROR(f"Missing required field: {field}"))
                return False
        
        if not isinstance(data['questions'], list) or len(data['questions']) == 0:
            self.stdout.write(self.style.ERROR("Questions must be a non-empty list"))
            return False
        
        # Validate each question
        for i, q in enumerate(data['questions']):
            required_q_fields = ['question_text', 'options', 'correct_option']
            for field in required_q_fields:
                if field not in q:
                    self.stdout.write(self.style.ERROR(
                        f"Question {i+1} missing required field: {field}"
                    ))
                    return False
            
            if not isinstance(q['options'], list) or len(q['options']) < 2:
                self.stdout.write(self.style.ERROR(
                    f"Question {i+1}: options must be a list with at least 2 items"
                ))
                return False
            
            if not isinstance(q['correct_option'], int) or q['correct_option'] >= len(q['options']):
                self.stdout.write(self.style.ERROR(
                    f"Question {i+1}: correct_option must be a valid index"
                ))
                return False
        
        return True

    def import_quiz_data(self, data, update=False):
        """Import quiz and questions from validated data"""
        # Get or create subject
        subject = None
        if 'subject' in data and data['subject']:
            subject, _ = Subject.objects.get_or_create(
                name=data['subject'],
                defaults={'description': f"{data['subject']} subject"}
            )
        
        # Check if quiz exists
        quiz = None
        if update:
            try:
                quiz = Quiz.objects.get(title=data['title'])
                # Delete old questions if updating
                quiz.questions.all().delete()
                self.stdout.write(f"  Updating existing quiz: {quiz.title}")
            except Quiz.DoesNotExist:
                pass
        
        # Create or update quiz
        if quiz:
            quiz.category = data['category']
            quiz.topic = data.get('topic', '')
            quiz.total_questions = len(data['questions'])
            quiz.duration = data['duration']
            quiz.subject = subject
            quiz.save()
        else:
            quiz = Quiz.objects.create(
                title=data['title'],
                topic=data.get('topic', ''),
                category=data['category'],
                total_questions=len(data['questions']),
                duration=data['duration'],
                subject=subject
            )
        
        # Create questions
        for q_data in data['questions']:
            Question.objects.create(
                quiz=quiz,
                question_text=q_data['question_text'],
                options=q_data['options'],
                correct_option=q_data['correct_option'],
                explanation=q_data.get('explanation', ''),
                difficulty=q_data.get('difficulty', 'medium'),
                subject=subject
            )
        
        return quiz
