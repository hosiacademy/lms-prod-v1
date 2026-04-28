from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import Certificate
from .serializers import CertificateSerializer
from .services import CertificateGenerator

class CertificateViewSet(viewsets.ReadOnlyModelViewSet):
    """API for viewing and downloading certificates"""
    serializer_class = CertificateSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Certificate.objects.filter(user=self.request.user)
    
    @action(detail=True, methods=['get'])
    def download(self, request, pk=None):
        """Get certificate download URL and metadata"""
        certificate = self.get_object()
        return Response({
            'pdf_url': certificate.pdf_url,
            'filename': f'certificate_{certificate.certificate_id}.pdf',
            'course_name': certificate.course_name,
            'completion_date': certificate.completion_date
        })

@api_view(['GET'])
@permission_classes([AllowAny])
def verify_certificate(request, verification_code):
    """Publicly verify a certificate's authenticity"""
    generator = CertificateGenerator()
    result = generator.verify(verification_code)
    
    if result.get('valid'):
        return Response(result)
    return Response({'valid': False}, status=status.HTTP_404_NOT_FOUND)
