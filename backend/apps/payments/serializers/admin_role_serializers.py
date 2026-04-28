from rest_framework import serializers
from ..models import AdminRoleRequest

class AdminRoleRequestSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.ReadOnlyField(source='requested_by.get_full_name')
    processed_by_name = serializers.ReadOnlyField(source='processed_by.get_full_name')
    target_country_name = serializers.ReadOnlyField(source='target_country.name')
    
    class Meta:
        model = AdminRoleRequest
        fields = '__all__'
        read_only_fields = ('requested_by', 'processed_by', 'processed_at', 'created_at', 'updated_at')
