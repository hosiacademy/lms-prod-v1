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
            valid_from__lte=timezone.now(),
            valid_until__gte=timezone.now()
        ).order_by('priority')
        serializer = LocalizedPromotionSerializer(promotions, many=True)
        return Response(serializer.data)
