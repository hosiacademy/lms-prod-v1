# apps/payments/views/webhook_views.py
import json
import logging
from django.utils import timezone  # Now imported properly
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_POST
from django.http import HttpResponse, JsonResponse
from django.conf import settings
from ..services.payment_service import payment_service
from ..models import PaymentWebhookLog

logger = logging.getLogger(__name__)


@csrf_exempt
@require_POST
def provider_webhook(request, provider_code):
    """
    Generic webhook endpoint for all payment providers
    URL: /api/payments/webhooks/<provider_code>/
    
    CRITICAL: Passes raw body to service for proper signature verification.
    """
    try:
        # CRITICAL FIX: Capture raw body BEFORE parsing
        # Payment providers sign the exact raw bytes they send
        # Parsing first (json.loads) can alter whitespace/key order, breaking signature verification
        raw_body = request.body  # Keep as bytes
        
        # Parse for logging and processing
        payload = json.loads(raw_body.decode('utf-8')) if raw_body else {}

        webhook_log = PaymentWebhookLog.objects.create(
            provider=provider_code,
            event_type='webhook_received',
            payload=payload,
            headers=dict(request.headers),
            raw_body=raw_body.decode('utf-8') if raw_body else '',
            signature_valid=True,  # Will be validated by adapter
        )

        # Process webhook with RAW BODY for signature verification
        transaction = payment_service.handle_webhook(
            provider_code=provider_code,
            payload=payload,
            headers=dict(request.headers),
            raw_body=raw_body,  # Pass raw bytes for signature verification
        )

        # Update webhook log
        webhook_log.processed = True
        webhook_log.transaction = transaction
        webhook_log.processed_at = timezone.now()  # Now this works
        webhook_log.signature_valid = True  # Signature was valid if we got here
        webhook_log.save()

        return JsonResponse({
            'status': 'success',
            'message': 'Webhook processed successfully',
            'transaction_id': str(transaction.id),
        }, status=200)

    except Exception as e:
        logger.error(f"Webhook error for {provider_code}: {str(e)}")

        # Update webhook log with error
        if 'webhook_log' in locals():
            webhook_log.processed = False
            webhook_log.processing_error = str(e)
            webhook_log.signature_valid = False
            webhook_log.save()

        return JsonResponse({
            'status': 'error',
            'message': str(e),
        }, status=400)


@csrf_exempt
@require_POST
def country_webhook(request, provider_code, country_code):
    """
    Country-specific webhook endpoint
    URL: /api/payments/webhooks/<provider_code>/<country_code>/
    """
    # You might want to add country_code to the payload or metadata
    try:
        raw_body = request.body.decode('utf-8')
        payload = json.loads(raw_body) if raw_body else {}
        
        # Add country code to payload for processing
        if isinstance(payload, dict):
            payload['_country_code'] = country_code
        
        # Create a modified request object if needed
        return provider_webhook(request, provider_code)
    except Exception as e:
        logger.error(f"Country webhook error for {provider_code}/{country_code}: {str(e)}")
        return JsonResponse({
            'status': 'error',
            'message': str(e),
        }, status=400)
