from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils.decorators import method_decorator
from apps.payments.decorators import require_marketing_admin
from apps.payments.models_admin import Administrator, SalesMarketingCountryAssignment
from .models import MarketingAsset, SocialShareEvent, MarketingLead
from apps.learner_portal.models import Wishlist
from .serializers import MarketingAssetSerializer, SocialShareEventSerializer, MarketingLeadSerializer, WishlistItemSerializer

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

class MarketingLeadViewSet(viewsets.ModelViewSet):
    queryset = MarketingLead.objects.all()
    serializer_class = MarketingLeadSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return MarketingLead.objects.all()
            
        # Check if user is a marketing admin
        admin_profile = Administrator.objects.filter(user=user, is_active=True).first()
        if admin_profile and (admin_profile.admin_type == 'marketing' or admin_profile.is_marketing_admin):
            # For now, let admins see all leads
            return MarketingLead.objects.all()
        
        return MarketingLead.objects.filter(user=user)

class WishlistViewSet(viewsets.ModelViewSet):
    serializer_class = WishlistItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Automatically assign country based on user's country if not provided
        country = self.request.data.get('country')
        if not country and self.request.user.country:
            serializer.save(user=self.request.user, country=self.request.user.country)
        else:
            serializer.save(user=self.request.user)

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Wishlist.objects.all()

        # Check if user is a marketing admin
        admin_profile = Administrator.objects.filter(user=user, is_active=True).first()
        if admin_profile and (admin_profile.admin_type == 'marketing' or admin_profile.is_marketing_admin):
            # Get assigned countries
            assigned_countries = SalesMarketingCountryAssignment.objects.filter(
                sales_marketing_admin=admin_profile, 
                is_active=True
            ).values_list('country', flat=True)
            
            if assigned_countries:
                # Filter wishlists by assigned countries
                return Wishlist.objects.filter(country__id__in=assigned_countries)
            
            return Wishlist.objects.none()

        # Regular users only see their own wishlist
        return Wishlist.objects.filter(user=user)
