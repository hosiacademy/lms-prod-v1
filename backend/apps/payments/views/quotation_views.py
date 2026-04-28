"""
Quotation System API Views
- Cascading dropdowns for training types & pricing
- SmatPay payment link generation
- Email & SMS delivery
"""
import logging
from decimal import Decimal
from datetime import timedelta

from django.utils import timezone
from django.db import transaction
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status

from ..models import PaymentTransaction, Order
from ..quotation_models import (
    ClientQuotation, QuotationItem, QuotationActivityLog,
    TrainingType, QuotationStatus
)

logger = logging.getLogger(__name__)


def is_payment_admin(user):
    """Check if user has payment/sales/marketing admin role"""
    if user.is_staff or user.is_superuser:
        return True
    # Check AdminRole
    try:
        from ..models import AdminRole
        role = AdminRole.objects.filter(user=user, is_active=True).first()
        if role and role.role_type in [
            'payment_admin', 'payment_sales_marketing_admin',
            'sales_admin', 'marketing_admin'
        ]:
            return True
    except:
        pass
    return False


# ═══════════════════════════════════════════════════════════════════════════════
# CASCADING DROPDOWN APIs
# ═══════════════════════════════════════════════════════════════════════════════

class GetTrainingTypesView(APIView):
    """
    GET /api/v1/payments/quotations/training-types/
    Returns available training types for dropdown
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        types = [
            {'code': TrainingType.COURSE, 'name': 'AI Certs Course'},
            {'code': TrainingType.MASTERCLASS, 'name': 'Professional Masterclass'},
            {'code': TrainingType.LEARNERSHIP, 'name': 'Learnership Program'},
        ]
        
        return Response({'types': types})


class GetTrainingStreamsView(APIView):
    """
    GET /api/v1/payments/quotations/streams/
    Returns available training streams (Industry, Learnership, etc.)
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
            
        streams = [
            {'id': 'industry', 'name': 'Industry (Corporate)'},
            {'id': 'learnership', 'name': 'Learnership (B-BBEE)'},
            {'id': 'individual', 'name': 'Individual (Private)'},
        ]
        return Response({'streams': streams})


class GetCoursesListView(APIView):
    """
    GET /api/v1/payments/quotations/courses/
    Returns list of AI Certs courses with pricing
    Query params: ?country=ZA&currency=ZAR
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        country_code = request.query_params.get('country', 'ZW').upper()
        currency = request.query_params.get('currency', 'USD').upper()
        
        try:
            # Import AICERTS courses
            from apps.courses.models import AICERTSCourse
            from apps.localization.models import Country
            
            country = Country.objects.filter(code=country_code).first()
            
            courses = []
            for course in AICERTSCourse.objects.filter(is_active=True):
                # Get localized pricing
                price_usd = course.base_price or Decimal('0.00')
                
                # Convert to local currency if needed
                if currency != 'USD' and country:
                    # Get exchange rate
                    from apps.payments.exchange_rate_models import ExchangeRate
                    rate = ExchangeRate.objects.filter(
                        source_currency='USD',
                        target_currency=currency
                    ).first()
                    if rate:
                        local_price = price_usd * rate.rate
                    else:
                        local_price = price_usd
                else:
                    local_price = price_usd
                
                courses.append({
                    'id': course.id,
                    'name': course.title,
                    'code': course.code,
                    'description': course.description[:100] if course.description else '',
                    'duration': course.duration,
                    'price_usd': str(price_usd),
                    'local_price': str(local_price),
                    'currency': currency,
                })
            
            return Response({'courses': courses})
        
        except Exception as e:
            logger.error(f"Error fetching courses: {e}")
            # Return sample data if models not available
            return Response({'courses': [
                {'id': 1, 'name': 'AI Project Management Practitioner', 'code': 'AI-PM-101', 'duration': '8 weeks', 'price_usd': '299.00', 'local_price': '299.00'},
                {'id': 2, 'name': 'AI Context Engineering', 'code': 'AI-CE-201', 'duration': '6 weeks', 'price_usd': '249.00', 'local_price': '249.00'},
                {'id': 3, 'name': 'AI Vibe Coder', 'code': 'AI-VC-301', 'duration': '4 weeks', 'price_usd': '199.00', 'local_price': '199.00'},
            ]})


class GetMasterclassesListView(APIView):
    """
    GET /api/v1/payments/quotations/masterclasses/
    Returns list of Masterclasses with pricing
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        country_code = request.query_params.get('country', 'ZW').upper()
        currency = request.query_params.get('currency', 'USD').upper()
        
        try:
            # Import Masterclasses
            from apps.masterclasses.models import MasterclassSchedule
            from apps.localization.models import Country
            
            country = Country.objects.filter(code=country_code).first()
            
            masterclasses = []
            for mc in MasterclassSchedule.objects.filter(is_active=True):
                price_usd = mc.price or Decimal('0.00')
                
                # Convert to local currency
                if currency != 'USD' and country:
                    from apps.payments.exchange_rate_models import ExchangeRate
                    rate = ExchangeRate.objects.filter(
                        source_currency='USD',
                        target_currency=currency
                    ).first()
                    if rate:
                        local_price = price_usd * rate.rate
                    else:
                        local_price = price_usd
                else:
                    local_price = price_usd
                
                masterclasses.append({
                    'id': mc.id,
                    'name': mc.title,
                    'category': mc.category,
                    'start_date': mc.start_date.isoformat() if mc.start_date else None,
                    'end_date': mc.end_date.isoformat() if mc.end_date else None,
                    'duration_hours': mc.duration_hours,
                    'price_usd': str(price_usd),
                    'local_price': str(local_price),
                    'currency': currency,
                    'max_participants': mc.max_participants,
                })
            
            return Response({'masterclasses': masterclasses})
        
        except Exception as e:
            logger.error(f"Error fetching masterclasses: {e}")
            return Response({'masterclasses': [
                {'id': 1, 'name': 'AI Strategy for Executives', 'category': 'Professional', 'duration_hours': 16, 'price_usd': '150.00', 'local_price': '150.00'},
                {'id': 2, 'name': 'Machine Learning Fundamentals', 'category': 'Technical', 'duration_hours': 24, 'price_usd': '200.00', 'local_price': '200.00'},
                {'id': 3, 'name': 'AI Ethics & Governance', 'category': 'Professional', 'duration_hours': 8, 'price_usd': '75.00', 'local_price': '75.00'},
            ]})


class GetLearnershipsListView(APIView):
    """
    GET /api/v1/payments/quotations/learnerships/
    Returns list of Learnerships with pricing
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        country_code = request.query_params.get('country', 'ZW').upper()
        currency = request.query_params.get('currency', 'USD').upper()
        
        try:
            # Import Learnerships
            from apps.learnerships.models import Learnership
            from apps.localization.models import Country
            
            country = Country.objects.filter(code=country_code).first()
            
            learnerships = []
            for lp in Learnership.objects.filter(is_active=True):
                price_usd = lp.price or Decimal('0.00')
                
                # Convert to local currency
                if currency != 'USD' and country:
                    from apps.payments.exchange_rate_models import ExchangeRate
                    rate = ExchangeRate.objects.filter(
                        source_currency='USD',
                        target_currency=currency
                    ).first()
                    if rate:
                        local_price = price_usd * rate.rate
                    else:
                        local_price = price_usd
                else:
                    local_price = price_usd
                
                learnerships.append({
                    'id': lp.id,
                    'name': lp.title,
                    'program_code': lp.program_code,
                    'sector': lp.sector,
                    'duration_months': lp.duration_months,
                    'nqf_level': lp.nqf_level,
                    'price_usd': str(price_usd),
                    'local_price': str(local_price),
                    'currency': currency,
                    'max_learners': lp.max_learners,
                })
            
            return Response({'learnerships': learnerships})
        
        except Exception as e:
            logger.error(f"Error fetching learnerships: {e}")
            return Response({'learnerships': [
                {'id': 1, 'name': 'AI & Blockchain Systems Development', 'program_code': 'AI-BLK-2026', 'sector': 'ICT', 'duration_months': 12, 'nqf_level': 5, 'price_usd': '0.00', 'local_price': '0.00'},
                {'id': 2, 'name': 'Cybersecurity Operations', 'program_code': 'CYB-OPS-2026', 'sector': 'ICT', 'duration_months': 12, 'nqf_level': 5, 'price_usd': '0.00', 'local_price': '0.00'},
            ]})


class GetItemPricingView(APIView):
    """
    POST /api/v1/payments/quotations/get-pricing/
    Get pricing for selected item with exchange rate conversion
    
    Request: {
        "training_type": "course",
        "item_id": 1,
        "country_code": "ZW",
        "quantity": 1
    }
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        training_type = request.data.get('training_type')
        item_id = request.data.get('item_id')
        country_code = request.data.get('country_code', 'ZW').upper()
        quantity = int(request.data.get('quantity', 1))
        
        if not training_type or not item_id:
            return Response({'error': 'training_type and item_id required'}, status=400)
        
        try:
            # Get country & currency
            from apps.localization.models import Country
            country = Country.objects.filter(code=country_code).first()
            local_currency = country.currency if country else 'USD'
            
            # Get base price
            base_price_usd = Decimal('0.00')
            item_name = ''
            
            if training_type == TrainingType.COURSE:
                from apps.courses.models import AICERTSCourse
                item = AICERTSCourse.objects.get(id=item_id)
                base_price_usd = item.base_price or Decimal('0.00')
                item_name = item.title
                
            elif training_type == TrainingType.MASTERCLASS:
                from apps.masterclasses.models import MasterclassSchedule
                item = MasterclassSchedule.objects.get(id=item_id)
                base_price_usd = item.price or Decimal('0.00')
                item_name = item.title
                
            elif training_type == TrainingType.LEARNERSHIP:
                from apps.learnerships.models import Learnership
                item = Learnership.objects.get(id=item_id)
                base_price_usd = item.price or Decimal('0.00')
                item_name = item.title
            
            # Get exchange rate
            exchange_rate = Decimal('1.0')
            if local_currency != 'USD':
                from apps.payments.exchange_rate_models import ExchangeRate
                rate_obj = ExchangeRate.objects.filter(
                    source_currency='USD',
                    target_currency=local_currency
                ).first()
                if rate_obj:
                    exchange_rate = rate_obj.rate
            
            # Calculate amounts
            total_usd = base_price_usd * quantity
            local_amount = total_usd * exchange_rate
            
            return Response({
                'success': True,
                'training_type': training_type,
                'item_id': item_id,
                'item_name': item_name,
                'base_price_usd': str(base_price_usd),
                'quantity': quantity,
                'total_usd': str(total_usd),
                'exchange_rate': str(exchange_rate),
                'local_currency': local_currency,
                'local_amount': str(local_amount.quantize(Decimal('0.01'))),
            })
            
        except Exception as e:
            logger.error(f"Error getting pricing: {e}")
            return Response({'error': str(e)}, status=500)


# ═══════════════════════════════════════════════════════════════════════════════
# QUOTATION CRUD APIs
# ═══════════════════════════════════════════════════════════════════════════════

class CreateQuotationView(APIView):
    """
    POST /api/v1/payments/quotations/create/
    Create a new quotation with SmatPay payment link
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        data = request.data
        
        # Validate required fields
        required = ['client_name', 'client_email', 'training_type', 'item_id']
        for field in required:
            if not data.get(field):
                return Response({'error': f'{field} is required'}, status=400)
        
        try:
            with transaction.atomic():
                # Get pricing
                training_type = data['training_type']
                item_id = data['item_id']
                country_code = data.get('client_country', 'ZW').upper()
                quantity = int(data.get('quantity', 1))
                
                # Get item details and pricing
                from apps.localization.models import Country
                country = Country.objects.filter(code=country_code).first()
                local_currency = country.currency if country else 'USD'
                
                base_price_usd = Decimal('0.00')
                item_name = ''
                
                course_id = masterclass_id = learnership_id = None
                course_name = masterclass_name = learnership_name = ''
                
                if training_type == TrainingType.COURSE:
                    from apps.courses.models import AICERTSCourse
                    item = AICERTSCourse.objects.get(id=item_id)
                    base_price_usd = item.base_price or Decimal('0.00')
                    item_name = item.title
                    course_id = item.id
                    course_name = item.title
                    
                elif training_type == TrainingType.MASTERCLASS:
                    from apps.masterclasses.models import MasterclassSchedule
                    item = MasterclassSchedule.objects.get(id=item_id)
                    base_price_usd = item.price or Decimal('0.00')
                    item_name = item.title
                    masterclass_id = item.id
                    masterclass_name = item.title
                    
                elif training_type == TrainingType.LEARNERSHIP:
                    from apps.learnerships.models import Learnership
                    item = Learnership.objects.get(id=item_id)
                    base_price_usd = item.price or Decimal('0.00')
                    item_name = item.title
                    learnership_id = item.id
                    learnership_name = item.title
                
                # Calculate exchange rate
                exchange_rate = Decimal('1.0')
                if local_currency != 'USD':
                    from apps.payments.exchange_rate_models import ExchangeRate
                    rate_obj = ExchangeRate.objects.filter(
                        source_currency='USD',
                        target_currency=local_currency
                    ).first()
                    if rate_obj:
                        exchange_rate = rate_obj.rate
                
                # Calculate totals
                subtotal_usd = base_price_usd * quantity
                discount_pct = Decimal(str(data.get('discount_percentage', 0)))
                discount_amount = subtotal_usd * (discount_pct / 100)
                vat_amount = Decimal('0.00')  # Can be calculated based on country
                total_usd = subtotal_usd - discount_amount + vat_amount
                local_amount = total_usd * exchange_rate
                
                # Create quotation
                quotation = ClientQuotation.objects.create(
                    client_name=data['client_name'],
                    client_email=data['client_email'],
                    client_phone=data.get('client_phone', ''),
                    client_company=data.get('client_company', ''),
                    client_country=country_code,
                    training_type=training_type,
                    course_id=course_id,
                    course_name=course_name,
                    masterclass_id=masterclass_id,
                    masterclass_name=masterclass_name,
                    learnership_id=learnership_id,
                    learnership_name=learnership_name,
                    base_price=base_price_usd,
                    local_currency=local_currency,
                    local_amount=local_amount.quantize(Decimal('0.01')),
                    exchange_rate=exchange_rate,
                    quantity=quantity,
                    discount_percentage=discount_pct,
                    discount_amount=discount_amount,
                    subtotal=subtotal_usd - discount_amount,
                    vat_amount=vat_amount,
                    total_amount=total_usd,
                    description=data.get('description', ''),
                    validity_days=int(data.get('validity_days', 30)),
                    created_by=request.user,
                )
                
                # Generate SmatPay payment link
                payment_link = self._generate_smatpay_link(quotation)
                if payment_link:
                    quotation.smatpay_payment_link = payment_link
                    quotation.save()
                
                # Log activity
                QuotationActivityLog.objects.create(
                    quotation=quotation,
                    activity_type='created',
                    description=f'Quotation created by {request.user.email}',
                    performed_by=request.user,
                )
                
                return Response({
                    'success': True,
                    'quotation': {
                        'id': quotation.id,
                        'quotation_number': quotation.quotation_number,
                        'client_name': quotation.client_name,
                        'training_type': quotation.training_type,
                        'training_item': item_name,
                        'base_price': str(base_price_usd),
                        'quantity': quantity,
                        'total_usd': str(total_usd),
                        'local_amount': str(quotation.local_amount),
                        'local_currency': local_currency,
                        'smatpay_link': quotation.smatpay_payment_link,
                        'status': quotation.status,
                        'created_at': quotation.created_at.isoformat(),
                        'expires_at': quotation.expires_at.isoformat() if quotation.expires_at else None,
                    }
                })
                
        except Exception as e:
            logger.error(f"Error creating quotation: {e}")
            return Response({'error': str(e)}, status=500)
    
    def _generate_smatpay_link(self, quotation):
        """Generate SmatPay payment link for quotation"""
        try:
            # Create order for SmatPay
            order = Order.objects.create(
                user=None,  # No user until payment
                amount=quotation.total_amount,
                currency='USD',  # SmatPay requires USD
                metadata={
                    'quotation_id': quotation.id,
                    'quotation_number': quotation.quotation_number,
                    'client_email': quotation.client_email,
                    'client_name': quotation.client_name,
                    'is_quotation_payment': True,
                }
            )
            
            # Create payment transaction
            transaction = PaymentTransaction.objects.create(
                order=order,
                provider='smatpay',
                amount=quotation.total_amount,
                currency='USD',
                status='pending',
                description=f'Quotation {quotation.quotation_number}',
            )
            
            # Generate SmatPay link
            from apps.payments.adapters.smatpay import SmatPayAdapter
            
            adapter = SmatPayAdapter()
            result = adapter.initiate_payment(
                transaction=transaction,
                return_url=f"{settings.FRONTEND_URL}/quotations/{quotation.quotation_number}/success",
                cancel_url=f"{settings.FRONTEND_URL}/quotations/{quotation.quotation_number}/cancel",
            )
            
            quotation.smatpay_reference = transaction.provider_reference
            quotation.save()
            
            return result.get('payment_url')
            
        except Exception as e:
            logger.error(f"Error generating SmatPay link: {e}")
            return None


class ListQuotationsView(APIView):
    """
    GET /api/v1/payments/quotations/
    List all quotations with filtering
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        # Filters
        status_filter = request.query_params.get('status')
        training_type = request.query_params.get('training_type')
        search = request.query_params.get('search')
        
        queryset = ClientQuotation.objects.all()
        
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if training_type:
            queryset = queryset.filter(training_type=training_type)
        if search:
            queryset = queryset.filter(
                models.Q(client_name__icontains=search) |
                models.Q(client_email__icontains=search) |
                models.Q(quotation_number__icontains=search)
            )
        
        quotations = []
        for q in queryset[:100]:
            quotations.append({
                'id': q.id,
                'quotation_number': q.quotation_number,
                'client_name': q.client_name,
                'client_email': q.client_email,
                'training_type': q.training_type,
                'training_item': q.training_item_name,
                'total_amount': str(q.total_amount),
                'local_amount': str(q.local_amount),
                'local_currency': q.local_currency,
                'status': q.status,
                'email_sent': q.email_sent,
                'sms_sent': q.sms_sent,
                'created_at': q.created_at.isoformat(),
                'expires_at': q.expires_at.isoformat() if q.expires_at else None,
                'days_until_expiry': q.days_until_expiry,
            })
        
        return Response({
            'quotations': quotations,
            'total': queryset.count(),
        })


class QuotationDetailView(APIView):
    """
    GET /api/v1/payments/quotations/<quotation_number>/
    Get full quotation details
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request, quotation_number):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        try:
            quotation = ClientQuotation.objects.get(quotation_number=quotation_number)
            
            return Response({
                'id': quotation.id,
                'quotation_number': quotation.quotation_number,
                'client': {
                    'name': quotation.client_name,
                    'email': quotation.client_email,
                    'phone': quotation.client_phone,
                    'company': quotation.client_company,
                    'country': quotation.client_country,
                },
                'training': {
                    'type': quotation.training_type,
                    'item_name': quotation.training_item_name,
                    'course_id': quotation.course_id,
                    'masterclass_id': quotation.masterclass_id,
                    'learnership_id': quotation.learnership_id,
                },
                'pricing': {
                    'base_price': str(quotation.base_price),
                    'quantity': quotation.quantity,
                    'exchange_rate': str(quotation.exchange_rate),
                    'local_currency': quotation.local_currency,
                    'local_amount': str(quotation.local_amount),
                    'discount_percentage': str(quotation.discount_percentage),
                    'discount_amount': str(quotation.discount_amount),
                    'subtotal': str(quotation.subtotal),
                    'vat_amount': str(quotation.vat_amount),
                    'total_amount': str(quotation.total_amount),
                },
                'description': quotation.description,
                'validity_days': quotation.validity_days,
                'expires_at': quotation.expires_at.isoformat() if quotation.expires_at else None,
                'status': quotation.status,
                'smatpay_link': quotation.smatpay_payment_link,
                'delivery': {
                    'email_sent': quotation.email_sent,
                    'email_sent_at': quotation.email_sent_at.isoformat() if quotation.email_sent_at else None,
                    'sms_sent': quotation.sms_sent,
                    'sms_sent_at': quotation.sms_sent_at.isoformat() if quotation.sms_sent_at else None,
                },
                'activity': [
                    {
                        'type': log.activity_type,
                        'description': log.description,
                        'created_at': log.created_at.isoformat(),
                    }
                    for log in quotation.activity_logs.all()[:20]
                ],
                'created_at': quotation.created_at.isoformat(),
            })
            
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)


class UpdateQuotationView(APIView):
    """
    PATCH /api/v1/payments/quotations/<id>/update/
    Update quotation details
    """
    permission_classes = [IsAuthenticated]
    
    def patch(self, request, quotation_id):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        try:
            quotation = ClientQuotation.objects.get(id=quotation_id)
            
            # Only allow updates for draft status
            if quotation.status not in [QuotationStatus.DRAFT, QuotationStatus.SENT]:
                return Response({'error': 'Cannot update quotation that is already accepted/paid'}, status=400)
            
            # Update fields
            allowed_fields = [
                'client_name', 'client_email', 'client_phone', 'client_company',
                'description', 'discount_percentage', 'validity_days'
            ]
            
            for field in allowed_fields:
                if field in request.data:
                    setattr(quotation, field, request.data[field])
            
            quotation.save()
            
            return Response({
                'success': True,
                'quotation': {
                    'id': quotation.id,
                    'quotation_number': quotation.quotation_number,
                    'total_amount': str(quotation.total_amount),
                }
            })
            
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)


class DeleteQuotationView(APIView):
    """
    DELETE /api/v1/payments/quotations/<id>/delete/
    Delete a quotation
    """
    permission_classes = [IsAuthenticated]
    
    def delete(self, request, quotation_id):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        try:
            quotation = ClientQuotation.objects.get(id=quotation_id)
            
            # Only allow deletion for draft/pending
            if quotation.status in [QuotationStatus.PAID]:
                return Response({'error': 'Cannot delete paid quotation'}, status=400)
            
            quotation.delete()
            return Response({'success': True, 'message': 'Quotation deleted'})
            
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)


# ═══════════════════════════════════════════════════════════════════════════════
# EMAIL & SMS DELIVERY APIs
# ═══════════════════════════════════════════════════════════════════════════════

class SendQuotationEmailView(APIView):
    """
    POST /api/v1/payments/quotations/<quotation_id>/send-email/
    Send quotation via email
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, quotation_id):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        try:
            quotation = ClientQuotation.objects.get(id=quotation_id)
            
            # Send email
            success = self._send_email(quotation)
            
            if success:
                quotation.email_sent = True
                quotation.email_sent_at = timezone.now()
                quotation.status = QuotationStatus.SENT
                quotation.save()
                
                QuotationActivityLog.objects.create(
                    quotation=quotation,
                    activity_type='email_sent',
                    description=f'Quotation sent to {quotation.client_email}',
                    performed_by=request.user,
                )
                
                return Response({
                    'success': True,
                    'message': f'Quotation sent to {quotation.client_email}'
                })
            else:
                return Response({'error': 'Failed to send email'}, status=500)
                
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)
    
    def _send_email(self, quotation):
        """Send quotation email"""
        try:
            from django.core.mail import send_mail
            from django.template.loader import render_to_string
            
            subject = f'Quotation {quotation.quotation_number} - {quotation.training_item_name}'
            
            # Build email context
            context = {
                'quotation': quotation,
                'training_item': quotation.training_item_name,
                'payment_link': quotation.smatpay_payment_link,
                'company_name': 'Hosi Academy',
            }
            
            # HTML email
            html_message = render_to_string('emails/quotation.html', context)
            
            # Plain text fallback
            plain_message = f"""
Dear {quotation.client_name},

Thank you for your interest in {quotation.training_item_name}.

Quotation Details:
- Quotation Number: {quotation.quotation_number}
- Training: {quotation.training_item_name}
- Total Amount: USD {quotation.total_amount}

To proceed with payment, please visit:
{quotation.smatpay_payment_link}

This quotation is valid until {quotation.expires_at.strftime('%B %d, %Y')}.

Best regards,
Hosi Academy Team
"""
            
            send_mail(
                subject=subject,
                message=plain_message,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[quotation.client_email],
                html_message=html_message,
                fail_silently=False,
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Error sending quotation email: {e}")
            return False


class SendQuotationSMSView(APIView):
    """
    POST /api/v1/payments/quotations/<quotation_id>/send-sms/
    Send quotation via SMS
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, quotation_id):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        try:
            quotation = ClientQuotation.objects.get(id=quotation_id)
            
            if not quotation.client_phone:
                return Response({'error': 'Client has no phone number'}, status=400)
            
            # Send SMS via Twilio
            success = self._send_sms(quotation)
            
            if success:
                quotation.sms_sent = True
                quotation.sms_sent_at = timezone.now()
                quotation.save()
                
                QuotationActivityLog.objects.create(
                    quotation=quotation,
                    activity_type='sms_sent',
                    description=f'Quotation sent to {quotation.client_phone}',
                    performed_by=request.user,
                )
                
                return Response({
                    'success': True,
                    'message': f'SMS sent to {quotation.client_phone}'
                })
            else:
                return Response({'error': 'Failed to send SMS'}, status=500)
                
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)
    
    def _send_sms(self, quotation):
        """Send quotation SMS via Twilio"""
        try:
            from twilio.rest import Client as TwilioClient
            
            account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', None)
            auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', None)
            messaging_service_sid = 'MG17481cdaf787ad333c48f42eec53e005'
            
            if not (account_sid and auth_token):
                logger.error("Twilio credentials not configured")
                return False
            
            client = TwilioClient(account_sid, auth_token)
            
            # Format message
            message_body = (
                f"Hi {quotation.client_name}, your Hosi Academy quotation is ready!\n\n"
                f"Quote: {quotation.quotation_number}\n"
                f"Training: {quotation.training_item_name[:30]}...\n"
                f"Amount: USD {quotation.total_amount}\n\n"
                f"Pay now: {quotation.smatpay_payment_link[:60]}...\n\n"
                f"Valid until {quotation.expires_at.strftime('%d %b %Y')}"
            )
            
            # Normalize phone number
            phone = quotation.client_phone.strip()
            if not phone.startswith('+'):
                # Add country code based on client_country
                country_prefixes = {
                    'ZA': '+27', 'KE': '+254', 'ZW': '+263',
                    'ZM': '+260', 'NG': '+234', 'GH': '+233'
                }
                prefix = country_prefixes.get(quotation.client_country, '+263')
                phone = prefix + phone.lstrip('0')
            
            msg = client.messages.create(
                body=message_body,
                messaging_service_sid=messaging_service_sid,
                to=phone,
            )
            
            logger.info(f"Quotation SMS sent to {phone}, SID: {msg.sid}")
            return True
            
        except Exception as e:
            logger.error(f"Error sending quotation SMS: {e}")
            return False


class SendQuotationBothView(APIView):
    """
    POST /api/v1/payments/quotations/<quotation_id>/send-both/
    Send quotation via both Email and SMS
    """
    permission_classes = [IsAuthenticated]
    
    def post(self, request, quotation_id):
        if not is_payment_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)
        
        results = {'email': False, 'sms': False}
        
        try:
            quotation = ClientQuotation.objects.get(id=quotation_id)
            
            # Send email
            email_view = SendQuotationEmailView()
            try:
                email_view._send_email(quotation)
                quotation.email_sent = True
                quotation.email_sent_at = timezone.now()
                results['email'] = True
            except Exception as e:
                logger.error(f"Email send failed: {e}")
            
            # Send SMS if phone available
            if quotation.client_phone:
                sms_view = SendQuotationSMSView()
                try:
                    sms_view._send_sms(quotation)
                    quotation.sms_sent = True
                    quotation.sms_sent_at = timezone.now()
                    results['sms'] = True
                except Exception as e:
                    logger.error(f"SMS send failed: {e}")
            
            # Update status
            quotation.status = QuotationStatus.SENT
            quotation.save()
            
            return Response({
                'success': True,
                'results': results,
                'message': 'Quotation sent via available channels'
            })
            
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)


# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC QUOTATION VIEW (for clients)
# ═══════════════════════════════════════════════════════════════════════════════

class PublicQuotationView(APIView):
    """
    GET /api/v1/payments/quotations/public/<quotation_number>/
    Public endpoint for clients to view their quotation (no auth required)
    """
    permission_classes = []
    
    def get(self, request, quotation_number):
        try:
            quotation = ClientQuotation.objects.get(quotation_number=quotation_number)
            
            # Track view
            quotation.viewed_count += 1
            if not quotation.viewed_at:
                quotation.viewed_at = timezone.now()
            quotation.save()
            
            # Log activity
            QuotationActivityLog.objects.create(
                quotation=quotation,
                activity_type='viewed',
                description=f'Quotation viewed from IP {request.META.get("REMOTE_ADDR")}',
                ip_address=request.META.get('REMOTE_ADDR'),
                user_agent=request.META.get('HTTP_USER_AGENT', '')[:255],
            )
            
            return Response({
                'quotation_number': quotation.quotation_number,
                'client_name': quotation.client_name,
                'training_type': quotation.training_type,
                'training_item': quotation.training_item_name,
                'pricing': {
                    'base_price': str(quotation.base_price),
                    'quantity': quotation.quantity,
                    'discount_percentage': str(quotation.discount_percentage),
                    'discount_amount': str(quotation.discount_amount),
                    'total_amount': str(quotation.total_amount),
                    'local_amount': str(quotation.local_amount),
                    'local_currency': quotation.local_currency,
                },
                'description': quotation.description,
                'expires_at': quotation.expires_at.isoformat() if quotation.expires_at else None,
                'is_expired': quotation.is_expired,
                'days_until_expiry': quotation.days_until_expiry,
                'smatpay_link': quotation.smatpay_payment_link if not quotation.is_expired else None,
                'status': quotation.status,
            })
            
        except ClientQuotation.DoesNotExist:
            return Response({'error': 'Quotation not found'}, status=404)
