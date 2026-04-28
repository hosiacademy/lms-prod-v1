import re
with open("backend/apps/enrollments/tasks.py", "r") as f:
    content = f.read()

replacement = """
        if enrollment.status == 'cash_pending':
            subject = f"Welcome to Hosi Academy - Payment Reference: {enrollment.reference_code}"
            message = f'''
Dear {enrollment.user.get_full_name() or enrollment.user.email},

Welcome to Hosi Academy! Thank you for your enrollment in {enrollment.get_enrollment_type_display()}.

To complete your enrollment, please visit one of our offices to make your payment.
You now have access to our Hosi Academy Chat group, your Specific Training chat group, and direct access to chat with your Instructors.

Reference Code: {enrollment.reference_code}
Amount: {enrollment.payment_transaction.amount if enrollment.payment_transaction else 'TBD'} {enrollment.payment_transaction.currency if enrollment.payment_transaction else 'USD'}
Expires: {enrollment.expires_at.strftime('%Y-%m-%d')}

Office Details:
- Visit our website for office locations
- Email: payments@hosiacademy.com
- Phone: Contact your regional office

Best regards,
Hosi Academy Team
'''
        else:  # provisional for learnership
            subject = "Welcome to Hosi Academy - Enrollment Pending Verification"
            message = f'''
Dear {enrollment.user.get_full_name() or enrollment.user.email},

Welcome to Hosi Academy! Thank you for your payment for the {enrollment.get_enrollment_type_display()} program.

Your enrollment is currently being reviewed to verify that you meet all prerequisites.
You now have access to our Hosi Academy Chat group, your Specific Training chat group, and direct access to chat with your Instructors.

Status: Pending Verification
Review Period: 7 days
Reference: {enrollment.reference_code or 'N/A'}

We will notify you within 7 days with the verification result.

Best regards,
Hosi Academy Team
'''

        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [enrollment.user.email],
            fail_silently=True,
        )

        # Send SMS Welcome
        try:
            from apps.communication.sms_service import SMSService
            if enrollment.user.phone:
                sms_message = "Welcome to Hosi Academy! Check your email for enrollment details and access to our Chat groups to chat with your Instructors."
                SMSService.send_sms(enrollment.user.phone, sms_message)
        except Exception as e:
            logger.error(f"Failed to send SMS to {enrollment.user.phone}: {e}")

        # Auto-generate chat messages
        try:
            from apps.communication.models import ChatMessage, ChatRoom
            from apps.users.models import User
            # Logic to find instructor and send messages...
            instructor = None
            if enrollment.programme and enrollment.programme.instructor:
                instructor = enrollment.programme.instructor
            
            if instructor:
                # Welcome msg from instructor in 1-on-1
                # Message to instructor that student joined
                pass # Specific logic implementation depends on models
        except Exception as e:
            logger.error(f"Failed to generate chat messages: {e}")

"""

# Let's replace the if statement block
start_idx = content.find("        if enrollment.status == 'cash_pending':")
end_idx = content.find("        logger.info(f\"Sent provisional enrollment email")

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + replacement + content[end_idx:]
    with open("backend/apps/enrollments/tasks.py", "w") as f:
        f.write(new_content)
    print("Patched tasks.py")
else:
    print("Could not find patch bounds")
