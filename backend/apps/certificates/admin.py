from django.contrib import admin
from .models import Certificate, CertificateTemplate

@admin.register(CertificateTemplate)
class CertificateTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name', 'description')

@admin.register(Certificate)
class CertificateAdmin(admin.ModelAdmin):
    list_display = ('student_name', 'course_name', 'completion_date', 'issued_at', 'verification_code')
    list_filter = ('course', 'issued_at')
    search_fields = ('student_name', 'course_name', 'verification_code')
    raw_id_fields = ('user', 'course', 'template')
    readonly_fields = ('certificate_id', 'verification_code', 'issued_at')
