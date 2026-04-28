from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    LearnershipProgrammeViewSet,
    LearnershipEnrollmentViewSet,
    create_corporate_enrollment,
    CybersecurityLearnershipListView,
    AIBlockchainLearnershipListView,
)
from .certification_views import list_certification_tracks

router = DefaultRouter()
router.register(r'programmes', LearnershipProgrammeViewSet, basename='learnership-programme')
router.register(r'enrollments', LearnershipEnrollmentViewSet, basename='learnership-enrollment')

urlpatterns = [
    # Dedicated category endpoints (must come before router to avoid prefix conflict)
    path('programmes/cybersecurity/', CybersecurityLearnershipListView.as_view(), name='learnerships-cybersecurity'),
    path('programmes/ai-blockchain/', AIBlockchainLearnershipListView.as_view(), name='learnerships-ai-blockchain'),
    path('', include(router.urls)),
    path(
        'enrollments/corporate/',
        create_corporate_enrollment,
        name='create_corporate_enrollment'
    ),
    path('certification-tracks/', list_certification_tracks, name='list_certification_tracks'),
]
