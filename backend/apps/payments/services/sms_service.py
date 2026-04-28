"""
SMS/WhatsApp Service for Payment Notifications
Uses Twilio WhatsApp API with Content Templates for delivery
"""
import logging
import json
from typing import Dict, Optional
from django.conf import settings
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException

logger = logging.getLogger(__name__)


class TwilioSMSService:
    """Twilio WhatsApp service for payment and enrollment notifications"""

    def __init__(self):
        """Initialize Twilio client"""
        self.account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', None)
        self.auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', None)
        self.from_number = getattr(settings, 'TWILIO_WHATSAPP_NUMBER', None) or getattr(settings, 'TWILIO_PHONE_NUMBER', None)
        self.content_sid = getattr(settings, 'TWILIO_CONTENT_SID', None)

        if self.account_sid and self.auth_token:
            try:
                self.client = Client(self.account_sid, self.auth_token)
                self.enabled = True
                logger.info(f"Twilio WhatsApp initialized for {self.from_number}")
            except Exception as e:
                logger.error(f"Failed to initialize Twilio client: {str(e)}")
                self.enabled = False
        else:
            self.enabled = False
            logger.warning("Twilio credentials not configured - WhatsApp disabled")

    def send_whatsapp_template(self, to_number: str, content_sid: str = None, content_variables: Dict = None, body: str = None) -> Dict:
        """
        Send WhatsApp message using Twilio Content Template

        Args:
            to_number: Recipient phone number (E.164 format: +27123456789)
            content_sid: Twilio Content SID (e.g., HXb5b62575e6e4ff6129ad7c8efe1f983e)
            content_variables: Dict with template variables (e.g., {"1":"12/1","2":"3pm"})
            body: Optional plain text body (if not using template)

        Returns:
            dict: {'success': bool, 'message_sid': str, 'error': str}
        """
        if not self.enabled:
            logger.warning("WhatsApp service disabled - skipping message")
            return {
                'success': False,
                'error': 'WhatsApp service not configured',
                'message_sid': None
            }

        if not to_number:
            return {
                'success': False,
                'error': 'No phone number provided',
                'message_sid': None
            }

        # Ensure phone number is in E.164 format
        if not to_number.startswith('+'):
            logger.warning(f"Phone number {to_number} missing country code")
            return {
                'success': False,
                'error': 'Phone number must include country code (e.g., +27)',
                'message_sid': None
            }

        try:
            # Format numbers for WhatsApp
            to_whatsapp = f"whatsapp:{to_number}"
            from_whatsapp = self.from_number
            if not from_whatsapp.startswith('whatsapp:'):
                from_whatsapp = f"whatsapp:{from_whatsapp}"

            # Build message parameters
            message_params = {
                'from_': from_whatsapp,
                'to': to_whatsapp,
            }

            # Use content template if provided
            use_content_sid = content_sid or self.content_sid
            if use_content_sid:
                message_params['content_sid'] = use_content_sid
                if content_variables:
                    message_params['content_variables'] = json.dumps(content_variables)
            
            # Add body if provided (fallback or plain text)
            if body:
                message_params['body'] = body

            # Send WhatsApp message
            message_obj = self.client.messages.create(**message_params)

            logger.info(
                f"WhatsApp sent successfully to {to_number}",
                extra={
                    'message_sid': message_obj.sid,
                    'content_sid': use_content_sid,
                    'to_number': to_number,
                    'status': message_obj.status
                }
            )

            return {
                'success': True,
                'message_sid': message_obj.sid,
                'status': message_obj.status,
                'error': None
            }

        except TwilioRestException as e:
            logger.error(
                f"Twilio WhatsApp error to {to_number}: {str(e)}",
                extra={
                    'error_code': e.code,
                    'error_message': e.msg,
                    'to_number': to_number
                }
            )
            return {
                'success': False,
                'error': f"WhatsApp error: {e.msg}",
                'message_sid': None
            }

        except Exception as e:
            logger.error(f"Unexpected error sending WhatsApp: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'message_sid': None
            }

    def send_sms(self, to_number: str, message: str) -> Dict:
        """
        Send WhatsApp message (alias for send_whatsapp_template with plain body)
        Maintains backward compatibility with existing code
        Always includes the Hosi Academy app link

        Args:
            to_number: Recipient phone number (E.164 format: +27123456789)
            message: WhatsApp message content (plain text)

        Returns:
            dict: {'success': bool, 'message_sid': str, 'error': str}
        """
        # Append app link to message
        app_link = "\n\n🌐 Access your dashboard: https://www.hosiacademy.africa/"
        full_message = message + app_link
        
        # Send as plain WhatsApp message with body
        return self.send_whatsapp_template(to_number=to_number, body=full_message)

    def send_payment_success_whatsapp(self, to_number: str, amount: float, currency: str, reference: str, description: str = None) -> Dict:
        """
        Send payment success WhatsApp using content template

        Template variables:
        1: Reference/Date
        2: Amount
        """
        content_vars = {
            "1": reference,
            "2": f"{currency} {amount:,.2f}"
        }
        
        if description:
            content_vars["3"] = description[:20]

        return self.send_whatsapp_template(
            to_number=to_number,
            content_variables=content_vars
        )

    def send_enrollment_whatsapp(self, to_number: str, student_name: str, program_name: str, enrollment_code: str) -> Dict:
        """
        Send enrollment confirmation WhatsApp using content template

        Template variables:
        1: Student name
        2: Program name
        3: Enrollment code
        """
        content_vars = {
            "1": student_name,
            "2": program_name,
            "3": enrollment_code
        }

        return self.send_whatsapp_template(
            to_number=to_number,
            content_variables=content_vars
        )


class SMSTemplateService:
    """Generate SMS message templates for payments"""

    @staticmethod
    def payment_success(
        amount: float,
        currency: str,
        reference: str,
        description: Optional[str] = None
    ) -> str:
        """
        Generate payment success SMS message

        Args:
            amount: Payment amount
            currency: Currency code (ZAR, USD, etc.)
            reference: Transaction reference number
            description: Optional payment description

        Returns:
            str: Formatted SMS message (max 160 chars for standard SMS)
        """
        # Get currency symbol
        currency_symbols = {
            'ZAR': 'R',
            'USD': '$',
            'EUR': '€',
            'GBP': '£',
            'NGN': '₦',
            'KES': 'KSh',
            'GHS': 'GH₵',
            'ZMW': 'ZK',
            'ZWL': 'Z$',
            'UGX': 'USh',
        }
        symbol = currency_symbols.get(currency, currency)

        # Format amount with currency
        amount_str = f"{symbol}{amount:,.2f}"

        # Build message (keep under 160 chars for single SMS)
        if description:
            message = (
                f"✅ Payment Confirmed!\n"
                f"Amount: {amount_str}\n"
                f"Course: {description[:30]}\n"
                f"Ref: {reference[:15]}\n"
                f"- Hosi Academy"
            )
        else:
            message = (
                f"✅ Payment Confirmed!\n"
                f"Amount: {amount_str}\n"
                f"Reference: {reference}\n"
                f"Thank you!\n"
                f"- Hosi Academy"
            )

        return message

    @staticmethod
    def payment_failed(
        amount: float,
        currency: str,
        reason: Optional[str] = None
    ) -> str:
        """Generate payment failure SMS"""
        currency_symbols = {
            'ZAR': 'R',
            'USD': '$',
            'NGN': '₦',
            'KES': 'KSh',
        }
        symbol = currency_symbols.get(currency, currency)
        amount_str = f"{symbol}{amount:,.2f}"

        if reason:
            message = (
                f"❌ Payment Failed\n"
                f"Amount: {amount_str}\n"
                f"Reason: {reason[:40]}\n"
                f"Please try again\n"
                f"- Hosi Academy"
            )
        else:
            message = (
                f"❌ Payment Failed\n"
                f"Amount: {amount_str}\n"
                f"Please try again or contact support\n"
                f"- Hosi Academy"
            )

        return message

    @staticmethod
    def payment_pending(amount: float, currency: str, reference: str) -> str:
        """Generate payment pending SMS"""
        currency_symbols = {'ZAR': 'R', 'USD': '$', 'NGN': '₦', 'KES': 'KSh'}
        symbol = currency_symbols.get(currency, currency)
        amount_str = f"{symbol}{amount:,.2f}"

        message = (
            f"⏳ Payment Processing\n"
            f"Amount: {amount_str}\n"
            f"Ref: {reference[:15]}\n"
            f"We'll notify you when confirmed\n"
            f"- Hosi Academy"
        )

        return message

    @staticmethod
    def refund_success(amount: float, currency: str, reference: str) -> str:
        """Generate refund success SMS"""
        currency_symbols = {'ZAR': 'R', 'USD': '$', 'NGN': '₦', 'KES': 'KSh'}
        symbol = currency_symbols.get(currency, currency)
        amount_str = f"{symbol}{amount:,.2f}"

        message = (
            f"💰 Refund Processed\n"
            f"Amount: {amount_str}\n"
            f"Ref: {reference[:15]}\n"
            f"Funds will reflect in 3-5 days\n"
            f"- Hosi Academy"
        )

        return message


# Singleton instance
sms_service = TwilioSMSService()
sms_template = SMSTemplateService()
