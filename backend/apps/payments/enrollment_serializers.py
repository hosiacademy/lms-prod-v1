# apps/payments/enrollment_serializers.py
"""
Serializers for enrollment forms.
Handles individual and bulk company enrollments.
"""

from rest_framework import serializers
from django.contrib.contenttypes.models import ContentType
from django.utils import timezone
from .models import Enrollment, BulkEnrollment, EnrollmentType, EnrollmentStatus
from apps.organizations.models import Company, CompanyLearner
from apps.users.models import User


class EnrollmentSerializer(serializers.ModelSerializer):
    """
    Serializer for individual enrollment form.
    Collects all required user information before payment.
    """

    # Additional fields for form submission
    training_id = serializers.IntegerField(write_only=True, help_text="ID of the training (masterclass, learnership, etc.)")
    company_id = serializers.IntegerField(required=False, allow_null=True, help_text="Optional company ID for corporate enrollments")

    # Read-only computed fields
    enrolled_item_name = serializers.SerializerMethodField()
    payment_url = serializers.SerializerMethodField()
    is_paid = serializers.BooleanField(read_only=True)

    class Meta:
        model = Enrollment
        fields = [
            'id',
            'enrollment_code',
            'enrollment_type',
            'training_id',
            'company_id',
            'status',

            # Learner information (ALL REQUIRED)
            'learner_full_name',
            'learner_email',
            'learner_phone',
            'learner_id_number',
            'learner_address',
            'learner_city',
            'learner_country',
            'learner_postal_code',
            'learner_dob',
            'learner_gender',

            # Professional/Educational info (ALL REQUIRED)
            'current_occupation',
            'education_level',
            'institution',

            # Emergency contact (basic - kept for backward compatibility)
            'emergency_contact_name',
            'emergency_contact_phone',
            'emergency_contact_relationship',

            # Special requirements
            'dietary_requirements',
            'accessibility_needs',
            'additional_notes',

            # ===== NEW: ACADEMIC & EMPLOYMENT INFORMATION (For SETA Compliance) =====
            'highest_qualification',
            'qualification_institution',
            'qualification_year',
            'employer',
            'job_title',
            'employment_status',
            'monthly_income',
            'existing_skills',

            # ===== NEW: DEMOGRAPHICS (For SETA/Employment Equity Reporting) =====
            'race',
            'disability',
            'nationality',

            # ===== NEW: NEXT OF KIN (Comprehensive) =====
            'next_of_kin_name',
            'next_of_kin_phone',
            'next_of_kin_relationship',
            'next_of_kin_email',
            'next_of_kin_address',

            # ===== NEW: MEDICAL & ACCESSIBILITY =====
            'medical_conditions',
            'allergies',
            'medications',

            # ===== NEW: LEARNING SUPPORT =====
            'requires_learning_support',
            'learning_support_details',
            'has_previous_learnership_experience',
            'previous_learnership_details',

            # ===== NEW: DOCUMENTATION CHECKLIST =====
            'has_id_copy',
            'has_qualification_certificates',
            'has_proof_of_residence',
            'has_cv',
            'has_motivational_letter',

            # ===== NEW: PAYMENT & FUNDING =====
            'funding_source',
            'company_vat_number',
            'purchase_order_number',

            # ===== NEW: DEBIT ORDER DETAILS =====
            'requires_debit_order',
            'bank_name',
            'bank_account_number',
            'bank_branch_code',
            'bank_account_type',
            'bank_account_holder_name',

            # ===== NEW: LEGAL DECLARATIONS =====
            'data_protection_accepted',
            'certification_declaration_accepted',
            'seta_declaration_accepted',

            # ===== NEW: ADDITIONAL FIELDS =====
            'referral_source',
            'prerequisites_verified',
            'verification_notes',
            'verified_by',
            'verified_at',
            'confirmed_at',
            'dropped_out_at',

            # Pricing
            'enrollment_fee',
            'currency',
            'discount_applied',
            'final_amount',

            # Terms (basic)
            'terms_accepted',
            'terms_accepted_at',

            # Pathway linkage fields (read-only, set automatically)
            'student_id',
            'instructor_id',
            'learnership_enrollment_id',
            'masterclass_enrollment_id',
            'aicerts_enrollment_id',
            'industry_enrollment_id',

            # Read-only fields
            'enrolled_item_name',
            'payment_url',
            'is_paid',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'enrollment_code', 'status', 'created_at', 'updated_at',
            'terms_accepted_at', 'verified_by', 'verified_at',
            'confirmed_at', 'dropped_out_at',
            'student_id', 'instructor_id',
            'learnership_enrollment_id', 'masterclass_enrollment_id',
            'aicerts_enrollment_id', 'industry_enrollment_id',
        ]

    def get_enrolled_item_name(self, obj):
        """Get the name of the enrolled training"""
        try:
            item = obj.get_enrolled_item()
            if hasattr(item, 'title'):
                return item.title
            elif hasattr(item, 'name'):
                return item.name
            return str(item)
        except:
            return None

    def get_payment_url(self, obj):
        """Generate payment URL for this enrollment"""
        if obj.order:
            # Return payment gateway URL or checkout URL
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(f'/api/payments/checkout/{obj.order.tracking}/')
        return None

    def validate_training_id(self, value):
        """Validate that the training exists"""
        enrollment_type = self.initial_data.get('enrollment_type')

        # Map enrollment types to models
        model_map = {
            EnrollmentType.MASTERCLASS: ('masterclasses', 'Masterclass'),
            EnrollmentType.LEARNERSHIP: ('learnerships', 'LearnershipProgramme'),
            EnrollmentType.INDUSTRY_TRAINING: ('industry_based_training', 'AiCertsCourse'),
            EnrollmentType.ROLE_TRAINING: ('industry_based_training', 'Offering'),
        }

        if enrollment_type not in model_map:
            raise serializers.ValidationError("Invalid enrollment type")

        app_label, model_name = model_map[enrollment_type]
        try:
            content_type = ContentType.objects.get(app_label=app_label, model=model_name.lower())
            model_class = content_type.model_class()
            model_class.objects.get(pk=value)
        except ContentType.DoesNotExist:
            raise serializers.ValidationError(f"Training type not found: {model_name}")
        except model_class.DoesNotExist:
            raise serializers.ValidationError(f"Training with ID {value} not found")

        return value

    def validate_company_id(self, value):
        """Validate company exists if provided"""
        if value:
            try:
                Company.objects.get(pk=value)
            except Company.DoesNotExist:
                raise serializers.ValidationError("Company not found")
        return value

    def validate_terms_accepted(self, value):
        """Ensure terms are accepted"""
        if not value:
            raise serializers.ValidationError("You must accept the terms and conditions to proceed")
        return value

    def validate(self, data):
        """
        Cross-field validation - Enforce ALL required fields for complete user profile.
        
        For ACTUAL ENROLLMENT (production), additional SETA compliance and legal 
        declaration fields are required.
        """
        request = self.context.get('request')

        # List of REQUIRED fields for user validation (basic - always required)
        required_fields = {
            'learner_full_name': 'Full Name',
            'learner_email': 'Email Address',
            'learner_phone': 'Phone Number',
            'learner_id_number': 'ID/Passport Number',
            'learner_address': 'Physical Address',
            'learner_city': 'City',
            'learner_country': 'Country',
            'learner_postal_code': 'Postal Code',
            'learner_dob': 'Date of Birth',
            'learner_gender': 'Gender',
            'current_occupation': 'Current Occupation',
            'education_level': 'Education Level',
            'institution': 'Institution/Company',
            'emergency_contact_name': 'Emergency Contact Name',
            'emergency_contact_phone': 'Emergency Contact Phone',
            'emergency_contact_relationship': 'Emergency Contact Relationship',
        }

        # Check all required fields are provided and not empty
        missing_fields = []
        for field_name, field_label in required_fields.items():
            value = data.get(field_name)
            if not value or (isinstance(value, str) and not value.strip()):
                missing_fields.append(field_label)

        if missing_fields:
            raise serializers.ValidationError({
                'required_fields': f"The following required fields are missing or empty: {', '.join(missing_fields)}. "
                                  f"All personal information must be provided before proceeding to payment."
            })

        # ===== ACTUAL ENROLLMENT: Additional required fields for SETA compliance =====
        # These are required for actual production enrollment (not for testing)
        enrollment_type = data.get('enrollment_type')
        
        # For learnerships, additional SETA compliance fields are mandatory
        if enrollment_type == 'learnership':
            seta_required_fields = {
                'race': 'Race/Ethnicity (for employment equity reporting)',
                'nationality': 'Nationality',
                'employment_status': 'Employment Status',
                'highest_qualification': 'Highest Qualification',
                'next_of_kin_name': 'Next of Kin Name',
                'next_of_kin_phone': 'Next of Kin Phone',
                'terms_accepted': 'Terms & Conditions Acceptance',
                'data_protection_accepted': 'Data Protection Declaration',
            }
            
            missing_seta_fields = []
            for field_name, field_label in seta_required_fields.items():
                value = data.get(field_name)
                # For boolean fields, check if explicitly set
                if field_name in ['terms_accepted', 'data_protection_accepted']:
                    if value is not True:
                        missing_seta_fields.append(field_label)
                elif not value or (isinstance(value, str) and not value.strip()):
                    missing_seta_fields.append(field_label)
            
            if missing_seta_fields:
                raise serializers.ValidationError({
                    'seta_compliance': f"The following SETA compliance fields are required for learnership enrollment: {', '.join(missing_seta_fields)}. "
                                      f"These are mandatory for actual enrollment and accreditation reporting."
                })
        
        # For AICERTS pathways (Custom Selection and Industry Training), ensure name fields are split properly
        if enrollment_type in ['custom_selection', 'industry_training']:
            # AICERTS API requires separate first_name and last_name
            full_name = data.get('learner_full_name', '').strip()
            if full_name:
                name_parts = full_name.split()
                if len(name_parts) < 2:
                    raise serializers.ValidationError({
                        'learner_full_name': 'For AICERTS integration, please provide both first and last name (e.g., "John Smith")'
                    })
                # Store name parts for AICERTS synchronization
                data['__first_name'] = name_parts[0]
                data['__last_name'] = ' '.join(name_parts[1:]) if len(name_parts) > 1 else name_parts[0]
            
            # AICERTS requires email format validation
            learner_email = data.get('learner_email', '').strip()
            if not learner_email or '@' not in learner_email:
                raise serializers.ValidationError({
                    'learner_email': 'Valid email address is required for AICERTS platform access'
                })
            
            # Optional but recommended: phone and country for AICERTS profile completeness
            learner_country = data.get('learner_country', '').strip()
            if not learner_country:
                logger.warning(f"AICERTS enrollment for {learner_email} missing country (optional but recommended)")

        # Validate email format
        learner_email = data.get('learner_email', '').strip()
        if learner_email and '@' not in learner_email:
            raise serializers.ValidationError({
                'learner_email': 'Please provide a valid email address'
            })

        # Validate phone number format (basic check)
        learner_phone = data.get('learner_phone')
        if learner_phone and isinstance(learner_phone, str):
            learner_phone = learner_phone.strip()
            if len(learner_phone) < 10:
                raise serializers.ValidationError({
                    'learner_phone': 'Phone number must be at least 10 digits'
                })

        # Validate ID number length
        learner_id_number = data.get('learner_id_number')
        if learner_id_number and isinstance(learner_id_number, str):
            learner_id_number = learner_id_number.strip()
            if len(learner_id_number) < 5:
                raise serializers.ValidationError({
                    'learner_id_number': 'ID/Passport number must be at least 5 characters'
                })

        # Validate date of birth (must be at least 16 years old)
        learner_dob = data.get('learner_dob')
        if learner_dob:
            from datetime import datetime, date
            
            # If it's a string, try to parse it (though DRF usually handles this)
            dob_date = None
            if isinstance(learner_dob, str):
                try:
                    dob_date = datetime.strptime(learner_dob.strip(), '%Y-%m-%d').date()
                except ValueError:
                    raise serializers.ValidationError({
                        'learner_dob': 'Date of birth must be in YYYY-MM-DD format (e.g., 1990-01-15)'
                    })
            elif isinstance(learner_dob, date):
                dob_date = learner_dob
            
            if dob_date:
                # Check age (must be at least 16 years old)
                today = date.today()
                age = today.year - dob_date.year - ((today.month, today.day) < (dob_date.month, dob_date.day))
                if age < 16:
                    raise serializers.ValidationError({
                        'learner_dob': 'You must be at least 16 years old to enroll'
                    })
                if age > 120:
                    raise serializers.ValidationError({
                        'learner_dob': 'Please enter a valid date of birth'
                    })

        # Check if email matches authenticated user (if logged in)
        if request and request.user.is_authenticated:
            if learner_email != request.user.email:
                # For existing users, email must match their account
                raise serializers.ValidationError({
                    'learner_email': f'Email must match your account email: {request.user.email}'
                })

        return data

    def create(self, validated_data):
        """Create enrollment and associate with user"""
        request = self.context.get('request')
        training_id = validated_data.pop('training_id')
        company_id = validated_data.pop('company_id', None)

        # Get or create user for guest enrollments
        user = None
        if request and request.user.is_authenticated:
            user = request.user
        else:
            # Guest enrollment - find or create user by email
            email = validated_data.get('learner_email').lower()
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': email,
                    'name': validated_data.get('learner_full_name', 'Student'),
                    'role_id': 3,  # Student
                }
            )

        # Get content type for the training
        enrollment_type = validated_data['enrollment_type']
        model_map = {
            EnrollmentType.MASTERCLASS: ('masterclasses', 'Masterclass'),
            EnrollmentType.LEARNERSHIP: ('learnerships', 'LearnershipProgramme'),
            EnrollmentType.INDUSTRY_TRAINING: ('industry_based_training', 'AiCertsCourse'),
            EnrollmentType.ROLE_TRAINING: ('industry_based_training', 'Offering'),
        }

        app_label, model_name = model_map[enrollment_type]
        content_type = ContentType.objects.get(app_label=app_label, model=model_name.lower())

        # Generate unique enrollment code
        import uuid
        enrollment_code = f"ENR-{uuid.uuid4().hex[:8].upper()}"

        # Create enrollment
        enrollment = Enrollment.objects.create(
            user=user,
            enrollment_code=enrollment_code,
            company_id=company_id,
            content_type=content_type,
            object_id=training_id,
            status=EnrollmentStatus.PENDING_PAYMENT,
            ip_address=self.get_client_ip(request) if request else None,
            user_agent=request.META.get('HTTP_USER_AGENT', '') if request else '',
            terms_accepted_at=timezone.now() if validated_data.get('terms_accepted') else None,
            **validated_data
        )

        # Update/create user profile with collected information
        self.update_user_profile(user, validated_data)

        # If company enrollment, link user to company
        if company_id:
            CompanyLearner.objects.get_or_create(
                company_id=company_id,
                user=request.user,
                defaults={'is_active': True}
            )

        return enrollment

    def get_client_ip(self, request):
        """Extract client IP address"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip

    def update_user_profile(self, user, data):
        """
        Update user profile with ALL enrollment data to ensure complete user record
        """
        # Personal information
        user.name = data.get('learner_full_name', user.name)
        user.fullname = data.get('learner_full_name', user.fullname)  # For AiCerts sync
        user.email = data.get('learner_email', user.email)
        user.phone = data.get('learner_phone', user.phone)
        user.phone1 = data.get('learner_phone', user.phone1)  # For AiCerts sync
        user.idnumber = data.get('learner_id_number', user.idnumber)
        user.dob = data.get('learner_dob', user.dob)

        # Address information
        user.address = data.get('learner_address', user.address)
        # Handle ForeignKeys for location if possible, otherwise store as string in other fields if available
        # Country is a ForeignKey to localization.Country
        country_code = data.get('learner_country')
        if country_code:
            from apps.localization.models import Country
            try:
                user.country = Country.objects.get(code=country_code)
            except Country.DoesNotExist:
                # If country code not found, we might want to log it or handle it
                pass

        # City is a ForeignKey to localization.City, but form gives a string
        # For now, let's not try to resolve the City FK to avoid complexity, 
        # but we can store it in a custom field if we had one or just skip if FK is required
        # user.city = data.get('learner_city', user.city) # This would fail if it's a string
        
        user.zip = data.get('learner_postal_code', user.zip)

        # Professional/Educational information
        user.institution = data.get('institution', user.institution)
        user.department = data.get('current_occupation', user.department)  # Store occupation in department field

        # Verify email if not already verified
        if not user.email_verified_at and data.get('learner_email'):
            user.email_verified_at = timezone.now()
            user.email_verify = '1'

        user.save()

        # Log the profile update
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"User profile updated for {user.email} via enrollment form")


class BulkEnrollmentSerializer(serializers.ModelSerializer):
    """
    Serializer for bulk company enrollments.
    Allows companies to register multiple learners at once.
    """

    learners = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        help_text="List of learner information dictionaries"
    )

    training_id = serializers.IntegerField(write_only=True)

    # Read-only computed fields
    training_name = serializers.SerializerMethodField()
    progress = serializers.SerializerMethodField()

    class Meta:
        model = BulkEnrollment
        fields = [
            'id',
            'bulk_code',
            'company',
            'enrollment_type',
            'training_id',
            'total_learners',
            'total_amount',
            'currency',
            'status',
            'contact_name',
            'contact_email',
            'contact_phone',
            'notes',
            'learners',
            'training_name',
            'progress',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['bulk_code', 'status', 'created_at', 'updated_at']

    def get_training_name(self, obj):
        """Get training name"""
        try:
            item = obj.get_training_item()
            if hasattr(item, 'title'):
                return item.title
            elif hasattr(item, 'name'):
                return item.name
            return str(item)
        except:
            return None

    def get_progress(self, obj):
        """Get enrollment progress"""
        return {
            'completed': obj.completed_enrollments,
            'total': obj.total_learners,
            'percentage': obj.progress_percentage
        }

    def validate_learners(self, value):
        """
        Validate learners list - ENFORCE COMPLETE INFORMATION FOR EACH LEARNER
        Each learner must provide all required fields before proceeding to payment
        """
        if not value or len(value) == 0:
            raise serializers.ValidationError("At least one learner is required for bulk enrollment")

        # ALL REQUIRED FIELDS for each learner (matching single enrollment requirements)
        required_fields = {
            'full_name': 'Full Name',
            'email': 'Email Address',
            'phone': 'Phone Number',
            'id_number': 'ID/Passport Number',
            'address': 'Physical Address',
            'city': 'City',
            'country': 'Country',
            'postal_code': 'Postal Code',
            'dob': 'Date of Birth',
            'gender': 'Gender',
            'occupation': 'Current Occupation',
            'education_level': 'Education Level',
            'institution': 'Institution/Company',
            'emergency_contact_name': 'Emergency Contact Name',
            'emergency_contact_phone': 'Emergency Contact Phone',
            'emergency_contact_relationship': 'Emergency Contact Relationship',
        }

        errors = []

        for idx, learner in enumerate(value):
            learner_number = idx + 1
            missing_fields = []

            # Check each required field
            for field_key, field_label in required_fields.items():
                field_value = learner.get(field_key)
                if not field_value or (isinstance(field_value, str) and not field_value.strip()):
                    missing_fields.append(field_label)

            if missing_fields:
                errors.append(
                    f"Learner {learner_number} ({learner.get('full_name', 'Unknown')}): "
                    f"Missing required fields: {', '.join(missing_fields)}"
                )

            # Validate email format for this learner
            email = learner.get('email', '').strip()
            if email and '@' not in email:
                errors.append(
                    f"Learner {learner_number}: Invalid email format"
                )

            # Validate phone format for this learner
            phone = learner.get('phone', '').strip()
            if phone and len(phone) < 10:
                errors.append(
                    f"Learner {learner_number}: Phone number must be at least 10 digits"
                )

            # Validate date of birth format and age
            dob = learner.get('dob', '').strip()
            if dob:
                try:
                    from datetime import datetime
                    dob_date = datetime.strptime(dob, '%Y-%m-%d')
                    age = (datetime.now() - dob_date).days / 365.25
                    if age < 16:
                        errors.append(
                            f"Learner {learner_number}: Must be at least 16 years old"
                        )
                    if age > 120:
                        errors.append(
                            f"Learner {learner_number}: Invalid date of birth"
                        )
                except ValueError:
                    errors.append(
                        f"Learner {learner_number}: Date of birth must be in YYYY-MM-DD format"
                    )

        if errors:
            raise serializers.ValidationError({
                'learners': [
                    "All learners must provide complete information before proceeding to payment:",
                    *errors,
                    "",
                    "Please complete all required fields for each learner."
                ]
            })

        return value

    def create(self, validated_data):
        """Create bulk enrollment and individual enrollments"""
        learners_data = validated_data.pop('learners')
        training_id = validated_data.pop('training_id')
        request = self.context.get('request')

        # Get content type
        enrollment_type = validated_data['enrollment_type']
        model_map = {
            EnrollmentType.MASTERCLASS: ('masterclasses', 'Masterclass'),
            EnrollmentType.LEARNERSHIP: ('learnerships', 'LearnershipProgramme'),
            EnrollmentType.INDUSTRY_TRAINING: ('industry_based_training', 'AiCertsCourse'),
            EnrollmentType.ROLE_TRAINING: ('industry_based_training', 'Offering'),
        }

        app_label, model_name = model_map[enrollment_type]
        content_type = ContentType.objects.get(app_label=app_label, model=model_name.lower())

        # Get the training item to determine price
        model_class = content_type.model_class()
        training_item = model_class.objects.get(pk=training_id)

        # Determine price per learner
        if hasattr(training_item, 'price'):
            price_per_learner = training_item.price
        elif hasattr(training_item, 'cost_usd'):
            price_per_learner = training_item.cost_usd
        elif hasattr(training_item, 'our_price_usd'):
            price_per_learner = training_item.our_price_usd
        else:
            price_per_learner = 0

        # Create bulk enrollment
        bulk_enrollment = BulkEnrollment.objects.create(
            content_type=content_type,
            object_id=training_id,
            total_learners=len(learners_data),
            total_amount=price_per_learner * len(learners_data),
            created_by=request.user if request and request.user.is_authenticated else None,
            **validated_data
        )

        # Create individual enrollments for each learner with COMPLETE information
        for learner_data in learners_data:
            # Get or create user for this learner with ALL collected information
            email = learner_data['email']
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': email,
                    'name': learner_data.get('full_name', ''),
                    'fullname': learner_data.get('full_name', ''),
                    'phone': learner_data.get('phone', ''),
                    'phone1': learner_data.get('phone', ''),
                    'idnumber': learner_data.get('id_number', ''),
                    'dob': learner_data.get('dob', ''),
                    'address': learner_data.get('address', ''),
                    'city': learner_data.get('city', ''),
                    'country': learner_data.get('country', ''),
                    'zip': learner_data.get('postal_code', ''),
                    'institution': learner_data.get('institution', ''),
                    'department': learner_data.get('occupation', ''),
                    'role_id': 3,  # Student
                    'email_verified_at': timezone.now(),
                    'email_verify': '1',
                }
            )

            # Update existing user with complete information
            if not created:
                user.name = learner_data.get('full_name', user.name)
                user.fullname = learner_data.get('full_name', user.fullname)
                user.phone = learner_data.get('phone', user.phone)
                user.phone1 = learner_data.get('phone', user.phone1)
                user.idnumber = learner_data.get('id_number', user.idnumber)
                user.dob = learner_data.get('dob', user.dob)
                user.address = learner_data.get('address', user.address)
                user.city = learner_data.get('city', user.city)
                user.country = learner_data.get('country', user.country)
                user.zip = learner_data.get('postal_code', user.zip)
                user.institution = learner_data.get('institution', user.institution)
                user.department = learner_data.get('occupation', user.department)
                user.save()

            # Create enrollment with ALL collected information
            Enrollment.objects.create(
                user=user,
                company=bulk_enrollment.company,
                enrollment_type=enrollment_type,
                content_type=content_type,
                object_id=training_id,
                status=EnrollmentStatus.PENDING_PAYMENT,
                # Personal information
                learner_full_name=learner_data.get('full_name'),
                learner_email=learner_data.get('email'),
                learner_phone=learner_data.get('phone'),
                learner_id_number=learner_data.get('id_number', ''),
                learner_dob=learner_data.get('dob', ''),
                learner_gender=learner_data.get('gender', ''),
                # Address information
                learner_address=learner_data.get('address', ''),
                learner_city=learner_data.get('city', ''),
                learner_country=learner_data.get('country'),
                learner_postal_code=learner_data.get('postal_code', ''),
                # Professional/Educational
                current_occupation=learner_data.get('occupation', ''),
                education_level=learner_data.get('education_level', ''),
                institution=learner_data.get('institution', ''),
                # Emergency contact
                emergency_contact_name=learner_data.get('emergency_contact_name', ''),
                emergency_contact_phone=learner_data.get('emergency_contact_phone', ''),
                emergency_contact_relationship=learner_data.get('emergency_contact_relationship', ''),
                # Pricing
                enrollment_fee=price_per_learner,
                final_amount=price_per_learner,
                enrollment_data={'bulk_enrollment_id': bulk_enrollment.id},
                # Terms
                terms_accepted=True,
                terms_accepted_at=timezone.now(),
            )

            # Link user to company
            CompanyLearner.objects.get_or_create(
                company=bulk_enrollment.company,
                user=user,
                defaults={'is_active': True}
            )

        return bulk_enrollment


class EnrollmentListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing enrollments"""

    enrolled_item_name = serializers.SerializerMethodField()
    company_name = serializers.CharField(source='company.name', read_only=True)
    id = serializers.IntegerField(source='enrollment_id', read_only=True)

    class Meta:
        model = Enrollment
        fields = [
            'id',
            'enrollment_code',
            'enrollment_type',
            'status',
            'learner_full_name',
            'learner_email',
            'company_name',
            'enrolled_item_name',
            'final_amount',
            'currency',
            'is_paid',
            'created_at',
            'enrolled_at',
        ]

    def get_enrolled_item_name(self, obj):
        """Get the name of the enrolled training"""
        try:
            item = obj.get_enrolled_item()
            if hasattr(item, 'title'):
                return item.title
            elif hasattr(item, 'name'):
                return item.name
            return str(item)
        except:
            return None
