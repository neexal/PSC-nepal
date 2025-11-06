from django.contrib import admin
from django import forms
from django.core.exceptions import ValidationError
from django.contrib import messages
import json
from .models import Quiz, Question, Result, StudyMaterial, Notification, UserProfile, Subject, Badge, Streak


class QuizAdminForm(forms.ModelForm):
    questions_json = forms.CharField(
        widget=forms.Textarea(attrs={
            'rows': 15,
            'cols': 80,
            'placeholder': '''Paste your questions in JSON format:
{
  "questions": [
    {
      "question_text": "Your question?",
      "options": ["A", "B", "C", "D"],
      "correct_option": 0,
      "explanation": "Why correct (optional)",
      "difficulty": "medium"
    }
  ]
}'''
        }),
        required=False,
        label='Questions (JSON)',
        help_text='Upload questions in JSON format. Leave empty to add questions manually later.'
    )
    
    class Meta:
        model = Quiz
        fields = '__all__'
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Auto-generate topic if subject is selected
        if self.instance and self.instance.pk:
            # Editing existing quiz - don't change topic
            pass
        else:
            # New quiz - set helpful placeholder
            self.fields['topic'].widget.attrs['placeholder'] = 'Will auto-generate as "Subject Quiz #N"'
    
    def clean_questions_json(self):
        json_data = self.cleaned_data.get('questions_json', '').strip()
        if not json_data:
            return None
        
        try:
            data = json.loads(json_data)
        except json.JSONDecodeError as e:
            raise ValidationError(f'Invalid JSON format: {e}')
        
        # Validate structure
        if 'questions' not in data:
            raise ValidationError('JSON must contain a "questions" array')
        
        if not isinstance(data['questions'], list) or len(data['questions']) == 0:
            raise ValidationError('"questions" must be a non-empty array')
        
        # Validate each question
        for i, q in enumerate(data['questions'], 1):
            if 'question_text' not in q:
                raise ValidationError(f'Question {i}: missing "question_text"')
            if 'options' not in q:
                raise ValidationError(f'Question {i}: missing "options"')
            if 'correct_option' not in q:
                raise ValidationError(f'Question {i}: missing "correct_option"')
            
            if not isinstance(q['options'], list) or len(q['options']) < 2:
                raise ValidationError(f'Question {i}: "options" must have at least 2 items')
            
            if not isinstance(q['correct_option'], int) or q['correct_option'] >= len(q['options']):
                raise ValidationError(f'Question {i}: "correct_option" must be a valid index (0 to {len(q["options"])-1})')
        
        return data


@admin.register(Quiz)
class QuizAdmin(admin.ModelAdmin):
    form = QuizAdminForm
    list_display = ['title', 'topic', 'category', 'subject', 'total_questions', 'duration']
    list_filter = ['category', 'subject']
    search_fields = ['title', 'topic']
    
    fieldsets = (
        ('📝 Basic Information', {
            'fields': ('title', 'subject', 'category', 'duration'),
            'description': 'Fill in the quiz details. Title can be anything descriptive.'
        }),
        ('🤖 Auto-Generated Fields', {
            'fields': ('topic', 'total_questions'),
            'description': '<b>Topic:</b> Auto-generates as "Subject Quiz #N" (you can edit if needed)<br><b>Total Questions:</b> Auto-counts from JSON upload'
        }),
        ('📤 Bulk Upload Questions', {
            'fields': ('questions_json',),
            'description': '''<b>Paste your questions in JSON format.</b> Leave empty to add questions manually later.<br>
            Format: <code>{"questions": [{"question_text": "...", "options": [...], "correct_option": 0}]}</code><br>
            <a href="/static/admin/quiz_example.json" target="_blank">Download Example JSON</a>''',
            'classes': ('wide',)
        }),
    )
    
    readonly_fields = []
    
    def save_model(self, request, obj, form, change):
        # Auto-generate topic if not provided
        if not obj.topic and obj.subject:
            # Count existing quizzes for this subject
            count = Quiz.objects.filter(subject=obj.subject).count() + 1
            obj.topic = f"{obj.subject.name} Quiz #{count}"
        
        # Handle JSON upload
        questions_data = form.cleaned_data.get('questions_json')
        
        if questions_data:
            # Set total_questions from JSON
            obj.total_questions = len(questions_data['questions'])
        elif not change:
            # New quiz without JSON - set to 0 for now
            obj.total_questions = 0
        
        # Save the quiz first
        super().save_model(request, obj, form, change)
        
        # Now create questions from JSON if provided
        if questions_data:
            # Delete existing questions if updating
            obj.questions.all().delete()
            
            # Create new questions
            for q_data in questions_data['questions']:
                Question.objects.create(
                    quiz=obj,
                    subject=obj.subject,
                    question_text=q_data['question_text'],
                    options=q_data['options'],
                    correct_option=q_data['correct_option'],
                    explanation=q_data.get('explanation', ''),
                    difficulty=q_data.get('difficulty', 'medium')
                )
            
            # Update total_questions to match actual count
            obj.total_questions = obj.questions.count()
            obj.save(update_fields=['total_questions'])
            
            # Success message
            messages.success(
                request,
                f'✅ Quiz created successfully! {obj.total_questions} questions uploaded. '
                f'Topic: "{obj.topic}"'
            )

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ['question_text', 'quiz', 'subject', 'difficulty', 'correct_option']
    list_filter = ['difficulty', 'quiz__category', 'subject']
    search_fields = ['question_text']

@admin.register(Result)
class ResultAdmin(admin.ModelAdmin):
    list_display = ['user', 'quiz', 'score', 'correct_count', 'wrong_count', 'date_taken']
    list_filter = ['date_taken', 'quiz__category']
    search_fields = ['user__username', 'quiz__title']

@admin.register(StudyMaterial)
class StudyMaterialAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'material_type', 'download_count', 'created_at']
    list_filter = ['category', 'material_type', 'created_at']
    search_fields = ['title', 'topic']

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ['title', 'notification_type', 'is_active', 'timestamp']
    list_filter = ['notification_type', 'is_active', 'timestamp']
    search_fields = ['title', 'message']

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'role', 'target_post', 'created_at']
    list_filter = ['role', 'created_at']
    search_fields = ['user__username', 'target_post']

@admin.register(Subject)
class SubjectAdmin(admin.ModelAdmin):
    list_display = ['name']
    search_fields = ['name']

@admin.register(Badge)
class BadgeAdmin(admin.ModelAdmin):
    list_display = ['user', 'type', 'date_awarded']
    list_filter = ['type', 'date_awarded']
    search_fields = ['user__username']

@admin.register(Streak)
class StreakAdmin(admin.ModelAdmin):
    list_display = ['user', 'current_streak', 'longest_streak']
    search_fields = ['user__username']
