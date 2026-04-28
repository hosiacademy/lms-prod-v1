import re

with open("backend/apps/payments/tasks.py", "r") as f:
    content = f.read()

# Update email message
email_patch = """        subject = "Welcome to Hosi Academy - Payment Confirmation"
        message = f'''
Dear {transaction.user.first_name or transaction.user.username},

Welcome to Hosi Academy! Your payment of {transaction.amount} {transaction.currency} has been confirmed.

You now have access to our Hosi Academy Chat group, your Specific Training chat group, and direct access to chat with your Instructors.

Transaction Details:
- Amount: {transaction.amount} {transaction.currency}
- Reference: {transaction.provider_reference}
- Date: {transaction.completed_at or timezone.now()}
- Description: {transaction.description or 'Course Payment'}

Thank you for your purchase!

If you have any questions, please contact our support team.

Best regards,
Hosi Academy Team
'''"""

content = re.sub(
    r'        subject = "Payment Confirmation - Hosi Academy".*?        message = f"""\n.*?\n        """',
    email_patch,
    content,
    flags=re.DOTALL
)

# Check if ChatEnforcerService is called in send_payment_confirmation_email
chat_trigger = """
        # Auto-generate chat messages
        try:
            from apps.enrollments.models import Enrollment
            enrollment = Enrollment.objects.filter(payment_transaction=transaction).first()
            if enrollment:
                from apps.communication.services import ChatEnforcerService
                ChatEnforcerService.enforce_enrollment_chats(enrollment)
        except Exception as e:
            logger.error(f"Failed to generate chat messages: {e}")
            
        # Send email
"""

content = content.replace("        # Send email", chat_trigger)

with open("backend/apps/payments/tasks.py", "w") as f:
    f.write(content)

print("Patched tasks.py (payments)")

with open("backend/apps/payments/services/sms_service.py", "r") as f:
    sms_content = f.read()

sms_patch = """        return f"Welcome to Hosi Academy! Payment of {amount_str} confirmed. Ref: {reference}. Check your email to access our Chat groups to chat with your Instructors." """

sms_content = re.sub(
    r'        return f"Payment of \{amount_str\} confirmed.*?Reference: \{reference\}."',
    sms_patch,
    sms_content
)

with open("backend/apps/payments/services/sms_service.py", "w") as f:
    f.write(sms_content)

print("Patched sms_service.py")
