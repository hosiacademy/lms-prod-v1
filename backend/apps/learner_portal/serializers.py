from rest_framework import serializers
from django.contrib.contenttypes.models import ContentType
from .models import (
    StudentProfile, Wishlist, CourseCart, CourseCartItem,
    CourseProvider, CourseCatalogItem
)
from apps.localization.models import Country, State, City
from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField, FormattedPriceField


class LearnerProfileSerializer(serializers.ModelSerializer):
    """Serializer for learner profile with all personal and payment details"""

    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_full_name = serializers.CharField(source='user.get_full_name', read_only=True)

    preferred_country_name = serializers.CharField(source='preferred_country.name', read_only=True)
    preferred_state_name = serializers.CharField(source='preferred_state.name', read_only=True)
    preferred_city_name = serializers.CharField(source='preferred_city.name', read_only=True)

    country_name = serializers.CharField(source='country.name', read_only=True)
    state_name = serializers.CharField(source='state.name', read_only=True)
    city_name = serializers.CharField(source='city.name', read_only=True)

    company_details = serializers.SerializerMethodField()

    class Meta:
        model = StudentProfile
        fields = [
            'id', 'user', 'user_email', 'user_full_name',
            # Personal identification
            'phone', 'id_number', 'date_of_birth', 'gender',
            # Address
            'address', 'postal_code',
            'country', 'country_name', 'state', 'state_name', 'city', 'city_name',
            # Employment & Education
            'employer', 'job_title', 'employment_status',
            'highest_qualification', 'qualification_institution', 'qualification_year',
            # Demographics
            'race', 'disability', 'nationality',
            # Emergency contact
            'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relationship',
            # Banking
            'bank_name', 'bank_account_number', 'bank_branch_code',
            'bank_account_type', 'bank_account_holder_name',
            # Mobile money
            'mobile_money_number', 'mobile_money_provider',
            # Company history
            'last_used_company_name', 'last_used_company_email',
            'last_used_company_phone', 'last_used_company_address',
            'last_used_vat_number', 'has_company_payment_history',
            # Location preferences
            'preferred_country', 'preferred_country_name',
            'preferred_state', 'preferred_state_name',
            'preferred_city', 'preferred_city_name',
            # Payment preferences
            'preferred_payment_provider', 'preferred_payment_method',
            'company_details', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'has_company_payment_history', 'created_at', 'updated_at']

    def get_company_details(self, obj):
        """Get formatted company details for reuse prompt"""
        if obj.has_company_payment_history:
            return obj.get_company_details()
        return None


class WishlistSerializer(serializers.ModelSerializer):
    """Serializer for wishlist items with course details"""

    user_email = serializers.EmailField(source='user.email', read_only=True)
    course_title = serializers.SerializerMethodField()
    course_details = serializers.SerializerMethodField()
    days_in_wishlist = serializers.SerializerMethodField()

    class Meta:
        model = Wishlist
        fields = [
            'id', 'user', 'user_email', 'content_type', 'object_id',
            'course_title', 'course_details', 'training_type',
            'interest_level', 'intended_start', 'notes',
            'marketing_contacted', 'marketing_contacted_at', 'marketing_notes',
            'contacted_by', 'converted_to_cart', 'converted_to_enrollment',
            'days_in_wishlist', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'user', 'marketing_contacted', 'marketing_contacted_at',
            'contacted_by', 'converted_to_cart', 'converted_to_enrollment',
            'created_at', 'updated_at'
        ]

    def get_course_title(self, obj):
        """Get the title from the generic course"""
        if obj.course:
            return getattr(obj.course, 'title', str(obj.course))
        return 'Unknown Course'

    def get_course_details(self, obj):
        """Get course details for display"""
        if obj.course:
            return {
                'id': obj.object_id,
                'type': obj.content_type.model,
                'title': getattr(obj.course, 'title', ''),
                'description': getattr(obj.course, 'description', ''),
                'price': str(getattr(obj.course, 'price', 0)),
                'duration': getattr(obj.course, 'duration', ''),
            }
        return None

    def get_days_in_wishlist(self, obj):
        """Calculate days since added to wishlist"""
        from django.utils import timezone
        delta = timezone.now() - obj.created_at
        return delta.days


class CourseCartItemSerializer(serializers.ModelSerializer):
    """Serializer for individual cart items"""

    course_title = serializers.SerializerMethodField()
    course_details = serializers.SerializerMethodField()
    
    # Localized Pricing (Shadowing model field)
    price = LocalizedPriceField(read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='price', read_only=True)

    class Meta:
        model = CourseCartItem
        fields = [
            'id', 'cart', 'content_type', 'object_id',
            'course_title', 'course_details', 'training_type',
            'price', 'currency', 'formatted_price',
            'prerequisites_met', 'added_from_wishlist',
            'created_at'
        ]
        read_only_fields = ['cart', 'price', 'created_at']

    def get_course_title(self, obj):
        """Get the title from the generic course"""
        try:
            if obj.course:
                return getattr(obj.course, 'title', str(obj.course))
        except Exception:
            pass
        return 'Unknown Course'

    def get_course_details(self, obj):
        """Get course details for display"""
        try:
            if obj.course:
                return {
                    'id': obj.object_id,
                    'type': obj.content_type.model,
                    'title': getattr(obj.course, 'title', ''),
                    'description': getattr(obj.course, 'description', ''),
                    'duration': getattr(obj.course, 'duration', ''),
                    'prerequisites': getattr(obj.course, 'prerequisites', []) or [],
                }
        except Exception:
            pass
        return None


class CourseCartSerializer(serializers.ModelSerializer):
    """Serializer for course cart with items"""

    items = CourseCartItemSerializer(many=True, read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    previous_company_details = serializers.SerializerMethodField()
    
    # Localized Pricing (Shadowing model field)
    total_amount = LocalizedPriceField(read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_total = FormattedPriceField(source='*', price_field='total_amount', read_only=True)

    class Meta:
        model = CourseCart
        fields = [
            'id', 'user', 'user_email', 'status',
            'use_previous_company_details', 'is_corporate_enrollment',
            'total_courses', 'total_amount', 'currency', 'formatted_total',
            'items', 'previous_company_details', 'created_at', 'updated_at'
        ]
        read_only_fields = ['user', 'total_courses', 'total_amount', 'created_at', 'updated_at']

    def get_previous_company_details(self, obj):
        """Get previous company details if available"""
        try:
            profile = StudentProfile.objects.get(user=obj.user)
            if profile.has_company_payment_history:
                return profile.get_company_details()
        except StudentProfile.DoesNotExist:
            pass
        return None


class AddToCartSerializer(serializers.Serializer):
    """Serializer for adding courses to cart"""

    content_type_id = serializers.IntegerField()
    object_id = serializers.IntegerField()
    training_type = serializers.ChoiceField(choices=[
        ('masterclass', 'Masterclass'),
        ('learnership', 'Learnership'),
        ('industry_training', 'Industry Training'),
        ('custom_selection', 'Custom Selection'),
        ('aicertscourse', 'AICerts Course'),
        ('course', 'Course'),
        ('offering', 'Industry Training'),
    ])
    from_wishlist = serializers.BooleanField(default=False)

    def validate(self, data):
        """Validate that the course exists"""
        try:
            content_type = ContentType.objects.get(id=data['content_type_id'])
            model_class = content_type.model_class()
            course = model_class.objects.get(id=data['object_id'])

            # Store the course for later use
            self.context['course'] = course
            self.context['content_type'] = content_type

        except ContentType.DoesNotExist:
            raise serializers.ValidationError("Invalid content type")
        except model_class.DoesNotExist:
            raise serializers.ValidationError("Course not found")

        return data


class CourseProviderSerializer(serializers.ModelSerializer):
    """Serializer for course providers"""

    active_courses_count = serializers.SerializerMethodField()

    class Meta:
        model = CourseProvider
        fields = [
            'id', 'name', 'code', 'description', 'logo_url',
            'is_active', 'display_order', 'active_courses_count'
        ]

    def get_active_courses_count(self, obj):
        """Count active courses from this provider"""
        return CourseCatalogItem.objects.filter(
            provider=obj,
            is_active=True
        ).count()


class CourseCatalogItemSerializer(serializers.ModelSerializer):
    """Serializer for course catalog items"""

    provider_name = serializers.CharField(source='provider.name', read_only=True)
    course_details = serializers.SerializerMethodField()
    in_wishlist = serializers.SerializerMethodField()
    in_cart = serializers.SerializerMethodField()
    
    # Localized Pricing (Shadowing model field)
    price = LocalizedPriceField(read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='price', read_only=True)

    class Meta:
        model = CourseCatalogItem
        fields = [
            'id', 'content_type', 'object_id', 'training_type',
            'provider', 'provider_name', 'title', 'description',
            'price', 'currency', 'formatted_price',
            'is_active', 'is_featured',
            'display_order', 'total_enrollments', 'total_wishlist_adds',
            'course_details', 'in_wishlist', 'in_cart'
        ]

    def get_course_details(self, obj):
        """Get full course details"""
        if obj.course:
            return {
                'id': obj.object_id,
                'type': obj.content_type.model,
                'duration': getattr(obj.course, 'duration', ''),
                'level': getattr(obj.course, 'level', ''),
                'prerequisites': getattr(obj.course, 'prerequisites', []),
                'thumbnail_url': getattr(obj.course, 'thumbnail_url', ''),
            }
        return None

    def get_in_wishlist(self, obj):
        """Check if user has this course in wishlist"""
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            return Wishlist.objects.filter(
                user=user,
                content_type=obj.content_type,
                object_id=obj.object_id
            ).exists()
        return False

    def get_in_cart(self, obj):
        """Check if user has this course in active cart"""
        user = self.context.get('request').user if self.context.get('request') else None
        if user and user.is_authenticated:
            active_cart = CourseCart.objects.filter(
                user=user,
                status='active'
            ).first()
            if active_cart:
                return CourseCartItem.objects.filter(
                    cart=active_cart,
                    content_type=obj.content_type,
                    object_id=obj.object_id
                ).exists()
        return False


# Cascading dropdown serializers
class CitySerializer(serializers.ModelSerializer):
    """Serializer for cities in cascading dropdown"""

    class Meta:
        model = City
        fields = ['id', 'name', 'state']


class StateSerializer(serializers.ModelSerializer):
    """Serializer for states in cascading dropdown"""

    cities = serializers.SerializerMethodField()

    class Meta:
        model = State
        fields = ['id', 'name', 'code', 'country', 'cities']

    def get_cities(self, obj):
        """Optionally include cities if requested"""
        if self.context.get('include_cities'):
            cities = obj.cities.all().order_by('name')
            return CitySerializer(cities, many=True).data
        return None


class CountrySerializer(serializers.ModelSerializer):
    """Serializer for countries in cascading dropdown"""

    states = serializers.SerializerMethodField()

    class Meta:
        model = Country
        fields = ['id', 'name', 'code', 'phone_code', 'states']

    def get_states(self, obj):
        """Optionally include states if requested"""
        if self.context.get('include_states'):
            states = obj.states.all().order_by('name')
            return StateSerializer(states, many=True).data
        return None
