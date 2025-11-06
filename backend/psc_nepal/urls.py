from django.contrib import admin
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from quizzes.views import (
    QuizViewSet, QuestionViewSet, ResultViewSet, register, login,
    StudyMaterialViewSet, NotificationViewSet, UserProfileViewSet, analytics,
    SubjectViewSet, BadgeViewSet, StreakViewSet, BookmarkViewSet, QuestionReportViewSet
)
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

router = DefaultRouter()
router.register(r'quizzes', QuizViewSet)
router.register(r'questions', QuestionViewSet)
router.register(r'results', ResultViewSet)
router.register(r'study-materials', StudyMaterialViewSet, basename='studymaterial')
router.register(r'notifications', NotificationViewSet, basename='notification')
router.register(r'profile', UserProfileViewSet, basename='profile')
router.register(r'subjects', SubjectViewSet, basename='subject')
router.register(r'badges', BadgeViewSet, basename='badge')
router.register(r'streak', StreakViewSet, basename='streak')
router.register(r'bookmarks', BookmarkViewSet, basename='bookmark')
router.register(r'reports', QuestionReportViewSet, basename='report')

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include(router.urls)),
    # Custom auth endpoints - must come before rest_framework.urls if included
    path('api/auth/login/', login, name='login'),
    path('api/auth/register/', register, name='register'),
    # JWT endpoints (optional for clients using JWT)
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    # path('api/auth/', include('rest_framework.urls')),  # Commented out - using custom auth
    path('api/analytics/', analytics, name='analytics'),
]
