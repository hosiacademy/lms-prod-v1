from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
import uuid

class CertificateTemplate(models.Model):
    """Certificate design template"""
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    
    # Template file
    template_file = models.FileField(upload_to='certificate_templates/')
    
    # Customizable fields positions
    config = models.JSONField(default=dict, help_text=_("Position and styling config"))
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'certificate_templates'
        verbose_name = _('Certificate Template')
        verbose_name_plural = _('Certificate Templates')

    def __str__(self):
        return f"{self.name} ({'Active' if self.is_active else 'Inactive'})"

class Certificate(models.Model):
    """Issued certificate"""
    certificate_id = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    verification_code = models.CharField(max_length=50, unique=True)
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='certificates')
    course = models.ForeignKey('courses.Course', on_delete=models.CASCADE, related_name='certificates')
    
    template = models.ForeignKey(CertificateTemplate, on_delete=models.PROTECT)
    
    # Certificate data
    student_name = models.CharField(max_length=255)
    course_name = models.CharField(max_length=255)
    completion_date = models.DateField()
    grade = models.CharField(max_length=10, blank=True, null=True)
    
    # Generated files
    pdf_url = models.URLField()
    thumbnail_url = models.URLField(blank=True, null=True)
    
    issued_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'certificates'
        ordering = ['-issued_at']
        verbose_name = _('Certificate')
        verbose_name_plural = _('Certificates')

    def __str__(self):
        return f"{self.student_name} - {self.course_name}"
