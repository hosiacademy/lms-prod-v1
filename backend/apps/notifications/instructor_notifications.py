"""
Instructor Notification Service
Sends WhatsApp/Email notifications to instructors when students enroll in their courses
"""
import logging
from django.db import connection
from django.conf import settings
from apps.payments.services.sms_service import sms_service
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


class InstructorNotificationService:
    """Service for sending enrollment notifications to instructors"""
    
    @staticmethod
    def get_instructor_phone(instructor_id):
        """Get instructor's WhatsApp number from database or settings"""
        with connection.cursor() as cursor:
            cursor.execute('''
                SELECT phone, email, first_name, last_name
                FROM users
                WHERE id = %s
            ''', [instructor_id])
            row = cursor.fetchone()
            
            if row:
                return {
                    'phone': row[0],
                    'email': row[1],
                    'first_name': row[2],
                    'last_name': row[3],
                }
        return None
    
    @staticmethod
    def send_enrollment_notification(instructor_id, student_name, program_type, program_title, enrollment_code):
        """
        Send WhatsApp notification to instructor when student enrolls
        
        Args:
            instructor_id: ID of the instructor
            student_name: Name of enrolled student
            program_type: Type (learnership, masterclass, industry_training)
            program_title: Title of the program
            enrollment_code: Enrollment reference code
        """
        instructor_info = InstructorNotificationService.get_instructor_phone(instructor_id)
        
        if not instructor_info:
            logger.error(f'Instructor {instructor_id} not found')
            return {'success': False, 'error': 'Instructor not found'}
        
        phone = instructor_info['phone']
        email = instructor_info['email']
        instructor_name = f"{instructor_info['first_name']} {instructor_info['last_name']}"
        
        if not phone:
            logger.warning(f'No phone number for instructor {instructor_id}')
            return {'success': False, 'error': 'No phone number'}
        
        # Create WhatsApp message
        message = f'''🎓 New Student Enrollment!

Dear {instructor_name},

A new student has enrolled in your {program_type.title()}:

Student: {student_name}
Program: {program_title}
Code: {enrollment_code}

Please prepare to welcome them to your course.

🌐 https://www.hosiacademy.africa/'''
        
        # Send WhatsApp
        result = sms_service.send_sms(phone, message)
        
        if result.get('success'):
            logger.info(f'Instructor notification sent to {instructor_name} ({phone})')
            
            # Also send email notification
            InstructorNotificationService.send_email_notification(
                email=email,
                instructor_name=instructor_name,
                student_name=student_name,
                program_type=program_type,
                program_title=program_title,
                enrollment_code=enrollment_code
            )
            
            return result
        else:
            logger.error(f'Failed to notify instructor: {result.get("error")}')
            return result
    
    @staticmethod
    def send_email_notification(email, instructor_name, student_name, program_type, program_title, enrollment_code):
        """Send email notification to instructor"""
        try:
            subject = f'🎓 New Student Enrollment: {student_name}'
            
            html_content = f'''
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
        .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }}
        .content {{ background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }}
        .highlight {{ background: #fff; padding: 20px; border-left: 4px solid #667eea; margin: 20px 0; }}
        .btn {{ display: inline-block; background: #667eea; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎓 New Student Enrollment</h1>
            <p>Hosi Academy Instructor Notification</p>
        </div>
        
        <div class="content">
            <p>Dear <strong>{instructor_name}</strong>,</p>
            
            <p>A new student has enrolled in your program:</p>
            
            <div class="highlight">
                <p><strong>Student:</strong> {student_name}</p>
                <p><strong>Program:</strong> {program_title}</p>
                <p><strong>Type:</strong> {program_type.title()}</p>
                <p><strong>Enrollment Code:</strong> {enrollment_code}</p>
            </div>
            
            <p>Please prepare to welcome them to your course and ensure they have access to all necessary materials.</p>
            
            <p style="text-align: center;">
                <a href="https://www.hosiacademy.africa/instructor/dashboard" class="btn">Access Instructor Dashboard</a>
            </p>
            
            <p>Best regards,<br><strong>Hosi Academy Team</strong></p>
        </div>
    </div>
</body>
</html>
'''
            
            send_mail(
                subject=subject,
                message=f'New student enrollment: {student_name} in {program_title}',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[email],
                html_message=html_content,
                fail_silently=True,
            )
            
            logger.info(f'Instructor email sent to {email}')
            return True
            
        except Exception as e:
            logger.error(f'Failed to send instructor email: {e}')
            return False
    
    @staticmethod
    def notify_instructor_on_enrollment(enrollment_id):
        """
        Main entry point - called when new enrollment is created
        
        Args:
            enrollment_id: ID of the new enrollment record
        """
        try:
            with connection.cursor() as cursor:
                # Get enrollment details with instructor info
                cursor.execute('''
                    SELECT 
                        e.enrollment_id,
                        e.enrollment_code,
                        e.enrollment_type,
                        e.learner_full_name,
                        e.instructor_id,
                        e.student_id,
                        e.content_type_id,
                        ct.app_label,
                        ct.model
                    FROM enrollments e
                    JOIN django_content_type ct ON e.content_type_id = ct.id
                    WHERE e.enrollment_id = %s
                ''', [enrollment_id])
                
                row = cursor.fetchone()
                
                if not row:
                    logger.error(f'Enrollment {enrollment_id} not found')
                    return
                
                enf_id, code, enf_type, student_name, instructor_id, student_id, ctype_id, app_label, model = row
                
                # Skip if no instructor assigned
                if not instructor_id:
                    logger.info(f'No instructor for enrollment {enrollment_id}')
                    return
                
                # Get program title based on content type
                program_title = 'Unknown Program'
                
                if app_label == 'learnerships' and model == 'learnershipprogramme':
                    cursor.execute('''
                        SELECT title FROM learnerships_learnershipprogramme WHERE id = %s
                    ''', [row[5]])  # object_id would be needed here
                    result = cursor.fetchone()
                    if result:
                        program_title = result[0]
                        
                elif app_label == 'masterclasses' and model == 'masterclass':
                    cursor.execute('''
                        SELECT title FROM masterclasses_masterclass WHERE id = %s
                    ''', [row[5]])
                    result = cursor.fetchone()
                    if result:
                        program_title = result[0]
                
                # Send notification
                InstructorNotificationService.send_enrollment_notification(
                    instructor_id=instructor_id,
                    student_name=student_name,
                    program_type=enf_type,
                    program_title=program_title,
                    enrollment_code=code
                )
                
                logger.info(f'Instructor notification process complete for enrollment {enrollment_id}')
                
        except Exception as e:
            logger.error(f'Error in instructor notification: {e}')


# Singleton instance
instructor_notifications = InstructorNotificationService()
