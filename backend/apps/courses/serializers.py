# apps/courses/serializers.py
from rest_framework import serializers
from .models import CourseProvider

class CourseProviderSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseProvider
        fields = ['id', 'code', 'name', 'active']
