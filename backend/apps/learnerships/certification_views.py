# apps/learnerships/views.py - Certification Track API
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .models import CertificationTrack, CertificationItem
from .certification_serializers import CertificationTrackSerializer

@api_view(['GET'])
@permission_classes([AllowAny])
def list_certification_tracks(request):
    """List all certification tracks with their items"""
    tracks = CertificationTrack.objects.filter(active=True).prefetch_related('certifications')
    serializer = CertificationTrackSerializer(tracks, many=True)
    return Response(serializer.data)
