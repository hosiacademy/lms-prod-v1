from rest_framework import serializers
from .models import Certificate, CertificateTemplate

class CertificateTemplateSerializer(serializers.ModelSerializer):
    """Serializer for certificate templates"""
    class Meta:
        model = CertificateTemplate
        fields = [
            'id', 'name', 'description', 'template_file', 
            'config', 'is_active', 'created_at'
        ]

class CertificateSerializer(serializers.ModelSerializer):
    """Serializer for issued certificates"""
    class Meta:
        model = Certificate
        fields = [
            'id', 'certificate_id', 'verification_code', 'user',
            'course', 'template', 'student_name', 'course_name',
            'completion_date', 'grade', 'pdf_url', 'thumbnail_url',
            'issued_at'
        ]
        read_only_fields = ['certificate_id', 'verification_code', 'issued_at']
