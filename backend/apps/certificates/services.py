from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter, landscape
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from django.core.files.storage import default_storage
from django.conf import settings
from django.utils import timezone
import qrcode
import secrets
import os
from io import BytesIO
from PIL import Image
from .models import Certificate, CertificateTemplate

class CertificateGenerator:
    """Generate PDF certificates"""
    
    def __init__(self):
        # Register custom fonts (if available) - otherwise fallback to Helvetica
        try:
            # You should place these fonts in backend/assets/fonts/
            font_dir = os.path.join(settings.BASE_DIR, 'assets', 'fonts')
            if os.path.exists(os.path.join(font_dir, 'Roboto-Regular.ttf')):
                pdfmetrics.registerFont(TTFont('Roboto', os.path.join(font_dir, 'Roboto-Regular.ttf')))
                pdfmetrics.registerFont(TTFont('Roboto-Bold', os.path.join(font_dir, 'Roboto-Bold.ttf')))
                self.font_main = 'Roboto'
                self.font_bold = 'Roboto-Bold'
            else:
                self.font_main = 'Helvetica'
                self.font_bold = 'Helvetica-Bold'
        except Exception:
            self.font_main = 'Helvetica'
            self.font_bold = 'Helvetica-Bold'
    
    def generate(self, enrollment):
        """Generate certificate for enrollment"""
        # Get template
        template = CertificateTemplate.objects.filter(is_active=True).first()
        if not template:
            # Create a default template object if none exists for safety
            template, _ = CertificateTemplate.objects.get_or_create(
                name="Default Template",
                defaults={'is_active': True}
            )
        
        # Generate verification code
        verification_code = secrets.token_urlsafe(16)
        
        # Create certificate record
        certificate = Certificate.objects.create(
            user=enrollment.user,
            course=enrollment.course,
            template=template,
            student_name=enrollment.user.get_full_name() or enrollment.user.username,
            course_name=enrollment.course.title,
            completion_date=timezone.now().date(), # Fallback if enrollment has no completion date
            verification_code=verification_code,
            pdf_url='',  # Will update after generation
        )
        
        # Generate PDF
        pdf_buffer = BytesIO()
        c = canvas.Canvas(pdf_buffer, pagesize=landscape(letter))
        
        # Draw template background
        if template.template_file and os.path.exists(template.template_file.path):
            template_image = ImageReader(template.template_file.path)
            c.drawImage(template_image, 0, 0, width=792, height=612)
        else:
            # Draw placeholder border
            c.setStrokeColorRGB(0.1, 0.1, 0.4)
            c.rect(20, 20, 752, 572, stroke=1, fill=0)
        
        # Draw Title
        c.setFont(self.font_bold, 36)
        c.drawCentredString(396, 500, "CERTIFICATE OF COMPLETION")
        
        # Draw student name
        c.setFont(self.font_bold, 48)
        c.drawCentredString(396, 350, certificate.student_name)
        
        # Draw course name
        c.setFont(self.font_main, 24)
        c.drawCentredString(396, 280, f'has successfully completed')
        
        c.setFont(self.font_bold, 32)
        c.drawCentredString(396, 240, certificate.course_name)
        
        # Draw date
        c.setFont(self.font_main, 18)
        completion_date_str = certificate.completion_date.strftime("%B %d, %Y")
        c.drawCentredString(396, 180, f'Completed on {completion_date_str}')
        
        # Generate and draw QR code for verification
        qr_url = f"https://hosiacademy.com/verify/{verification_code}"
        qr = qrcode.QRCode(version=1, box_size=10, border=2)
        qr.add_data(qr_url)
        qr.make(fit=True)
        qr_img = qr.make_image(fill_color="black", back_color="white")
        
        qr_buffer = BytesIO()
        qr_img.save(qr_buffer, format='PNG')
        qr_buffer.seek(0)
        
        c.drawImage(ImageReader(qr_buffer), 650, 50, width=100, height=100)
        
        c.save()
        
        # Upload to Storage
        pdf_buffer.seek(0)
        file_path = f'certificates/{certificate.certificate_id}.pdf'
        saved_path = default_storage.save(file_path, pdf_buffer)
        
        certificate.pdf_url = default_storage.url(saved_path)
        certificate.save()
        
        return certificate
    
    def verify(self, verification_code):
        """Verify certificate authenticity"""
        try:
            certificate = Certificate.objects.get(verification_code=verification_code)
            return {
                'valid': True,
                'student_name': certificate.student_name,
                'course_name': certificate.course_name,
                'completion_date': certificate.completion_date,
                'issued_at': certificate.issued_at,
            }
        except Certificate.DoesNotExist:
            return {'valid': False}
