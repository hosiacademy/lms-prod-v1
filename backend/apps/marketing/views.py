from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils.decorators import method_decorator
from apps.payments.decorators import require_marketing_admin
from .models import MarketingAsset, SocialShareEvent
from .serializers import MarketingAssetSerializer, SocialShareEventSerializer

class MarketingAssetViewSet(viewsets.ModelViewSet):
    queryset = MarketingAsset.objects.all()
    serializer_class = MarketingAssetSerializer
    permission_classes = [permissions.IsAuthenticated]

    @method_decorator(require_marketing_admin)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)

    @action(detail=True, methods=['post'], url_path='log-share')
    def log_share(self, request, pk=None):
        asset = self.get_object()
        platform = request.data.get('platform')
        referral_link = request.data.get('referral_link')
        
        if not platform:
            return Response({'error': 'Platform is required'}, status=status.HTTP_400_BAD_REQUEST)
            
        share_event = SocialShareEvent.objects.create(
            asset=asset,
            platform=platform,
            shared_by=request.user,
            referral_link=referral_link or ''
        )
        
        # Update aggregate counts
        asset.total_shares += 1
        asset.save(update_fields=['total_shares'])
        
        return Response(SocialShareEventSerializer(share_event).data, status=status.HTTP_201_CREATED)

class SocialShareEventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = SocialShareEvent.objects.all()
    serializer_class = SocialShareEventSerializer
    permission_classes = [permissions.IsAuthenticated]

    @method_decorator(require_marketing_admin)
    def dispatch(self, *args, **kwargs):
        return super().dispatch(*args, **kwargs)
