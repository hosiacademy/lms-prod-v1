from rest_framework import serializers
from .models import MarketingAsset, SocialShareEvent, MarketingLead
from apps.learner_portal.models import Wishlist

class MarketingAssetSerializer(serializers.ModelSerializer):
    file_url = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    share_count = serializers.IntegerField(source='share_events.count', read_only=True)

    class Meta:
        model = MarketingAsset
        fields = [
            'id', 'title', 'description', 'asset_type', 
            'file', 'file_url', 'thumbnail', 'thumbnail_url', 
            'suggested_caption', 'total_clicks', 'total_shares', 
            'share_count', 'created_at', 'updated_at'
        ]
        read_only_fields = ['total_clicks', 'total_shares', 'created_at', 'updated_at']

    def get_file_url(self, obj):
        request = self.context.get('request')
        if obj.file and request:
            return request.build_absolute_uri(obj.file.url)
        return obj.file.url if obj.file else None

    def get_thumbnail_url(self, obj):
        request = self.context.get('request')
        if obj.thumbnail and request:
            return request.build_absolute_uri(obj.thumbnail.url)
        return obj.thumbnail.url if obj.thumbnail else None

class SocialShareEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = SocialShareEvent
        fields = '__all__'
        read_only_fields = ['shared_at', 'clicks']

class MarketingLeadSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    
    class Meta:
        model = MarketingLead
        fields = [
            'id', 'user', 'user_email', 'training_type', 'object_id', 
            'title', 'goals', 'professional_status', 'planned_start', 
            'expectations', 'created_at', 'status'
        ]
        read_only_fields = ['user', 'created_at']

class WishlistItemSerializer(serializers.ModelSerializer):
    user_email = serializers.EmailField(source='user.email', read_only=True)
    country_name = serializers.CharField(source='country.name', read_only=True)
    
    class Meta:
        model = Wishlist
        fields = [
            'id', 'user', 'user_email', 'training_type', 'object_id', 
            'title', 'country', 'country_name', 'created_at',
            'interest_level', 'intended_start', 'notes'
        ]
        read_only_fields = ['user', 'created_at']
