# apps/learner_portal/views.py
import logging
from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.shortcuts import get_object_or_404
from django.db.models import Q, Count, Sum
from django.utils import timezone
from django.contrib.contenttypes.models import ContentType

from .models import (
    StudentProfile, Wishlist, CourseCart, CourseCartItem,
    CourseProvider, CourseCatalogItem
)
from apps.payments.models import Order
import uuid
from .serializers import (
    LearnerProfileSerializer, WishlistSerializer,
    CourseCartSerializer, CourseCartItemSerializer,
    AddToCartSerializer, CourseProviderSerializer,
    CourseCatalogItemSerializer, CountrySerializer,
    StateSerializer, CitySerializer
)
from apps.localization.models import Country, State, City


class LearnerProfileViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing learner profiles and previous payment details
    """
    serializer_class = LearnerProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Filter to current user's profile"""
        return StudentProfile.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current user's profile"""
        profile, created = StudentProfile.objects.get_or_create(user=request.user)
        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def update_company_details(self, request):
        """Update company details after successful payment"""
        profile, created = StudentProfile.objects.get_or_create(user=request.user)

        company_details = request.data.get('company_details', {})
        profile.update_company_details(company_details)

        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def company_details(self, request):
        """Get previous company details for reuse"""
        try:
            profile = StudentProfile.objects.get(user=request.user)
            if profile.has_company_payment_history:
                return Response({
                    'has_history': True,
                    'details': profile.get_company_details()
                })
            return Response({'has_history': False})
        except StudentProfile.DoesNotExist:
            return Response({'has_history': False})

    @action(detail=False, methods=['patch', 'post'], url_path='update')
    def update_profile(self, request):
        """Update student profile personal data (cascade from enrollment form changes)"""
        profile, created = StudentProfile.objects.get_or_create(user=request.user)

        UPDATABLE_FIELDS = [
            'phone', 'id_number', 'date_of_birth', 'gender',
            'address', 'postal_code',
            'employer', 'job_title', 'employment_status',
            'highest_qualification', 'qualification_institution', 'qualification_year',
            'race', 'disability', 'nationality',
            'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relationship',
            'bank_name', 'bank_account_number', 'bank_branch_code',
            'bank_account_type', 'bank_account_holder_name',
            'mobile_money_number', 'mobile_money_provider',
            'preferred_payment_provider', 'preferred_payment_method',
            'last_used_company_name', 'last_used_company_email',
            'last_used_company_phone', 'last_used_company_address',
            'last_used_vat_number',
        ]

        changed = False
        for field in UPDATABLE_FIELDS:
            if field in request.data and request.data[field] not in (None, ''):
                setattr(profile, field, request.data[field])
                changed = True

        # Handle FK location fields
        for fk_field, model_class in [('country', 'localization.Country'), ('state', 'localization.State'), ('city', 'localization.City')]:
            if fk_field in request.data and request.data[fk_field]:
                try:
                    from django.apps import apps
                    app_label, model_name = model_class.split('.')
                    Model = apps.get_model(app_label, model_name)
                    obj = Model.objects.get(id=request.data[fk_field])
                    setattr(profile, fk_field, obj)
                    setattr(profile, f'preferred_{fk_field}', obj)
                    changed = True
                except Exception:
                    pass

        if changed:
            profile.save()

        serializer = self.get_serializer(profile)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def check_existing_student(self, request):
        """
        Check if user is an existing student with prior enrollments.
        Returns student data if they exist, used to skip personal info collection.
        """
        from apps.payments.models import Enrollment
        
        try:
            profile = StudentProfile.objects.get(user=request.user)
            
            # Check if user has any completed enrollments
            has_enrollments = Enrollment.objects.filter(
                user=request.user,
                status__in=['enrolled', 'completed']
            ).exists()
            
            if has_enrollments:
                return Response({
                    'is_existing_student': True,
                    'student_data': {
                        'name': request.user.get_full_name() or request.user.username,
                        'email': request.user.email,
                        'phone': profile.phone or '',
                        'country': profile.country or '',
                        'city': profile.city or '',
                        'has_company_history': profile.has_company_payment_history,
                    }
                })
            else:
                return Response({
                    'is_existing_student': False,
                    'student_data': None
                })
        except StudentProfile.DoesNotExist:
            return Response({
                'is_existing_student': False,
                'student_data': None
            })


class WishlistViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing wishlist items and marketing lead tracking
    """
    serializer_class = WishlistSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        """Allow guest users to check wishlist status without 403"""
        if self.action in ['list', 'unconverted']:
            return [AllowAny()]
        return super().get_permissions()

    def get_queryset(self):
        """Filter to current user's wishlist"""
        if not self.request.user.is_authenticated:
            return Wishlist.objects.none()
        return Wishlist.objects.filter(user=self.request.user).order_by('-created_at')

    def perform_create(self, serializer):
        """Auto-assign current user"""
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def move_to_cart(self, request, pk=None):
        """Move wishlist item to cart"""
        wishlist_item = self.get_object()

        # Get or create active cart
        cart, created = CourseCart.objects.get_or_create(
            user=request.user,
            status='active',
            defaults={'total_courses': 0, 'total_amount': 0}
        )

        # Check if already in cart
        existing_item = CourseCartItem.objects.filter(
            cart=cart,
            content_type=wishlist_item.content_type,
            object_id=wishlist_item.object_id
        ).first()

        if existing_item:
            return Response(
                {'error': 'Course already in cart'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get price from course
        course = wishlist_item.course
        price = getattr(course, 'price', 0)

        # Create cart item
        cart_item = CourseCartItem.objects.create(
            cart=cart,
            content_type=wishlist_item.content_type,
            object_id=wishlist_item.object_id,
            training_type=wishlist_item.training_type,
            price=price,
            added_from_wishlist=True
        )

        # Mark wishlist item as converted
        wishlist_item.converted_to_cart = True
        wishlist_item.save()

        # Recalculate cart totals
        cart.recalculate_totals()

        return Response({
            'message': 'Course moved to cart',
            'cart_item_id': cart_item.id,
            'cart_id': cart.id
        })

    @action(detail=False, methods=['get'])
    def by_training_type(self, request):
        """Get wishlist items grouped by training type"""
        training_type = request.query_params.get('type')
        queryset = self.get_queryset()

        if training_type:
            queryset = queryset.filter(training_type=training_type)

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def unconverted(self, request):
        """Get wishlist items not yet converted to cart or enrollment"""
        queryset = self.get_queryset().filter(
            converted_to_cart=False,
            converted_to_enrollment=False
        )
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)


class CourseCartViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing course cart and checkout
    """
    serializer_class = CourseCartSerializer
    permission_classes = [IsAuthenticated]

    def get_permissions(self):
        """Allow guest users to check active cart status without 403"""
        if self.action == 'active':
            return [AllowAny()]
        return super().get_permissions()


    def get_queryset(self):
        """Filter to current user's carts"""
        if not self.request.user.is_authenticated:
            return CourseCart.objects.none()
        return CourseCart.objects.filter(user=self.request.user).order_by('-created_at')

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get or create active cart"""
        if not request.user.is_authenticated:
            # Return a mock empty cart structure for guests
            return Response({
                'id': None,
                'status': 'active',
                'total_courses': 0,
                'total_amount': "0.00",
                'currency': 'USD',
                'items': [],
                'is_guest': True
            })

        try:
            cart, created = CourseCart.objects.get_or_create(
                user=request.user,
                status='active',
                defaults={'total_courses': 0, 'total_amount': 0}
            )
            serializer = self.get_serializer(cart)
            return Response(serializer.data)
        except Exception as e:
            logger = logging.getLogger(__name__)
            logger.error(f"Error getting active cart: {str(e)}", exc_info=True)
            return Response(
                {'error': 'Failed to retrieve cart', 'details': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @action(detail=True, methods=['post'])
    def add_item(self, request, pk=None):
        """Add course to cart (drag-and-drop from catalog)"""
        cart = self.get_object()

        serializer = AddToCartSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        # Get validated course and content type from context
        course = serializer.context['course']
        content_type = serializer.context['content_type']

        # Check if already in cart
        existing_item = CourseCartItem.objects.filter(
            cart=cart,
            content_type=content_type,
            object_id=serializer.validated_data['object_id']
        ).exists()

        if existing_item:
            return Response(
                {'error': 'Course already in cart'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Get price from course
        price = getattr(course, 'price', 0)

        # Create cart item
        cart_item = CourseCartItem.objects.create(
            cart=cart,
            content_type=content_type,
            object_id=serializer.validated_data['object_id'],
            training_type=serializer.validated_data['training_type'],
            price=price,
            added_from_wishlist=serializer.validated_data.get('from_wishlist', False)
        )

        # If from wishlist, mark wishlist item as converted
        if serializer.validated_data.get('from_wishlist'):
            Wishlist.objects.filter(
                user=request.user,
                content_type=content_type,
                object_id=serializer.validated_data['object_id']
            ).update(converted_to_cart=True)

        # Recalculate cart totals
        cart.recalculate_totals()

        serializer = CourseCartItemSerializer(cart_item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['delete'])
    def remove_item(self, request, pk=None):
        """Remove course from cart"""
        cart = self.get_object()
        item_id = request.data.get('item_id')

        try:
            cart_item = CourseCartItem.objects.get(id=item_id, cart=cart)
            cart_item.delete()
            cart.recalculate_totals()
            return Response({'message': 'Item removed from cart'})
        except CourseCartItem.DoesNotExist:
            return Response(
                {'error': 'Cart item not found'},
                status=status.HTTP_404_NOT_FOUND
            )

    @action(detail=True, methods=['post'])
    def clear(self, request, pk=None):
        """Clear all items from cart"""
        cart = self.get_object()
        cart.items.all().delete()
        cart.recalculate_totals()
        return Response({'message': 'Cart cleared'})

    @action(detail=True, methods=['post'])
    def checkout(self, request, pk=None):
        """Initiate checkout process"""
        cart = self.get_object()

        if cart.items.count() == 0:
            return Response(
                {'error': 'Cannot checkout empty cart'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Update cart status
        cart.status = 'checkout'
        cart.save()

        # Get company details preference
        use_previous_details = request.data.get('use_previous_company_details', False)
        is_corporate = request.data.get('is_corporate_enrollment', False)

        cart.use_previous_company_details = use_previous_details
        cart.is_corporate_enrollment = is_corporate
        cart.save()

        # Create Order for payment system
        course_ids = list(cart.items.values_list('object_id', flat=True))
        
        order = Order.objects.create(
            user=request.user,
            tracking=f"CART-{uuid.uuid4().hex[:12].upper()}",
            amount=cart.total_amount,
            currency=cart.currency,
            status='pending',
            metadata={
                'cart_id': cart.id,
                'enrollment_type': 'custom_selection',
                'is_corporate': is_corporate,
                'use_previous_details': use_previous_details,
                'course_ids': course_ids,
                'total_courses': cart.total_courses,
            }
        )

        return Response({
            'message': 'Cart ready for checkout',
            'cart_id': cart.id,
            'order_id': order.tracking,
            'total_amount': str(cart.total_amount),
            'currency': cart.currency,
            'total_courses': cart.total_courses,
            'proceed_to_payment': True
        })


class CourseCatalogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for browsing course catalog (custom selection enrollment)
    Only shows courses from active providers
    """
    serializer_class = CourseCatalogItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get active courses from active providers"""
        return CourseCatalogItem.objects.filter(
            is_active=True,
            provider__is_active=True
        ).select_related('provider', 'content_type').order_by('display_order', '-is_featured')

    def list(self, request):
        """List catalog with filters"""
        queryset = self.get_queryset()

        # Filter by training type
        training_type = request.query_params.get('training_type')
        if training_type:
            queryset = queryset.filter(training_type=training_type)

        # Filter by provider
        provider_id = request.query_params.get('provider')
        if provider_id:
            queryset = queryset.filter(provider_id=provider_id)

        # Filter by featured
        featured = request.query_params.get('featured')
        if featured == 'true':
            queryset = queryset.filter(is_featured=True)

        # Search by title
        search = request.query_params.get('search')
        if search:
            queryset = queryset.filter(
                Q(title__icontains=search) |
                Q(description__icontains=search)
            )

        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_training_type(self, request):
        """Get catalog items grouped by training type"""
        training_type = request.query_params.get('type')
        if not training_type:
            return Response(
                {'error': 'training_type parameter required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        queryset = self.get_queryset().filter(training_type=training_type)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def add_to_wishlist(self, request, pk=None):
        """Add catalog item to wishlist"""
        catalog_item = self.get_object()

        # Check if already in wishlist
        existing = Wishlist.objects.filter(
            user=request.user,
            content_type=catalog_item.content_type,
            object_id=catalog_item.object_id
        ).exists()

        if existing:
            return Response(
                {'error': 'Course already in wishlist'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create wishlist item
        wishlist_item = Wishlist.objects.create(
            user=request.user,
            content_type=catalog_item.content_type,
            object_id=catalog_item.object_id,
            training_type=catalog_item.training_type,
            interest_level='medium',
            notes=request.data.get('reason', '')  # specific reason
        )

        # Update catalog item stats
        catalog_item.total_wishlist_adds += 1
        catalog_item.save()

        serializer = WishlistSerializer(wishlist_item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def add_to_cart(self, request, pk=None):
        """Add catalog item directly to cart (drag-and-drop)"""
        catalog_item = self.get_object()

        # Get or create active cart
        cart, created = CourseCart.objects.get_or_create(
            user=request.user,
            status='active',
            defaults={'total_courses': 0, 'total_amount': 0}
        )

        # Check if already in cart
        existing = CourseCartItem.objects.filter(
            cart=cart,
            content_type=catalog_item.content_type,
            object_id=catalog_item.object_id
        ).exists()

        if existing:
            return Response(
                {'error': 'Course already in cart'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Create cart item
        cart_item = CourseCartItem.objects.create(
            cart=cart,
            content_type=catalog_item.content_type,
            object_id=catalog_item.object_id,
            training_type=catalog_item.training_type,
            price=catalog_item.price
        )

        # Recalculate cart totals
        cart.recalculate_totals()

        serializer = CourseCartItemSerializer(cart_item)
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class CourseProviderViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for browsing course providers
    Only shows active providers in custom enrollment catalog
    """
    serializer_class = CourseProviderSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        """Get only active providers"""
        return CourseProvider.objects.filter(is_active=True).order_by('display_order')

    @action(detail=True, methods=['get'])
    def courses(self, request, pk=None):
        """Get all courses from this provider"""
        provider = self.get_object()
        catalog_items = CourseCatalogItem.objects.filter(
            provider=provider,
            is_active=True
        ).order_by('display_order')

        serializer = CourseCatalogItemSerializer(catalog_items, many=True)
        return Response(serializer.data)


# Cascading Dropdown Views
class CountryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for countries in cascading dropdown
    """
    serializer_class = CountrySerializer
    permission_classes = [AllowAny]
    queryset = Country.objects.all().order_by('name')

    def get_serializer_context(self):
        """Add flag to include states if requested"""
        context = super().get_serializer_context()
        context['include_states'] = self.request.query_params.get('include_states') == 'true'
        return context


class StateViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for states in cascading dropdown
    Filter by country
    """
    serializer_class = StateSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        """Filter by country if provided"""
        queryset = State.objects.all().order_by('name')

        country_id = self.request.query_params.get('country')
        country_code = self.request.query_params.get('country_code')

        if country_id:
            queryset = queryset.filter(country_id=country_id)
        elif country_code:
            queryset = queryset.filter(country__code=country_code)

        return queryset

    def get_serializer_context(self):
        """Add flag to include cities if requested"""
        context = super().get_serializer_context()
        context['include_cities'] = self.request.query_params.get('include_cities') == 'true'
        return context


class CityViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet for cities in cascading dropdown
    Filter by state
    """
    serializer_class = CitySerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        """Filter by state if provided"""
        queryset = City.objects.all().order_by('name')

        state_id = self.request.query_params.get('state')
        country_id = self.request.query_params.get('country')

        if state_id:
            queryset = queryset.filter(state_id=state_id)
        elif country_id:
            queryset = queryset.filter(state__country_id=country_id)

        return queryset


@api_view(['GET'])
@permission_classes([AllowAny])
def get_content_types(request):
    """
    Return content type IDs for course models.

    This endpoint helps the frontend determine the correct content_type_id
    to use when adding items to cart/wishlist.

    Returns:
        {
            "masterclass": 12,
            "learnershipprogramme": 13,
            "aicertscourse": 14,
            "offering": 15,
            "course": 16
        }
    """
    # Each tuple: (response_key, model_name, app_label)
    # Specify app_label explicitly to avoid MultipleObjectsReturned when
    # the same model name exists in multiple apps (e.g. 'course', 'aicertscourse').
    model_lookup = [
        ('masterclass',             'masterclass',          'masterclasses'),
        ('learnershipprogramme',    'learnershipprogramme', 'learnerships'),
        ('aicertscourse',           'aicertscourse',        'aicerts_courses'),
        ('industry_aicertscourse',  'aicertscourse',        'industry_based_training'),
        ('offering',                'offering',             'industry_based_training'),
        ('course',                  'course',               'courses'),
    ]

    content_types = {}
    for key, model_name, app_label in model_lookup:
        try:
            ct = ContentType.objects.get(app_label=app_label, model=model_name)
            content_types[key] = ct.id
        except ContentType.DoesNotExist:
            content_types[key] = None

    return Response(content_types)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_marketing_analytics(request):
    """
    Sales & Marketing analytics endpoint.

    Returns:
    - top_wishlist: courses sorted by wishlist count (highest first)
    - top_sales: courses sorted by enrollment count (highest first)
    - low_sales: courses with lowest enrollment (but at least 1)
    - wishlist_summary: total wishlist items, conversion rate
    """
    limit = int(request.query_params.get('limit', 10))

    # ── Wishlist analytics: count per course using Wishlist table ──
    wishlist_counts = (
        Wishlist.objects
        .values('object_id', 'training_type', 'content_type_id')
        .annotate(wishlist_count=Count('id'))
        .order_by('-wishlist_count')
    )

    # Build top wishlist list with title lookup
    top_wishlist = []
    seen_ids = set()
    for row in wishlist_counts:
        if len(top_wishlist) >= limit:
            break
        key = (row['content_type_id'], row['object_id'])
        if key in seen_ids:
            continue
        seen_ids.add(key)
        try:
            ct = ContentType.objects.get(id=row['content_type_id'])
            obj = ct.get_object_for_this_type(pk=row['object_id'])
            title = getattr(obj, 'title', getattr(obj, 'name', str(obj)))
        except Exception:
            title = f"[{row['training_type']}] ID {row['object_id']}"
        top_wishlist.append({
            'title': title,
            'training_type': row['training_type'],
            'object_id': row['object_id'],
            'wishlist_count': row['wishlist_count'],
            'converted_count': Wishlist.objects.filter(
                content_type_id=row['content_type_id'],
                object_id=row['object_id'],
                converted_to_cart=True,
            ).count(),
        })

    # ── Sales analytics: count enrollments per course via Enrollment model ──
    from apps.payments.models import Enrollment

    enrollment_counts = (
        Enrollment.objects
        .values('content_type_id', 'object_id', 'enrollment_type')
        .annotate(enrollment_count=Count('id'))
        .order_by('-enrollment_count')
    )

    top_sales = []
    seen_enroll = set()
    for row in list(enrollment_counts):
        if len(top_sales) >= limit * 2:
            break
        key = (row['content_type_id'], row['object_id'])
        if key in seen_enroll:
            continue
        seen_enroll.add(key)
        title = f"[{row.get('enrollment_type', 'unknown')}] ID {row['object_id']}"
        try:
            ct = ContentType.objects.get(id=row['content_type_id'])
            obj = ct.get_object_for_this_type(pk=row['object_id'])
            title = getattr(obj, 'title', getattr(obj, 'name', title))
        except Exception:
            pass
        top_sales.append({
            'object_id': row['object_id'],
            'training_type': row.get('enrollment_type', 'unknown'),
            'enrollment_count': row['enrollment_count'],
            'title': title,
        })

    # Reverse for lowest sales (exclude zero enrollments from top_sales)
    low_sales = sorted(
        [e for e in top_sales if e['enrollment_count'] > 0],
        key=lambda x: x['enrollment_count']
    )[:limit]

    # ── Wishlist summary stats ──
    total_wishlist = Wishlist.objects.count()
    converted_to_cart = Wishlist.objects.filter(converted_to_cart=True).count()
    converted_to_enrollment = Wishlist.objects.filter(converted_to_enrollment=True).count()
    conversion_rate = round(
        (converted_to_enrollment / total_wishlist * 100) if total_wishlist > 0 else 0, 1
    )

    # Training type breakdown for wishlist
    type_breakdown = list(
        Wishlist.objects
        .values('training_type')
        .annotate(count=Count('id'))
        .order_by('-count')
    )

    return Response({
        'top_wishlist': top_wishlist,
        'top_sales': top_sales[:limit],
        'low_sales': low_sales,
        'wishlist_summary': {
            'total': total_wishlist,
            'converted_to_cart': converted_to_cart,
            'converted_to_enrollment': converted_to_enrollment,
            'conversion_rate_percent': conversion_rate,
            'by_training_type': type_breakdown,
        },
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def student_dashboard(request):
    """
    Student dashboard data: enrolled courses, messages, instructors.
    GET /api/v1/student-portal/dashboard/
    """
    from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme
    from apps.communication.models import Message as CommMessage, ChatRoom
    from apps.aicerts_integration.models import AICertsEnrollment
    from apps.enrollments.models import ProvisionalEnrollment
    from apps.masterclasses.models import Masterclass
    from apps.facilitators.models import CourseAssignment, FacilitatorProfile
    from apps.communication.services import ChatRoomService

    user = request.user

    # ===== LEARNERSHIP ENROLLMENTS =====
    enrollments = LearnershipEnrollment.objects.filter(
        user=user, active=True
    ).select_related('programme')

    learnership_courses = []
    instructor_ids = set()

    for enr in enrollments:
        lp = enr.programme
        learnership_courses.append({
            'id': lp.id,
            'title': lp.title,
            'description': lp.description if hasattr(lp, 'description') else '',
            'active': lp.active,
            'enrolled_at': enr.enrolled_at.isoformat() if enr.enrolled_at else None,
            'type': 'learnership',
        })

        # Find instructor for this course
        try:
            ctype = ContentType.objects.get_for_model(lp)
            assignment = CourseAssignment.objects.filter(
                content_type=ctype,
                object_id=lp.id,
                status__in=['assigned', 'ongoing']
            ).select_related('facilitator__user').first()

            if assignment:
                instructor_ids.add(assignment.facilitator.user_id)
        except Exception:
            pass

    # ===== MASTERCLASS ENROLLMENTS =====
    masterclass_enrollments = ProvisionalEnrollment.objects.filter(
        user=user,
        enrollment_type='masterclass',
        status__in=['confirmed', 'provisional']
    ).select_related('payment_transaction')

    masterclass_courses = []
    for enr in masterclass_enrollments:
        mc_id = enr.metadata.get('masterclass_id')
        if mc_id:
            try:
                mc = Masterclass.objects.get(id=mc_id)
                masterclass_courses.append({
                    'id': mc.id,
                    'title': mc.title,
                    'description': mc.description or '',
                    'location': f'{mc.city}, {mc.country_name}' if mc.city else mc.country_name,
                    'start_date': str(mc.start_date) if mc.start_date else None,
                    'end_date': str(mc.end_date) if mc.end_date else None,
                    'status': mc.status,
                    'enrolled_at': enr.created_at.isoformat() if enr.created_at else None,
                    'type': 'masterclass',
                    'enrollment_status': enr.status,
                    'payment_status': 'paid' if enr.payment_transaction else 'pending',
                })
                # All masterclass instructors are the user's instructors
                facilitators = FacilitatorProfile.objects.select_related('user').all()
                for f in facilitators:
                    instructor_ids.add(f.user_id)
            except Masterclass.DoesNotExist:
                pass

    # AICerts enrollments
    from apps.aicerts_integration.services import SSOService
    aicerts_courses = []
    aicerts_enrollments = AICertsEnrollment.objects.filter(user=user).select_related('course')
    for enr in aicerts_enrollments:
        # Generate SSO URL for course access
        launch_url = None
        if enr.aicerts_enrollment_status == 'enrolled' and user.aicerts_user_id:
            try:
                launch_url = SSOService.generate_sso_url(
                    email=user.email,
                    course_id=enr.course.lms_course_id
                )
            except Exception:
                pass  # SSO URL generation failed, but still show the course
        aicerts_courses.append({
            'id': enr.course.id if enr.course else enr.id,
            'title': enr.course.title if enr.course else 'AICerts Course',
            'status': enr.aicerts_enrollment_status,
            'progress': float(enr.progress_percentage) if enr.progress_percentage else 0,
            'launch_url': launch_url,
            'type': 'aicerts',
            'lms_course_id': enr.course.lms_course_id if enr.course else None,
            'thumbnail_url': getattr(enr.course, 'feature_image_url', None) if enr.course else None,
            'completed_at': enr.completed_at.isoformat() if enr.completed_at else None,
            'certificate_issued': enr.certificate_issued_at is not None,
        })

    # Get REAL instructors - instructors of enrolled courses
    instructors_data = []
    instructors = User.objects.filter(
        id__in=instructor_ids
    ).select_related('facilitator_profile')
    
    for instructor in instructors:
        # Ensure chat room exists
        ChatRoomService.get_or_create_instructor_student_chat(
            instructor=instructor,
            student=user
        )
        
        # Get chat room
        chat_room = ChatRoom.objects.filter(
            participants__user=instructor,
            chat_type='one_on_one'
        ).filter(
            participants__user=user
        ).first()
        
        # Get unread messages
        unread_count = 0
        last_msg = None
        if chat_room:
            unread_count = CommMessage.objects.filter(
                chat_room=chat_room,
                receiver=user,
                seen=False
            ).count()
            last_msg = chat_room.last_message
        
        instructors_data.append({
            'id': instructor.id,
            'name': instructor.name or (instructor.first_name + ' ' + instructor.last_name).strip() or instructor.email,
            'email': instructor.email,
            'role': 'instructor',
            'chat_room_id': chat_room.id if chat_room else None,
            'unread_count': unread_count,
            'last_message': last_msg.message[:80] if last_msg else None,
            'last_message_at': last_msg.created_at.isoformat() if last_msg else None,
            'last_message_from_me': last_msg.sender_id == user.id if last_msg else False,
        })

    # Messages (all chat rooms)
    my_rooms = ChatRoom.objects.filter(
        participants__user=user, chat_type='one_on_one'
    ).prefetch_related('participants__user', 'last_message')

    messages_data = []
    unread_total = 0
    for room in my_rooms:
        other = room.participants.exclude(user=user).select_related('user').first()
        if not other:
            continue
        other_user = other.user
        unread = CommMessage.objects.filter(
            chat_room=room, receiver=user, seen=False
        ).count()
        unread_total += unread
        last_msg = room.last_message
        messages_data.append({
            'chat_room_id': room.id,
            'contact_id': other_user.id,
            'contact_name': other_user.name or (other_user.first_name + ' ' + other_user.last_name).strip() or other_user.email,
            'contact_email': other_user.email,
            'contact_role': 'instructor' if getattr(other_user, 'role_id', 3) == 2 else 'student',
            'unread_count': unread,
            'last_message': last_msg.message[:80] if last_msg else None,
            'last_message_at': last_msg.created_at.isoformat() if last_msg else None,
            'last_message_from_me': last_msg.sender_id == user.id if last_msg else False,
        })

    return Response({
        'user': {
            'id': user.id,
            'name': user.name or (user.first_name + ' ' + user.last_name).strip() or user.email,
            'email': user.email,
            'role_id': getattr(user, 'role_id', 3),
        },
        'stats': {
            'courses_enrolled': len(learnership_courses) + len(aicerts_courses) + len(masterclass_courses),
            'learnerships': len(learnership_courses),
            'aicerts_courses': len(aicerts_courses),
            'masterclasses': len(masterclass_courses),
            'instructors_count': len(instructors_data),
            'unread_messages': unread_total,
        },
        'learnership_courses': learnership_courses,
        'aicerts_courses': aicerts_courses,
        'masterclass_courses': masterclass_courses,
        'instructors': instructors_data,
        'messages': messages_data,
    })
