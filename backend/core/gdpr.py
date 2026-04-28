"""
GDPR Compliance utilities for LMS platform.
Handles data export, deletion, and consent management.
"""
import json
import logging
from datetime import datetime
from django.http import JsonResponse, HttpResponse
from django.contrib.auth import get_user_model

logger = logging.getLogger(__name__)
User = get_user_model()


class GDPRDataExporter:
    """
    Export all user data in machine-readable format (GDPR Right to Data Portability).
    """

    def __init__(self, user):
        self.user = user

    def export_all_data(self):
        """Export all user data."""
        data = {
            'export_date': datetime.utcnow().isoformat(),
            'user_id': self.user.id,
            'personal_information': self.export_personal_info(),
            'enrollments': self.export_enrollments(),
            'payments': self.export_payments(),
            'progress': self.export_progress(),
            'messages': self.export_messages(),
            'notifications': self.export_notifications(),
        }
        return data

    def export_personal_info(self):
        """Export personal information."""
        return {
            'email': self.user.email,
            'first_name': self.user.first_name,
            'last_name': self.user.last_name,
            'date_joined': self.user.date_joined.isoformat() if hasattr(self.user, 'date_joined') else None,
            'last_login': self.user.last_login.isoformat() if self.user.last_login else None,
            'is_active': self.user.is_active,
        }

    def export_enrollments(self):
        """Export enrollment data."""
        # Implement based on your enrollment model
        return []

    def export_payments(self):
        """Export payment history."""
        # Implement based on your payment model
        return []

    def export_progress(self):
        """Export learning progress."""
        # Implement based on your analytics model
        return []

    def export_messages(self):
        """Export messages/communications."""
        # Implement based on your communication model
        return []

    def export_notifications(self):
        """Export notifications."""
        # Implement based on your notification model
        return []

    def export_as_json(self):
        """Export as JSON file."""
        data = self.export_all_data()
        return json.dumps(data, indent=2, default=str)


class GDPRDataEraser:
    """
    Handle user data deletion (GDPR Right to Erasure/"Right to be Forgotten").
    """

    def __init__(self, user):
        self.user = user

    def anonymize_user(self):
        """
        Anonymize user data instead of complete deletion.
        Preserves data integrity for financial/legal records.
        """
        logger.info(f'Anonymizing user data for user {self.user.id}')

        # Anonymize personal information
        self.user.email = f'deleted_user_{self.user.id}@anonymized.local'
        self.user.first_name = 'Deleted'
        self.user.last_name = 'User'
        self.user.is_active = False
        self.user.save()

        # Delete profile picture/avatar if exists
        if hasattr(self.user, 'profile') and self.user.profile.avatar:
            self.user.profile.avatar.delete()

        logger.info(f'User {self.user.id} anonymized successfully')

    def delete_user_data(self, preserve_financial_records=True):
        """
        Delete user data completely.

        Args:
            preserve_financial_records: If True, keep payment records for legal compliance
        """
        logger.info(f'Deleting data for user {self.user.id}')

        if preserve_financial_records:
            # Anonymize instead of delete
            self.anonymize_user()
        else:
            # Complete deletion (use with caution)
            self.user.delete()

        logger.info(f'User {self.user.id} data deletion completed')


class AuditLogger:
    """
    Audit logging for compliance and security.
    Tracks important actions for accountability.
    """

    @staticmethod
    def log_action(user, action, resource_type, resource_id, details=None, ip_address=None):
        """
        Log an auditable action.

        Args:
            user: User who performed the action
            action: Action type (create, read, update, delete, export, etc.)
            resource_type: Type of resource (payment, enrollment, user_data, etc.)
            resource_id: ID of the resource
            details: Additional details (dict)
            ip_address: IP address of the request
        """
        audit_entry = {
            'timestamp': datetime.utcnow().isoformat(),
            'user_id': user.id if user else None,
            'user_email': user.email if user else None,
            'action': action,
            'resource_type': resource_type,
            'resource_id': resource_id,
            'details': details or {},
            'ip_address': ip_address,
        }

        # Log to file
        logger.info(f'AUDIT: {json.dumps(audit_entry)}', extra={'audit': True})

        # TODO: Also store in database for querying
        # AuditLog.objects.create(**audit_entry)

        return audit_entry

    @staticmethod
    def log_payment_transaction(user, transaction_id, amount, currency, provider, status, ip_address=None):
        """Log payment transaction for audit."""
        return AuditLogger.log_action(
            user=user,
            action='payment_transaction',
            resource_type='payment',
            resource_id=transaction_id,
            details={
                'amount': str(amount),
                'currency': currency,
                'provider': provider,
                'status': status,
            },
            ip_address=ip_address
        )

    @staticmethod
    def log_data_export(user, ip_address=None):
        """Log GDPR data export request."""
        return AuditLogger.log_action(
            user=user,
            action='data_export',
            resource_type='user_data',
            resource_id=user.id,
            details={'reason': 'GDPR data portability request'},
            ip_address=ip_address
        )

    @staticmethod
    def log_data_deletion(user, ip_address=None):
        """Log GDPR data deletion request."""
        return AuditLogger.log_action(
            user=user,
            action='data_deletion',
            resource_type='user_data',
            resource_id=user.id,
            details={'reason': 'GDPR right to erasure'},
            ip_address=ip_address
        )

    @staticmethod
    def log_admin_access(admin_user, accessed_user, action, ip_address=None):
        """Log when admin accesses user data."""
        return AuditLogger.log_action(
            user=admin_user,
            action=f'admin_{action}',
            resource_type='user',
            resource_id=accessed_user.id,
            details={'accessed_user_email': accessed_user.email},
            ip_address=ip_address
        )
