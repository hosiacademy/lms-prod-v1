# apps/courses/views.py
from rest_framework import viewsets, permissions
from .models import CourseProvider
from .serializers import CourseProviderSerializer

class CourseProviderViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that allows course providers to be viewed.
    """
    queryset = CourseProvider.objects.filter(active=True)
    serializer_class = CourseProviderSerializer
    permission_classes = [permissions.AllowAny]
