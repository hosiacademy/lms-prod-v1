import os
import django
import sys
from decimal import Decimal
from django.utils import timezone

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "lms_project.settings")
django.setup()

from apps.payments.quotation_models import ClientQuotation, QuotationStatus, TrainingType
from apps.users.models import User
from apps.payments.views.quotation_views import SendQuotationEmailView

def main():
    admin = User.objects.filter(is_superuser=True).first()
    
    from datetime import timedelta
    now = timezone.now()
    quotation = ClientQuotation(
        client_name="Hosi Tech Operations",
        client_email="hosimonorepo@gmail.com",
        client_company="Hosi Tech",
        training_type=TrainingType.COURSE,
        course_name="Software Engineering & AI Bootcamp",
        base_price=Decimal("1500.00"),
        quantity=2,
        discount_percentage=Decimal("0.00"),
        validity_days=30,
        created_by=admin,
        created_at=now,
        expires_at=now + timedelta(days=30)
    )
    
    quotation.save()  # Calculates subtotal, total, and local amounts
    
    print(f"Created Quotation: {quotation.quotation_number}")
    print(f"Total Amount: USD {quotation.total_amount}")
    
    from django.core.mail import send_mail
    from django.conf import settings
    
    plain_message = f"""
Dear {quotation.client_name},

Thank you for your interest in {quotation.training_item_name}.

Quotation Details:
- Quotation Number: {quotation.quotation_number}
- Training: {quotation.training_item_name}
- Total Amount: USD {quotation.total_amount}

This quotation is valid until {quotation.expires_at.strftime('%B %d, %Y')}.

Best regards,
Hosi Academy Team
"""
    try:
        send_mail(
            subject=f"Quotation {quotation.quotation_number} - {quotation.training_item_name}",
            message=plain_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[quotation.client_email],
            fail_silently=False,
        )
        quotation.email_sent = True
        quotation.email_sent_at = timezone.now()
        quotation.status = QuotationStatus.SENT
        quotation.save()
        print("Email sent successfully to hosimonorepo@gmail.com!")
    except Exception as e:
        print(f"Failed to send email: {e}")

if __name__ == "__main__":
    main()
