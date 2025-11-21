from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from quizzes.models import Quiz, DailyChallenge

class Command(BaseCommand):
    help = "Seed sample daily/weekly/monthly challenges"

    def handle(self, *args, **options):
        now = timezone.now()
        quiz = Quiz.objects.order_by('?').first()
        if not quiz:
            self.stdout.write(self.style.ERROR('No quizzes available to create challenges.'))
            return
        created = 0
        # Daily
        DailyChallenge.objects.get_or_create(
            title=f"Daily Challenge - {quiz.title}",
            description="Complete today's focused quiz challenge!",
            challenge_type='daily',
            quiz=quiz,
            start_date=now.replace(hour=0, minute=0, second=0, microsecond=0),
            end_date=(now.replace(hour=0, minute=0, second=0, microsecond=0) + timedelta(days=1)),
            defaults={'reward_points': 25, 'is_active': True}
        )
        created += 1
        # Weekly
        DailyChallenge.objects.get_or_create(
            title=f"Weekly Challenge - {quiz.title}",
            description="Stay consistent this week!",
            challenge_type='weekly',
            quiz=quiz,
            start_date=now - timedelta(days=now.weekday()),
            end_date=(now - timedelta(days=now.weekday()) + timedelta(days=7)),
            defaults={'reward_points': 150, 'is_active': True}
        )
        created += 1
        # Monthly
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        next_month = (month_start + timedelta(days=32)).replace(day=1)
        DailyChallenge.objects.get_or_create(
            title=f"Monthly Challenge - {quiz.title}",
            description="Achieve excellence this month!",
            challenge_type='monthly',
            quiz=quiz,
            start_date=month_start,
            end_date=next_month,
            defaults={'reward_points': 600, 'is_active': True}
        )
        created += 1
        self.stdout.write(self.style.SUCCESS(f'Challenges seeded/ensured (daily/weekly/monthly).'))
