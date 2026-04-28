from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from .models import AiCertsCourse
from .serializers import AiCertsCourseSerializer, AiCertsCourseListSerializer

class AiCertsCourseViewSet(viewsets.ModelViewSet):
    """API endpoint for AICerts courses"""
    queryset = AiCertsCourse.objects.all()
    serializer_class = AiCertsCourseSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['provider', 'is_offered', 'is_self_paced', 'is_in_package']
    search_fields = ['fullname', 'shortname', 'summary', 'category_name']
    ordering_fields = ['last_synced', 'fullname', 'price_individual']
    ordering = ['-last_synced']
    
    def get_serializer_class(self):
        """Use different serializers for list vs detail"""
        if self.action == 'list':
            return AiCertsCourseListSerializer
        return AiCertsCourseSerializer
