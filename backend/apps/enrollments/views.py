# apps/enrollments/views.py
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.authentication import SessionAuthentication, TokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from .models import ProvisionalEnrollment
from .serializers import ProvisionalEnrollmentSerializer, ProvisionalEnrollmentCreateSerializer


@api_view(['POST'])
# Note: No authentication required - users create provisional enrollment before payment
# Authentication happens after payment is confirmed
def create_provisional_enrollment(request):
    """
    Create provisional enrollment for cash payments or learnership verification.

    Cash payments: status=cash_pending, expires in 14 days
    Learnership online: status=provisional, expires in 7 days (prerequisite verification)
    """
    
    # For provisional enrollment, we allow unauthenticated users in some cases
    # (e.g., corporate enrollment where user is being created)
    # So we make authentication optional but recommended
    
    # Handle frontend data structure: 
    # Frontend sends: {program_id, type, method, amount, user_data: {...}}
    # Backend expects: {programme_id, enrollment_type, payment_method, ...}
    data = request.data.copy()
    
    # Map frontend fields to backend fields
    if 'program_id' in data:
        data['programme_id'] = data.pop('program_id')
    if 'type' in data:
        data['enrollment_type'] = data.pop('type')
    if 'method' in data:
        data['payment_method'] = data.pop('method')
    
    # Extract user_data fields if present
    if 'user_data' in data:
        user_data = data.pop('user_data', {})
        if 'corporate_details' not in data and user_data.get('is_corporate'):
            data['corporate_details'] = user_data.get('company', {})
        if 'individual_details' not in data:
            data['individual_details'] = user_data.get('individual_details', {})
            # Also check for learners array
            if not data['individual_details'] and 'learners' in user_data and len(user_data['learners']) > 0:
                learner = user_data['learners'][0]
                data['individual_details'] = {
                    'email': learner.get('email'),
                    'full_name': learner.get('full_name'),
                }
    
    serializer = ProvisionalEnrollmentCreateSerializer(data=data)
    serializer.is_valid(raise_exception=True)

    programme_id = serializer.validated_data.get('programme_id')
    enrollment_type = serializer.validated_data['enrollment_type']
    payment_method = serializer.validated_data.get('payment_method', 'cash')

    # Determine status based on payment method
    # Cash/Bank Transfer = pay later (provisional enrollment)
    # This applies to ALL enrollment types (masterclass, custom_selection, learnership, etc.)
    if payment_method in ['cash', 'bank_transfer']:
        initial_status = 'cash_pending'  # Awaiting payment confirmation
    else:
        # For other payment methods, create provisional enrollment pending payment
        initial_status = 'provisional'
    
    # Note: This is for ACTUAL enrollments where user will pay later
    # Payment will be processed through sandbox mode for testing

    # Create provisional enrollment
    # Handle anonymous users (user will be linked after registration/payment)
    user = None
    if request.user and request.user.is_authenticated:
        user = request.user
    
    metadata = {
        'corporate_details': serializer.validated_data.get('corporate_details'),
        'individual_details': serializer.validated_data.get('individual_details'),
        'payment_method': payment_method,
    }

    if enrollment_type != 'learnership' and programme_id:
        metadata['training_id'] = programme_id
        programme_id = None

    provisional = ProvisionalEnrollment.objects.create(
        user=user,
        programme_id=programme_id,
        enrollment_type=enrollment_type,
        status=initial_status,
        metadata=metadata
    )

    # Send notification email (async task)
    try:
        from .tasks import send_provisional_enrollment_email
        send_provisional_enrollment_email.delay(provisional.id)
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f"Failed to queue provisional enrollment email: {e}")

    # Get office details for cash payments
    office_details = None
    if initial_status == 'cash_pending':
        user_country = 'ZW'
        if request.user and request.user.is_authenticated:
            user_country = getattr(request.user, 'country', 'ZW')
        elif data.get('country'):
            # If guest, try to use country from request
            user_country = data.get('country')
            
        office_details = get_office_details(user_country)

    return Response({
        'reference_code': provisional.reference_code,
        'status': provisional.status,
        'expires_at': provisional.expires_at,
        'office_details': office_details,
        'enrollment': ProvisionalEnrollmentSerializer(provisional).data
    }, status=status.HTTP_201_CREATED)


def get_office_details(country_code):
    """
    Get office payment details for a country.

    TODO: Store in database or configuration
    """
    office_map = {
        'ZW': {
            'name': 'Hosi Academy Zimbabwe Office',
            'address': '123 Main Street, Harare',
            'phone': '+263 123 456 789',
            'email': 'payments.zw@hosiacademy.com',
            'hours': 'Mon-Fri: 8:00 AM - 5:00 PM',
        },
        'ZA': {
            'name': 'Hosi Academy South Africa Office',
            'address': '456 Market Street, Johannesburg',
            'phone': '+27 123 456 789',
            'email': 'payments.za@hosiacademy.com',
            'hours': 'Mon-Fri: 8:00 AM - 5:00 PM',
        },
        'NG': {
            'name': 'Hosi Academy Nigeria Office',
            'address': '789 Victoria Island, Lagos',
            'phone': '+234 123 456 789',
            'email': 'payments.ng@hosiacademy.com',
            'hours': 'Mon-Fri: 9:00 AM - 5:00 PM',
        },
        'KE': {
            'name': 'Hosi Academy Kenya Office',
            'address': 'Westlands, Nairobi',
            'phone': '+254 123 456 789',
            'email': 'payments.ke@hosiacademy.com',
            'hours': 'Mon-Fri: 8:30 AM - 5:30 PM',
        },
        # Add more countries as needed
    }

    return office_map.get(country_code, {
        'name': 'Hosi Academy',
        'email': 'payments@hosiacademy.com',
        'note': 'Please contact us for office details in your country'
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_provisional_enrollments(request):
    """Get user's provisional enrollments"""
    enrollments = ProvisionalEnrollment.objects.filter(user=request.user)
    serializer = ProvisionalEnrollmentSerializer(enrollments, many=True)
    return Response(serializer.data)
