from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import serializers
from apps.localization.models import LocalizedPromotion

class LocalizedPromotionSerializer(serializers.ModelSerializer):
    class Meta:
        model = LocalizedPromotion
        fields = '__all__'

class PublicPromotionListView(APIView):
    """Get active promotions for public display"""
    def get(self, request):
        promotions = LocalizedPromotion.objects.filter(
            is_active=True,
            start_date__lte=timezone.now().date(),
            end_date__gte=timezone.now().date()
        ).order_by('priority')
        serializer = LocalizedPromotionSerializer(promotions, many=True)
        return Response(serializer.data)
