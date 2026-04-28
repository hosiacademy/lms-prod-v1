# backend/apps/payments/views/eft_views.py
"""
EFT/Bank Transfer Payment Views

Handles Electronic Funds Transfer (EFT) payments with asynchronous verification flow.
Supports both traditional EFT (manual verification) and Instant EFT (Ozow, i-Pay).
"""

import logging
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction as db_transaction
from django.db.models import Q, Sum, Count, F
from django.utils import timezone
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile

from apps.users.models import User
from apps.enrollments.models import ProvisionalEnrollment
from apps.payments.models import (
    PaymentTransaction, PaymentStatus, PaymentMethod,
    ProviderCountryConfig, PaymentProviderIntegration,
    AfricanCountry, CompanyBankAccount
)
from apps.payments.services.payment_service import PaymentService, PaymentError
from apps.payments.serializers import PaymentTransactionSerializer

logger = logging.getLogger(__name__)
payment_service = PaymentService()


# ============================================================================
# PUBLIC ENDPOINTS - Customer Facing
# ============================================================================

@api_view(['POST'])
@permission_classes([AllowAny])
def initiate_eft_payment(request):
    """
    POST /api/v1/payments/eft/initiate/
    
    Initiate an EFT/Bank Transfer payment.
    Creates a payment transaction with PENDING status and generates reference number.
    
    Request:
    {
        "program_id": "123",
        "type": "masterclass|learnership|industry",
        "amount": 1500.00,
        "currency": "ZAR",
        "country": "ZA",
        "metadata": {
            "enrollment_type": "masterclass",
            "program_title": "Course Name"
        },
        "individual_details": {
            "full_name": "John Doe",
            "email": "john@example.com",
            "phone": "+27123456789"
        }
    }
    
    Response:
    {
        "status": "pending",
        "reference": "EFT-20260313-123456",
        "amount": 1500.00,
        "currency": "ZAR",
        "bank_details": {
            "bank_name": "FNB Business",
            "account_number": "123456789",
            "account_name": "HosiTech LMS (Pty) Ltd",
            "branch_code": "250655",
            "account_type": "Current Account",
            "reference": "EFT-20260313-123456"
        },
        "expires_at": "2026-03-16T23:59:59Z",
        "instructions": [
            "Copy the bank details",
            "Make transfer from your banking app",
            "Use reference number: EFT-20260313-123456",
            "Payment will be verified within 24-72 hours"
        ]
    }
    """
    try:
        # Extract request data
        data = request.data
        program_id = data.get('program_id')
        program_type = data.get('type')
        amount = float(data.get('amount', 0))
        currency = data.get('currency', 'ZAR')
        country = data.get('country', 'ZA')
        metadata = data.get('metadata', {})
        individual_details = data.get('individual_details', {})
        corporate_details = data.get('corporate_details', {})
        
        # Validate required fields
        if not amount or amount <= 0:
            return Response(
                {'error': 'Invalid amount'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not program_id or not program_type:
            return Response(
                {'error': 'Program ID and type are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generate reference number
        reference = generate_eft_reference()
        
        # Get or create user (for guest payments, create minimal user record)
        user = None
        if individual_details.get('email'):
            user, created = User.objects.get_or_create(
                email=individual_details['email'],
                defaults={
                    'first_name': individual_details.get('first_name', ''),
                    'last_name': individual_details.get('last_name', ''),
                    'username': individual_details['email']
                }
            )
        
        # Create payment transaction
        with db_transaction.atomic():
            transaction = PaymentTransaction.objects.create(
                user=user,
                amount=amount,
                currency=currency,
                country=country,
                provider='eft',
                provider_reference=reference,
                transaction_type='PURCHASE',
                status=PaymentStatus.PENDING,
                description=f"EFT Payment for {program_type} - {program_id}",
                metadata={
                    **metadata,
                    'program_id': program_id,
                    'program_type': program_type,
                    'payment_flow': 'asynchronous',
                    'verification_method': 'manual',
                    'individual_details': individual_details,
                    'corporate_details': corporate_details,
                },
                individual_name=individual_details.get('full_name') or individual_details.get('name'),
                individual_email=individual_details.get('email'),
                individual_phone=individual_details.get('phone'),
                is_corporate=bool(corporate_details),
                company_name=corporate_details.get('company_name'),
                company_email=corporate_details.get('contact_email'),
            )
            
            # Create provisional enrollment with reference code
            enrollment = ProvisionalEnrollment.objects.create(
                user=user,
                enrollment_type=program_type,
                payment_transaction=transaction,
                status='provisional',
                reference_code=reference,  # Use the EFT reference as reference code
                metadata={
                    **metadata,
                    'program_id': program_id,
                    'amount': str(amount),
                    'currency': currency,
                },
                expires_at=timezone.now() + timedelta(hours=72),  # 72 hour expiry
            )
        
        # Get company bank details — match country + currency for multi-currency countries (e.g. Zambia)
        bank_details = get_company_bank_details(country, currency=currency)
        bank_details['reference'] = reference
        
        # Calculate expiry time
        expires_at = timezone.now() + timedelta(hours=72)
        
        logger.info(
            f"EFT payment initiated: {reference} for {amount} {currency}",
            extra={
                'transaction_id': transaction.id,
                'program_id': program_id,
                'program_type': program_type,
            }
        )
        
        # Send EFT initiated notifications (email + SMS)
        try:
            from apps.payments.tasks import send_eft_notifications
            send_eft_notifications.delay(transaction.id, 'initiated')
        except Exception as e:
            logger.error(f"Failed to queue EFT notifications: {str(e)}")
        
        return Response({
            'status': 'pending',
            'reference': reference,
            'transaction_id': transaction.id,
            'amount': amount,
            'currency': currency,
            'bank_details': bank_details,
            'expires_at': expires_at.isoformat(),
            'instructions': [
                'Copy the bank details provided',
                'Open your banking app or visit a branch',
                'Make a transfer for the exact amount',
                f'Use reference number: {reference}',
                'Payment will be verified within 24-72 hours',
                'You will receive email confirmation once verified'
            ],
            'next_steps': {
                'make_payment': 'Transfer the amount using the bank details provided',
                'submit_proof': 'Optionally upload proof of payment for faster verification',
                'wait_verification': 'Wait for payment verification (24-72 hours)'
            }
        })
        
    except Exception as e:
        logger.error(f"Error initiating EFT payment: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to initiate EFT payment: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def submit_bank_details(request):
    """
    POST /api/v1/payments/eft/submit-bank-details/
    
    Submit customer's bank details for verification (optional).
    This helps with faster verification and reconciliation.
    
    Request:
    {
        "reference": "EFT-20260313-123456",
        "bank_name": "FNB",
        "account_number": "987654321",
        "account_holder": "John Doe",
        "branch_code": "250655"
    }
    
    Response:
    {
        "status": "success",
        "message": "Bank details submitted successfully"
    }
    """
    try:
        data = request.data
        reference = data.get('reference')
        
        if not reference:
            return Response(
                {'error': 'Reference number is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Find transaction
        try:
            transaction = PaymentTransaction.objects.get(
                provider_reference=reference,
                provider='eft'
            )
        except PaymentTransaction.DoesNotExist:
            return Response(
                {'error': 'Transaction not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Update transaction metadata with customer bank details
        bank_details = {
            'bank_name': data.get('bank_name'),
            'account_number': data.get('account_number'),
            'account_holder': data.get('account_holder'),
            'branch_code': data.get('branch_code'),
            'submitted_at': timezone.now().isoformat(),
        }
        
        # Validate required fields
        if not all([bank_details['bank_name'], bank_details['account_number'], 
                   bank_details['account_holder'], bank_details['branch_code']]):
            return Response(
                {'error': 'All bank details fields are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Update metadata
        metadata = transaction.metadata or {}
        metadata['customer_bank_details'] = bank_details
        transaction.metadata = metadata
        transaction.save()
        
        # Also update provisional enrollment if exists
        try:
            enrollment = ProvisionalEnrollment.objects.get(
                payment_transaction=transaction
            )
            enrollment.metadata = enrollment.metadata or {}
            enrollment.metadata['customer_bank_details'] = bank_details
            enrollment.save()
        except ProvisionalEnrollment.DoesNotExist:
            pass
        
        logger.info(
            f"Bank details submitted for EFT: {reference}",
            extra={'transaction_id': transaction.id}
        )
        
        return Response({
            'status': 'success',
            'message': 'Bank details submitted successfully',
            'reference': reference
        })
        
    except Exception as e:
        logger.error(f"Error submitting bank details: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to submit bank details: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def check_eft_status(request, reference):
    """
    GET /api/v1/payments/eft/status/<reference>/
    
    Check the status of an EFT payment.
    
    Response:
    {
        "status": "pending|successful|failed|expired",
        "reference": "EFT-20260313-123456",
        "amount": 1500.00,
        "currency": "ZAR",
        "created_at": "2026-03-13T10:00:00Z",
        "expires_at": "2026-03-16T10:00:00Z",
        "time_remaining": "48 hours",
        "verified": false,
        "verified_at": null,
        "enrollment_status": "provisional"
    }
    """
    try:
        # Find transaction
        try:
            transaction = PaymentTransaction.objects.get(
                provider_reference=reference,
                provider='eft'
            )
        except PaymentTransaction.DoesNotExist:
            return Response(
                {'error': 'Transaction not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Get enrollment status
        enrollment_status = 'not_found'
        enrollment = None
        try:
            enrollment = ProvisionalEnrollment.objects.get(
                payment_transaction=transaction
            )
            enrollment_status = enrollment.status
        except ProvisionalEnrollment.DoesNotExist:
            pass
        
        # Determine payment status
        payment_status = transaction.status
        is_expired = False
        
        if enrollment and enrollment.expires_at:
            if timezone.now() > enrollment.expires_at and payment_status == PaymentStatus.PENDING:
                is_expired = True
                payment_status = 'expired'
        
        # Build response
        response_data = {
            'status': payment_status,
            'reference': reference,
            'transaction_id': transaction.id,
            'amount': float(transaction.amount),
            'currency': transaction.currency,
            'created_at': transaction.created_at.isoformat(),
            'updated_at': transaction.updated_at.isoformat(),
            'verified': payment_status == PaymentStatus.SUCCESSFUL,
            'verified_at': transaction.completed_at.isoformat() if transaction.completed_at else None,
            'enrollment_status': enrollment_status,
        }
        
        # Add expiry information
        if enrollment and enrollment.expires_at:
            response_data['expires_at'] = enrollment.expires_at.isoformat()
            
            # Calculate time remaining
            if not is_expired and payment_status == PaymentStatus.PENDING:
                time_remaining = enrollment.expires_at - timezone.now()
                hours_remaining = int(time_remaining.total_seconds() / 3600)
                response_data['time_remaining'] = f"{hours_remaining} hours"
                response_data['is_expired'] = False
            else:
                response_data['is_expired'] = is_expired
        
        # Add bank details submission status
        if transaction.metadata and 'customer_bank_details' in transaction.metadata:
            response_data['bank_details_submitted'] = True
            response_data['bank_details_submitted_at'] = \
                transaction.metadata['customer_bank_details'].get('submitted_at')
        else:
            response_data['bank_details_submitted'] = False

        # Include company bank details for the result page display
        try:
            _currency_country = {'ZAR': 'ZA', 'USD': 'ZA', 'KES': 'KE', 'NGN': 'NG', 'GHS': 'GH'}
            country_code = (
                (transaction.metadata.get('country') if transaction.metadata else None)
                or _currency_country.get(transaction.currency, 'ZA')
            )
            bank_details = get_company_bank_details(country_code, currency=transaction.currency)
            bank_details['reference'] = reference
            response_data['bank_details'] = bank_details
        except Exception:
            pass

        return Response(response_data)
        
    except Exception as e:
        logger.error(f"Error checking EFT status: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to check EFT status: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([AllowAny])
def upload_proof_of_payment(request, reference):
    """
    POST /api/v1/payments/eft/upload-pop/<reference>/
    
    Upload proof of payment (POP) document.
    
    Request: multipart/form-data
    - file: PDF, JPG, or PNG file (max 5MB)
    
    Response:
    {
        "status": "success",
        "message": "Proof of payment uploaded successfully",
        "file_url": "/media/pop/EFT-20260313-123456.pdf"
    }
    """
    try:
        # Find transaction
        try:
            transaction = PaymentTransaction.objects.get(
                provider_reference=reference,
                provider='eft'
            )
        except PaymentTransaction.DoesNotExist:
            return Response(
                {'error': 'Transaction not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Check if file was uploaded
        if 'file' not in request.FILES:
            return Response(
                {'error': 'No file uploaded'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        pop_file = request.FILES['file']
        
        # Validate file type
        allowed_types = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']
        if pop_file.content_type not in allowed_types:
            return Response(
                {'error': 'Invalid file type. Only PDF, JPG, and PNG are allowed'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Validate file size (max 5MB)
        max_size = 5 * 1024 * 1024  # 5MB
        if pop_file.size > max_size:
            return Response(
                {'error': 'File size exceeds 5MB limit'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Save file
        filename = f"pop/{reference}_{pop_file.name}"
        file_path = default_storage.save(filename, ContentFile(pop_file.read()))
        file_url = default_storage.url(file_path)
        
        # Update transaction metadata
        metadata = transaction.metadata or {}
        metadata['proof_of_payment'] = {
            'file_path': file_path,
            'file_url': file_url,
            'file_name': pop_file.name,
            'file_size': pop_file.size,
            'uploaded_at': timezone.now().isoformat(),
        }
        transaction.metadata = metadata
        transaction.save()
        
        # Update enrollment metadata
        try:
            enrollment = ProvisionalEnrollment.objects.get(
                payment_transaction=transaction
            )
            enrollment_metadata = enrollment.metadata or {}
            enrollment_metadata['proof_of_payment'] = metadata['proof_of_payment']
            enrollment.metadata = enrollment_metadata
            enrollment.save()
        except ProvisionalEnrollment.DoesNotExist:
            pass
        
        logger.info(
            f"Proof of payment uploaded for EFT: {reference}",
            extra={
                'transaction_id': transaction.id,
                'file_path': file_path
            }
        )
        
        return Response({
            'status': 'success',
            'message': 'Proof of payment uploaded successfully',
            'file_url': file_url,
            'reference': reference
        })
        
    except Exception as e:
        logger.error(f"Error uploading proof of payment: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to upload proof of payment: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ============================================================================
# ADMIN ENDPOINTS - Payment Verification
# ============================================================================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_pending_eft_payments(request):
    """
    GET /api/v1/payments/eft/admin/pending/
    
    Get all pending EFT payments awaiting verification.
    Only accessible by payment_admin, admin, or executive_admin roles.
    
    Query Parameters:
    - page: Page number (default: 1)
    - page_size: Items per page (default: 50)
    - search: Search by reference, email, or name
    - date_from: Filter by date from (YYYY-MM-DD)
    - date_to: Filter by date to (YYYY-MM-DD)
    - min_amount: Minimum amount filter
    - max_amount: Maximum amount filter
    
    Response:
    {
        "count": 125,
        "next": "/api/v1/payments/eft/admin/pending/?page=2",
        "previous": null,
        "results": [
            {
                "id": 12345,
                "reference": "EFT-20260313-123456",
                "amount": 1500.00,
                "currency": "ZAR",
                "customer_name": "John Doe",
                "customer_email": "john@example.com",
                "customer_phone": "+27123456789",
                "program_type": "masterclass",
                "program_id": "123",
                "created_at": "2026-03-13T10:00:00Z",
                "expires_at": "2026-03-16T10:00:00Z",
                "time_remaining": "48 hours",
                "bank_details_submitted": true,
                "proof_of_payment_uploaded": true,
                "proof_of_payment_url": "/media/pop/EFT-20260313-123456.pdf"
            }
        ]
    }
    """
    try:
        # Check permissions
        user = request.user
        if not (user.is_staff or user.is_superuser or getattr(user, 'role_id', None) == 1):
            return Response(
                {'error': 'Insufficient permissions'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get query parameters
        page = int(request.query_params.get('page', 1))
        page_size = int(request.query_params.get('page_size', 50))
        search = request.query_params.get('search')
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        min_amount = request.query_params.get('min_amount')
        max_amount = request.query_params.get('max_amount')
        
        # Build query
        queryset = PaymentTransaction.objects.filter(
            provider='eft',
            status=PaymentStatus.PENDING
        ).select_related('user').order_by('-created_at')
        
        # Apply filters
        if search:
            queryset = queryset.filter(
                Q(provider_reference__icontains=search) |
                Q(individual_name__icontains=search) |
                Q(individual_email__icontains=search) |
                Q(company_name__icontains=search)
            )
        
        if date_from:
            try:
                date_from_obj = datetime.strptime(date_from, '%Y-%m-%d')
                queryset = queryset.filter(created_at__gte=date_from_obj)
            except ValueError:
                pass
        
        if date_to:
            try:
                date_to_obj = datetime.strptime(date_to, '%Y-%m-%d')
                date_to_obj = date_to_obj.replace(hour=23, minute=59, second=59)
                queryset = queryset.filter(created_at__lte=date_to_obj)
            except ValueError:
                pass
        
        if min_amount:
            try:
                queryset = queryset.filter(amount__gte=float(min_amount))
            except ValueError:
                pass
        
        if max_amount:
            try:
                queryset = queryset.filter(amount__lte=float(max_amount))
            except ValueError:
                pass
        
        # Paginate
        total_count = queryset.count()
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        transactions = queryset[start_idx:end_idx]
        
        # Serialize results
        results = []
        for txn in transactions:
            # Get enrollment
            enrollment = None
            try:
                enrollment = ProvisionalEnrollment.objects.get(
                    payment_transaction=txn
                )
            except ProvisionalEnrollment.DoesNotExist:
                pass
            
            # Get proof of payment
            pop_uploaded = False
            pop_url = None
            if txn.metadata and 'proof_of_payment' in txn.metadata:
                pop_uploaded = True
                pop_url = txn.metadata['proof_of_payment'].get('file_url')
            
            # Calculate time remaining
            time_remaining = None
            is_expired = False
            if enrollment and enrollment.expires_at:
                if timezone.now() > enrollment.expires_at:
                    is_expired = True
                else:
                    time_diff = enrollment.expires_at - timezone.now()
                    hours = int(time_diff.total_seconds() / 3600)
                    time_remaining = f"{hours} hours"
            
            results.append({
                'id': txn.id,
                'reference': txn.provider_reference,
                'transaction_id': txn.id,
                'amount': float(txn.amount),
                'currency': txn.currency,
                'customer_name': txn.individual_name or txn.company_name,
                'customer_email': txn.individual_email or txn.company_email,
                'customer_phone': txn.individual_phone or txn.company_phone,
                'program_type': txn.metadata.get('program_type') if txn.metadata else None,
                'program_id': txn.metadata.get('program_id') if txn.metadata else None,
                'program_title': txn.metadata.get('program_title') if txn.metadata else None,
                'created_at': txn.created_at.isoformat(),
                'expires_at': enrollment.expires_at.isoformat() if enrollment and enrollment.expires_at else None,
                'time_remaining': time_remaining,
                'is_expired': is_expired,
                'bank_details_submitted': txn.metadata and 'customer_bank_details' in txn.metadata,
                'proof_of_payment_uploaded': pop_uploaded,
                'proof_of_payment_url': pop_url,
            })
        
        return Response({
            'count': total_count,
            'next': f"/api/v1/payments/eft/admin/pending/?page={page + 1}&page_size={page_size}" if end_idx < total_count else None,
            'previous': f"/api/v1/payments/eft/admin/pending/?page={page - 1}&page_size={page_size}" if page > 1 else None,
            'results': results,
            'filters': {
                'search': search,
                'date_from': date_from,
                'date_to': date_to,
                'min_amount': min_amount,
                'max_amount': max_amount,
            }
        })
        
    except Exception as e:
        logger.error(f"Error fetching pending EFT payments: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to fetch pending EFT payments: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_eft_payment(request):
    """
    POST /api/v1/payments/eft/admin/verify/
    
    Verify an EFT payment and activate enrollment.
    Only accessible by payment_admin, admin, or executive_admin roles.
    
    Request:
    {
        "reference": "EFT-20260313-123456",
        "verified_amount": 1500.00,  # Optional, defaults to transaction amount
        "notes": "Verified against bank statement"  # Optional
    }
    
    Response:
    {
        "status": "success",
        "message": "Payment verified successfully",
        "reference": "EFT-20260313-123456",
        "enrollment_activated": true,
        "enrollment_id": 12345
    }
    """
    try:
        # Check permissions
        user = request.user
        if not (user.is_staff or user.is_superuser or getattr(user, 'role_id', None) == 1):
            return Response(
                {'error': 'Insufficient permissions'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        data = request.data
        reference = data.get('reference')
        verified_amount = data.get('verified_amount')
        notes = data.get('notes', '')
        
        if not reference:
            return Response(
                {'error': 'Reference number is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        with db_transaction.atomic():
            # Find transaction
            try:
                transaction = PaymentTransaction.objects.get(
                    provider_reference=reference,
                    provider='eft'
                )
            except PaymentTransaction.DoesNotExist:
                return Response(
                    {'error': 'Transaction not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Check if already verified
            if transaction.status == PaymentStatus.SUCCESSFUL:
                return Response(
                    {'error': 'Payment already verified'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Update transaction
            transaction.status = PaymentStatus.SUCCESSFUL
            transaction.completed_at = timezone.now()
            transaction.reconciled = True
            transaction.reconciliation_date = timezone.now().date()
            
            metadata = transaction.metadata or {}
            metadata['verified_by'] = {
                'user_id': user.id,
                'user_email': user.email,
                'verified_at': timezone.now().isoformat(),
                'notes': notes,
            }
            if verified_amount:
                metadata['verified_amount'] = float(verified_amount)
            
            transaction.metadata = metadata
            transaction.save()
            
            # Update enrollment
            enrollment_id = None
            try:
                enrollment = ProvisionalEnrollment.objects.get(
                    payment_transaction=transaction
                )
                enrollment.status = 'confirmed'
                enrollment.verified_by = user
                enrollment.verified_at = timezone.now()
                enrollment.save()
                enrollment_id = enrollment.id
                
                # TODO: Trigger enrollment activation logic
                # This would typically:
                # 1. Create actual enrollment record
                # 2. Grant course access
                # 3. Send confirmation email
                # 4. Send welcome email
                
            except ProvisionalEnrollment.DoesNotExist:
                pass
        
        logger.info(
            f"EFT payment verified: {reference} by admin {user.email}",
            extra={
                'transaction_id': transaction.id,
                'admin_user': user.email,
                'enrollment_id': enrollment_id,
            }
        )
        
        # Send EFT verified notifications (email + SMS)
        try:
            from apps.payments.tasks import send_eft_notifications
            send_eft_notifications.delay(transaction.id, 'verified')
        except Exception as e:
            logger.error(f"Failed to queue EFT verified notifications: {str(e)}")
        
        return Response({
            'status': 'success',
            'message': 'Payment verified successfully',
            'reference': reference,
            'enrollment_activated': True,
            'enrollment_id': enrollment_id,
            'verified_at': transaction.completed_at.isoformat(),
        })
        
    except Exception as e:
        logger.error(f"Error verifying EFT payment: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to verify EFT payment: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reject_eft_payment(request):
    """
    POST /api/v1/payments/eft/admin/reject/
    
    Reject an EFT payment.
    Only accessible by payment_admin, admin, or executive_admin roles.
    
    Request:
    {
        "reference": "EFT-20260313-123456",
        "rejection_reason": "Amount does not match. Expected R1500.00, received R1400.00"
    }
    
    Response:
    {
        "status": "success",
        "message": "Payment rejected",
        "reference": "EFT-20260313-123456"
    }
    """
    try:
        # Check permissions
        user = request.user
        if not (user.is_staff or user.is_superuser or getattr(user, 'role_id', None) == 1):
            return Response(
                {'error': 'Insufficient permissions'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        data = request.data
        reference = data.get('reference')
        rejection_reason = data.get('rejection_reason', 'No reason provided')
        
        if not reference:
            return Response(
                {'error': 'Reference number is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if not rejection_reason:
            return Response(
                {'error': 'Rejection reason is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        with db_transaction.atomic():
            # Find transaction
            try:
                transaction = PaymentTransaction.objects.get(
                    provider_reference=reference,
                    provider='eft'
                )
            except PaymentTransaction.DoesNotExist:
                return Response(
                    {'error': 'Transaction not found'},
                    status=status.HTTP_404_NOT_FOUND
                )
            
            # Update transaction
            transaction.status = PaymentStatus.FAILED
            transaction.completed_at = timezone.now()
            
            metadata = transaction.metadata or {}
            metadata['rejected_by'] = {
                'user_id': user.id,
                'user_email': user.email,
                'rejected_at': timezone.now().isoformat(),
                'reason': rejection_reason,
            }
            transaction.metadata = metadata
            transaction.save()
            
            # Update enrollment
            try:
                enrollment = ProvisionalEnrollment.objects.get(
                    payment_transaction=transaction
                )
                enrollment.status = 'rejected'
                enrollment.verified_by = user
                enrollment.verified_at = timezone.now()
                enrollment.rejection_reason = rejection_reason
                enrollment.save()
            except ProvisionalEnrollment.DoesNotExist:
                pass
        
        logger.info(
            f"EFT payment rejected: {reference} by admin {user.email}",
            extra={
                'transaction_id': transaction.id,
                'admin_user': user.email,
                'reason': rejection_reason,
            }
        )
        
        # Send EFT rejected notifications (email + SMS)
        try:
            from apps.payments.tasks import send_eft_notifications
            send_eft_notifications.delay(transaction.id, 'rejected', rejection_reason)
        except Exception as e:
            logger.error(f"Failed to queue EFT rejected notifications: {str(e)}")
        
        # TODO: Send rejection email to customer
        
        return Response({
            'status': 'success',
            'message': 'Payment rejected',
            'reference': reference,
            'rejection_reason': rejection_reason,
        })
        
    except Exception as e:
        logger.error(f"Error rejecting EFT payment: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to reject EFT payment: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_eft_statistics(request):
    """
    GET /api/v1/payments/eft/admin/statistics/
    
    Get EFT payment statistics for dashboard.
    
    Query Parameters:
    - date_from: Filter by date from (YYYY-MM-DD)
    - date_to: Filter by date to (YYYY-MM-DD)
    
    Response:
    {
        "total_pending": 45,
        "total_pending_amount": 67500.00,
        "total_verified_today": 12,
        "total_verified_amount_today": 18000.00,
        "total_rejected_today": 3,
        "average_verification_time_hours": 28.5,
        "expiry_rate": 0.05,
        "bank_details_submission_rate": 0.65,
        "pop_upload_rate": 0.35
    }
    """
    try:
        # Check permissions
        user = request.user
        if not (user.is_staff or user.is_superuser or getattr(user, 'role_id', None) == 1):
            return Response(
                {'error': 'Insufficient permissions'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get date filters
        date_from = request.query_params.get('date_from')
        date_to = request.query_params.get('date_to')
        
        # Build base query
        base_query = PaymentTransaction.objects.filter(provider='eft')
        
        if date_from:
            try:
                date_from_obj = datetime.strptime(date_from, '%Y-%m-%d')
                base_query = base_query.filter(created_at__gte=date_from_obj)
            except ValueError:
                pass
        
        if date_to:
            try:
                date_to_obj = datetime.strptime(date_to, '%Y-%m-%d')
                date_to_obj = date_to_obj.replace(hour=23, minute=59, second=59)
                base_query = base_query.filter(created_at__lte=date_to_obj)
            except ValueError:
                pass
        
        # Calculate statistics
        total_pending = base_query.filter(status=PaymentStatus.PENDING).count()
        total_pending_amount = base_query.filter(
            status=PaymentStatus.PENDING
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        today = timezone.now().date()
        total_verified_today = base_query.filter(
            status=PaymentStatus.SUCCESSFUL,
            completed_at__date=today
        ).count()
        total_verified_amount_today = base_query.filter(
            status=PaymentStatus.SUCCESSFUL,
            completed_at__date=today
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        total_rejected_today = base_query.filter(
            status=PaymentStatus.FAILED,
            completed_at__date=today
        ).count()
        
        # Average verification time (for completed payments)
        verified_payments = base_query.filter(
            status=PaymentStatus.SUCCESSFUL,
            completed_at__isnull=False
        )
        
        avg_verification_hours = None
        if verified_payments.exists():
            # Calculate average time between created_at and completed_at
            total_hours = 0
            count = 0
            for txn in verified_payments:
                if txn.completed_at:
                    delta = txn.completed_at - txn.created_at
                    total_hours += delta.total_seconds() / 3600
                    count += 1
            if count > 0:
                avg_verification_hours = round(total_hours / count, 1)
        
        # Expiry rate
        total_expired = base_query.filter(
            status='expired'
        ).count() if 'expired' in [choice[0] for choice in PaymentStatus.choices] else 0
        total_completed = base_query.filter(
            Q(status=PaymentStatus.SUCCESSFUL) | Q(status=PaymentStatus.FAILED)
        ).count()
        expiry_rate = round(total_expired / (total_completed + total_expired), 2) if (total_completed + total_expired) > 0 else 0
        
        # Bank details submission rate
        total_with_bank_details = base_query.filter(
            metadata__customer_bank_details__isnull=False
        ).count()
        bank_details_rate = round(total_with_bank_details / base_query.count(), 2) if base_query.count() > 0 else 0
        
        # POP upload rate
        total_with_pop = base_query.filter(
            metadata__proof_of_payment__isnull=False
        ).count()
        pop_upload_rate = round(total_with_pop / base_query.count(), 2) if base_query.count() > 0 else 0
        
        return Response({
            'total_pending': total_pending,
            'total_pending_amount': float(total_pending_amount),
            'total_verified_today': total_verified_today,
            'total_verified_amount_today': float(total_verified_amount_today),
            'total_rejected_today': total_rejected_today,
            'average_verification_time_hours': avg_verification_hours,
            'expiry_rate': expiry_rate,
            'bank_details_submission_rate': bank_details_rate,
            'pop_upload_rate': pop_upload_rate,
            'total_transactions': base_query.count(),
        })
        
    except Exception as e:
        logger.error(f"Error fetching EFT statistics: {str(e)}", exc_info=True)
        return Response(
            {'error': f'Failed to fetch EFT statistics: {str(e)}'},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def generate_eft_reference() -> str:
    """
    Generate unique EFT reference number.
    Format: EFT-YYYYMMDD-XXXXXX
    """
    import random
    from datetime import datetime
    
    date_part = datetime.now().strftime('%Y%m%d')
    random_part = ''.join([str(random.randint(0, 9)) for _ in range(6)])
    
    return f"EFT-{date_part}-{random_part}"


def get_company_bank_details(country_code: str = 'ZA', currency: str = None) -> Dict[str, str]:
    """
    Get company bank details for a specific country and optional currency.
    Priority: exact currency match for country → country default → ZA default.
    """
    try:
        from ..models import CompanyBankAccount

        qs = CompanyBankAccount.objects.filter(country__code=country_code, is_active=True)

        # 1. Exact currency match for this country
        if currency:
            account = qs.filter(currency=currency).order_by('-is_default', 'priority').first()
            if account:
                return account.get_bank_details_dict()

        # 2. Country default (any currency)
        account = qs.order_by('-is_default', 'priority').first()
        if account:
            return account.get_bank_details_dict()

        # 3. Fallback to ZA default
        if country_code != 'ZA':
            account = CompanyBankAccount.objects.filter(
                country__code='ZA',
                is_active=True
            ).order_by('-is_default', 'priority').first()
            if account:
                return account.get_bank_details_dict()
        
    except Exception as e:
        logger.warning(f"Error fetching company bank account for {country_code}: {str(e)}")
    
    # Ultimate fallback to settings
    return {
        'bank_name': getattr(settings, 'COMPANY_BANK_NAME', 'FNB Business'),
        'account_number': getattr(settings, 'COMPANY_ACCOUNT_NUMBER', '123456789'),
        'account_name': getattr(settings, 'COMPANY_ACCOUNT_NAME', 'HosiTech LMS (Pty) Ltd'),
        'branch_code': getattr(settings, 'COMPANY_BRANCH_CODE', '250655'),
        'account_type': getattr(settings, 'COMPANY_ACCOUNT_TYPE', 'Current Account'),
        'bank_address': getattr(settings, 'COMPANY_BANK_ADDRESS', ''),
        'swift_code': getattr(settings, 'COMPANY_SWIFT_CODE', 'FIRNZAJJ'),
        'currency': 'ZAR',
        'country_code': 'ZA',
        'country_name': 'South Africa',
    }
