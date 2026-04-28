# apps/payments/views/learnership_payment_views.py
"""
View for calculating learnership payment plans and validating payment options.

Provides:
- POST /api/v1/payments/calculate-learnership-plan/ - Calculate payment breakdown
- Validates payment options against learnership business rules
- Ensures corporate enrollments use installments only
"""
import logging
from decimal import Decimal
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.shortcuts import get_object_or_404
from apps.learnerships.models import LearnershipProgramme
from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus
from apps.payments.models import Order

logger = logging.getLogger(__name__)


class CalculateLearnershipPaymentPlanView(APIView):
    """
    POST /api/v1/payments/calculate-learnership-plan/
    
    Calculate payment plan for learnership enrollment.
    
    Request body:
    {
        "programme_id": 1,                    // Required: Learnership programme ID
        "payment_option": "upfront",          // Optional: "upfront", "installments", "cash"
        "is_corporate": false,               // Optional: Default false
        "learner_count": 1,                   // Optional: Number of learners (for corporate)
        "currency": "USD"                     // Optional: Default USD
    }
    
    Response:
    {
        "success": true,
        "programme_id": 1,
        "programme_title": "SOC Analyst Learnership",
        "payment_option": "upfront",
        "base_price": 12000.00,
        "calculated_prices": {
            "total_amount": 12000.00,
            "deposit_amount": 3600.00,       // 30% of total
            "admin_fee": 180.00,             // 5% of deposit
            "monthly_installment": 700.00,   // (Total - deposit)/duration_months
            "deposit_due_now": 3780.00       // Deposit + admin fee
        },
        "breakdown": {
            "deposit_percentage": 30,
            "admin_fee_percentage": 5,
            "duration_months": 12,
            "installment_count": 12,
            "currency": "USD"
        },
        "validation": {
            "is_valid": true,
            "allowed_options": ["upfront", "installments", "cash"],
            "business_rules": {
                "corporate_must_use_installments": true,
                "requires_prerequisite_evidence": true,
                "payment_options": ["upfront", "installments", "cash"]
            }
        }
    }
    """
    permission_classes = [permissions.AllowAny]  # Allow for enrollment wizard
    
    def post(self, request):
        try:
            data = request.data
            
            # Required field
            programme_id = data.get('programme_id')
            if not programme_id:
                return Response(
                    {'error': 'programme_id is required'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Validate programme exists
            programme = get_object_or_404(LearnershipProgramme, id=programme_id)
            
            # Get payment option (default: upfront)
            payment_option = data.get('payment_option', 'upfront')
            if payment_option not in ['upfront', 'installments', 'cash']:
                return Response(
                    {'error': 'payment_option must be "upfront", "installments", or "cash"'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Check if corporate enrollment
            is_corporate = data.get('is_corporate', False)
            learner_count = data.get('learner_count', 1)
            currency = data.get('currency', programme.currency or 'USD')
            
            # BUSINESS RULE: Corporate enrollments must use installments
            if is_corporate and payment_option != 'installments':
                return Response(
                    {
                        'error': 'Corporate enrollments must use installments payment option',
                        'allowed_option': 'installments',
                        'business_rule': 'corporate_must_use_installments'
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
            
            # Get base price (use cost_usd field or calculate)
            base_price = programme.cost_usd
            if not base_price or base_price <= 0:
                # Fallback to default pricing if not set
                base_price = Decimal('12000.00')  # Default learnership price
            
            # Apply scaling for multiple learners (corporate)
            total_amount = base_price * Decimal(str(learner_count))
            
            # Calculate payment breakdown based on option
            if payment_option == 'upfront':
                # Full payment upfront
                calculation_result = self._calculate_upfront(total_amount)
            elif payment_option == 'installments':
                # Installment plan: 30% deposit + 5% admin fee + monthly installments
                calculation_result = self._calculate_installments(
                    total_amount, programme.duration_months
                )
            else:  # cash
                # Cash payment - just the total amount
                calculation_result = self._calculate_cash(total_amount)
            
            # Prepare validation info
            allowed_options = ['upfront', 'installments', 'cash']
            if is_corporate:
                allowed_options = ['installments']  # Corporate can only use installments
            
            validation = {
                'is_valid': True,
                'allowed_options': allowed_options,
                'business_rules': {
                    'corporate_must_use_installments': is_corporate,
                    'requires_prerequisite_evidence': bool(programme.prerequisites),
                    'payment_options': allowed_options,
                    'max_learners': programme.max_participants,
                    'available_slots': max(0, programme.max_participants - programme.current_participants)
                }
            }
            
            return Response({
                'success': True,
                'programme_id': programme.id,
                'programme_title': programme.title,
                'payment_option': payment_option,
                'is_corporate': is_corporate,
                'learner_count': learner_count,
                'base_price': float(base_price),
                'calculated_prices': calculation_result,
                'breakdown': {
                    'deposit_percentage': 30 if payment_option == 'installments' else 0,
                    'admin_fee_percentage': 5 if payment_option == 'installments' else 0,
                    'duration_months': programme.duration_months,
                    'installment_count': programme.duration_months if payment_option == 'installments' else 0,
                    'currency': currency
                },
                'validation': validation
            })
            
        except Exception as e:
            logger.error(f"Error calculating learnership payment plan: {str(e)}")
            return Response(
                {'error': f'Calculation failed: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _calculate_upfront(self, total_amount: Decimal):
        """Calculate upfront payment breakdown"""
        return {
            'total_amount': float(total_amount),
            'deposit_amount': 0.0,
            'admin_fee': 0.0,
            'monthly_installment': 0.0,
            'deposit_due_now': float(total_amount),
            'amount_paid': float(total_amount),
            'payment_status': 'pending',
            'payment_plan_type': 'full'
        }
    
    def _calculate_installments(self, total_amount: Decimal, duration_months: int):
        """Calculate installment payment breakdown"""
        # 30% deposit
        deposit_amount = total_amount * Decimal('0.30')
        
        # 5% admin fee on deposit (not on total)
        admin_fee = deposit_amount * Decimal('0.05')
        
        # Monthly installment = (Total - deposit) / duration
        monthly_installment = (total_amount - deposit_amount) / Decimal(str(duration_months))
        
        # Deposit due now includes admin fee
        deposit_due_now = deposit_amount + admin_fee
        
        return {
            'total_amount': float(total_amount),
            'deposit_amount': float(deposit_amount),
            'admin_fee': float(admin_fee),
            'monthly_installment': float(monthly_installment),
            'deposit_due_now': float(deposit_due_now),
            'amount_paid': float(deposit_due_now),  # Initial payment
            'remaining_amount': float(total_amount - deposit_amount),
            'payment_status': 'partial_paid',
            'payment_plan_type': 'deposit_debit',
            'installments_remaining': duration_months
        }
    
    def _calculate_cash(self, total_amount: Decimal):
        """Calculate cash payment breakdown"""
        return {
            'total_amount': float(total_amount),
            'deposit_amount': 0.0,
            'admin_fee': 0.0,
            'monthly_installment': 0.0,
            'deposit_due_now': 0.0,
            'amount_paid': 0.0,  # Cash payment at office
            'payment_status': 'cash_promise',
            'payment_plan_type': 'cash_office'
        }


class ValidateLearnershipPaymentView(APIView):
    """
    POST /api/v1/payments/validate-learnership-payment/
    
    Validate payment details before initiating payment.
    Ensures payment option matches learnership business rules.
    """
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        try:
            data = request.data
            
            required_fields = ['programme_id', 'payment_option', 'payment_amount']
            for field in required_fields:
                if field not in data:
                    return Response(
                        {'error': f'{field} is required'},
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            programme_id = data['programme_id']
            payment_option = data['payment_option']
            payment_amount = Decimal(str(data['payment_amount']))
            is_corporate = data.get('is_corporate', False)
            
            # Get programme
            programme = get_object_or_404(LearnershipProgramme, id=programme_id)
            
            # Validate payment option
            if payment_option not in ['upfront', 'installments', 'cash']:
                return Response({
                    'success': False,
                    'error': 'Invalid payment option',
                    'allowed_options': ['upfront', 'installments', 'cash']
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Business rule: Corporate must use installments
            if is_corporate and payment_option != 'installments':
                return Response({
                    'success': False,
                    'error': 'Corporate enrollments must use installments',
                    'business_rule': 'corporate_must_use_installments',
                    'allowed_option': 'installments'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Calculate expected payment amount
            base_price = programme.cost_usd or Decimal('12000.00')
            learner_count = data.get('learner_count', 1)
            total_amount = base_price * Decimal(str(learner_count))
            
            # Calculate expected amount based on payment option
            if payment_option == 'upfront':
                expected_amount = total_amount
            elif payment_option == 'installments':
                # Deposit + admin fee
                deposit = total_amount * Decimal('0.30')
                admin_fee = deposit * Decimal('0.05')
                expected_amount = deposit + admin_fee
            else:  # cash
                expected_amount = Decimal('0.00')  # No payment at this stage for cash
            
            # Validate amount matches expectation (with tolerance)
            tolerance = Decimal('0.01')  # 1 cent tolerance
            if expected_amount > 0 and abs(payment_amount - expected_amount) > tolerance:
                return Response({
                    'success': False,
                    'error': f'Payment amount mismatch. Expected: {expected_amount:.2f}, Got: {payment_amount:.2f}',
                    'expected_amount': float(expected_amount),
                    'actual_amount': float(payment_amount),
                    'difference': float(abs(payment_amount - expected_amount))
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if programme has available slots
            available_slots = programme.max_participants - programme.current_participants
            if learner_count > available_slots:
                return Response({
                    'success': False,
                    'error': f'Not enough available slots. Requested: {learner_count}, Available: {available_slots}',
                    'available_slots': available_slots,
                    'requested_slots': learner_count
                }, status=status.HTTP_400_BAD_REQUEST)
            
            return Response({
                'success': True,
                'validation': {
                    'payment_option_valid': True,
                    'amount_valid': True,
                    'programme_available': True,
                    'business_rules_valid': True,
                    'slots_available': available_slots >= learner_count
                },
                'programme_info': {
                    'title': programme.title,
                    'duration_months': programme.duration_months,
                    'has_prerequisites': bool(programme.prerequisites),
                    'requires_evidence': bool(programme.prerequisites)
                }
            })
            
        except Exception as e:
            logger.error(f"Error validating learnership payment: {str(e)}")
            return Response(
                {'error': f'Validation failed: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )