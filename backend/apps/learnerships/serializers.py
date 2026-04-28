from rest_framework import serializers
from .models import (
    LearnershipProgramme,
    LearnershipPhase,
    LearnershipSchedule,
    LearnershipEnrollment,
    PrerequisiteEvidence,
    EnrollmentStatusHistory,
    EnrollmentStatus,
    CertificationTrack,
    CertificationItem,
)
from apps.users.models import User
from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField, FormattedPriceField


# -----------------------------
# Learnership Phase Serializer
# -----------------------------
class LearnershipPhaseSerializer(serializers.ModelSerializer):
    class Meta:
        model = LearnershipPhase
        fields = ('id', 'name', 'order', 'start_date', 'end_date', 'duration_weeks', 'description')


# -----------------------------
# Learnership Schedule Serializer
# -----------------------------
class LearnershipScheduleSerializer(serializers.ModelSerializer):
    class Meta:
        model = LearnershipSchedule
        fields = (
            'id', 'phase', 'start_date', 'end_date',
            'country', 'location', 'venue',
            'current_participants', 'max_participants', 'notes'
        )


# -----------------------------
# Learnership Programme Serializer
# -----------------------------
class LearnershipProgrammeSerializer(serializers.ModelSerializer):
    phases = LearnershipPhaseSerializer(many=True, read_only=True)
    certification_track = serializers.SerializerMethodField()

    # Localized Pricing
    price = LocalizedPriceField(source='cost_usd', read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='cost_usd', read_only=True)

    class Meta:
        model = LearnershipProgramme
        fields = [
            'id', 'title', 'role', 'slug', 'specialization', 'nqf_level',
            'duration_months', 'duration_weeks', 'description', 'focus',
            'prerequisites', 'entry_requirements', 'career_outcomes',
            'target_audience', 'category', 'status', 'max_participants',
            'current_participants', 'enrollment_deadline', 'start_date',
            'end_date', 'provider', 'accreditation_body', 'certificate',
            'delivery_mode', 'location', 'country', 'city', 'stipend_amount',
            'cost_usd', 'price', 'currency', 'formatted_price',
            'is_funded', 'is_featured', 'active', 'image_url', 'skills',
            'modules', 'intake_frequency', 'created_at', 'updated_at', 'phases',
            'certification_track'
        ]
    
    def get_certification_track(self, obj):
        """Get the certification track associated with this learnership"""
        try:
            # Map learnership title/role to certification track
            track_name = None
            title_lower = obj.title.lower()
            role_lower = (obj.role or '').lower()
            spec_lower = (obj.specialization or '').lower()
            
            # Check for track matches
            if 'soc analyst' in title_lower:
                track_name = 'SOC Analyst'
            elif 'security engineer' in title_lower:
                track_name = 'Security Engineer'
            elif 'security consultant' in title_lower:
                track_name = 'Security Consultant'
            elif 'red teamer' in title_lower or 'red team' in title_lower:
                track_name = 'Red Teamer'
            elif 'blue teamer' in title_lower or 'blue team' in title_lower:
                track_name = 'Blue Teamer'
            elif 'bug hunter' in title_lower:
                track_name = 'Bug Hunter'
            
            if track_name:
                track = CertificationTrack.objects.filter(name=track_name, active=True).first()
                if track:
                    from .certification_serializers import CertificationTrackSerializer
                    return CertificationTrackSerializer(track).data
        except Exception as e:
            pass
        return None

    def create(self, validated_data):
        phases_data = validated_data.pop('phases', [])
        programme = LearnershipProgramme.objects.create(**validated_data)
        for phase_data in phases_data:
            LearnershipPhase.objects.create(programme=programme, **phase_data)
        return programme

    def update(self, instance, validated_data):
        phases_data = validated_data.pop('phases', [])
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()

        for phase_data in phases_data:
            phase_id = phase_data.get('id', None)
            if phase_id:
                phase = LearnershipPhase.objects.get(id=phase_id, programme=instance)
                for key, val in phase_data.items():
                    setattr(phase, key, val)
                phase.save()
            else:
                LearnershipPhase.objects.create(programme=instance, **phase_data)

        return instance


# -----------------------------
# Learnership Enrollment Serializer (Basic)
# -----------------------------
class LearnershipEnrollmentSerializer(serializers.ModelSerializer):
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    programme = serializers.PrimaryKeyRelatedField(queryset=LearnershipProgramme.objects.all())

    # Additional fields for display
    programme_title = serializers.CharField(source='programme.title', read_only=True)
    programme_slug = serializers.CharField(source='programme.slug', read_only=True)
    instructor_name = serializers.CharField(source='programme.instructor.name', read_only=True)
    instructor_id = serializers.IntegerField(source='programme.instructor.id', read_only=True, allow_null=True)

    class Meta:
        model = LearnershipEnrollment
        fields = (
            'id', 'user', 'programme', 'programme_title', 'programme_slug',
            'instructor_name', 'instructor_id',
            'active', 'enrolled_at'
        )
        read_only_fields = ('enrolled_at',)

    def create(self, validated_data):
        schedules_data = validated_data.pop('schedules', [])
        enrollment = LearnershipEnrollment.objects.create(**validated_data)
        for schedule_data in schedules_data:
            LearnershipSchedule.objects.create(enrollment=enrollment, **schedule_data)
        return enrollment

    def update(self, instance, validated_data):
        schedules_data = validated_data.pop('schedules', [])
        for attr, val in validated_data.items():
            setattr(instance, attr, val)
        instance.save()

        for schedule_data in schedules_data:
            schedule_id = schedule_data.get('id', None)
            if schedule_id:
                schedule = LearnershipSchedule.objects.get(id=schedule_id, enrollment=instance)
                for key, val in schedule_data.items():
                    setattr(schedule, key, val)
                schedule.save()
            else:
                LearnershipSchedule.objects.create(enrollment=instance, **schedule_data)

        return instance


# =====================================================
# LEARNERSHIP ENROLLMENT SERIALIZERS (NEW - Enhanced)
# =====================================================

class PrerequisiteEvidenceSerializer(serializers.ModelSerializer):
    """Serializer for uploading prerequisite evidence"""
    class Meta:
        model = PrerequisiteEvidence
        fields = (
            'id', 'enrollment', 'prerequisite_key', 'prerequisite_name',
            'evidence_file', 'file_type', 'file_size', 'evidence_description',
            'status', 'uploaded_at', 'review_notes',
        )
        read_only_fields = ('id', 'enrollment', 'status', 'uploaded_at', 'review_notes')


class LearnershipEnrollmentCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating a new learnership enrollment.
    Handles both individual and corporate enrollments.
    
    Accepts two formats:
    1. Flat format (matching Enrollment model) - for direct API calls
    2. Nested format with user_data dict - for backward compatibility
    """
    # For backward compatibility with nested user_data format
    user_data = serializers.DictField(write_only=True, required=False)
    corporate_learners = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        required=False
    )
    evidence = serializers.ListField(
        child=serializers.DictField(),
        write_only=True,
        required=False
    )
    company = serializers.DictField(write_only=True, required=False)
    payment_option = serializers.ChoiceField(
        choices=['upfront', 'installments', 'cash'],
        default='installments'
    )
    payment_status = serializers.ChoiceField(
        choices=[('pending', 'Pending'), ('paid', 'Paid'), ('partial_paid', 'Partially Paid'), ('cash_promise', 'Cash Promise')],
        default='pending'
    )
    amount_paid = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        required=False
    )
    
    # Flat fields matching Enrollment model (for direct API format)
    # Personal Information
    learner_full_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_email = serializers.EmailField(write_only=True, required=False, allow_blank=True)
    learner_phone = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_id_number = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_dob = serializers.DateField(write_only=True, required=False, allow_null=True)
    learner_gender = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_address = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_city = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_country = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learner_postal_code = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    # Professional/Educational
    current_occupation = serializers.CharField(write_only=True, required=False, allow_blank=True)
    education_level = serializers.CharField(write_only=True, required=False, allow_blank=True)
    institution = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    # Emergency Contact
    emergency_contact_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    emergency_contact_phone = serializers.CharField(write_only=True, required=False, allow_blank=True)
    emergency_contact_relationship = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    # SETA Compliance
    race = serializers.CharField(write_only=True, required=False, allow_blank=True)
    disability = serializers.CharField(write_only=True, required=False, allow_blank=True)
    nationality = serializers.CharField(write_only=True, required=False, allow_blank=True)
    highest_qualification = serializers.CharField(write_only=True, required=False, allow_blank=True)
    qualification_institution = serializers.CharField(write_only=True, required=False, allow_blank=True)
    qualification_year = serializers.CharField(write_only=True, required=False, allow_blank=True)
    employer = serializers.CharField(write_only=True, required=False, allow_blank=True)
    job_title = serializers.CharField(write_only=True, required=False, allow_blank=True)
    employment_status = serializers.CharField(write_only=True, required=False, allow_blank=True)
    monthly_income = serializers.CharField(write_only=True, required=False, allow_blank=True)
    existing_skills = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    # Next of Kin
    next_of_kin_name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    next_of_kin_phone = serializers.CharField(write_only=True, required=False, allow_blank=True)
    next_of_kin_relationship = serializers.CharField(write_only=True, required=False, allow_blank=True)
    next_of_kin_email = serializers.EmailField(write_only=True, required=False, allow_blank=True)
    next_of_kin_address = serializers.CharField(write_only=True, required=False, allow_blank=True)
    
    # Medical & Accessibility
    medical_conditions = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    allergies = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    medications = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    accessibility_needs = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    dietary_requirements = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    
    # Learning Support
    requires_learning_support = serializers.CharField(write_only=True, required=False, allow_blank=True)
    learning_support_details = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    has_previous_learnership_experience = serializers.CharField(write_only=True, required=False, allow_blank=True)
    previous_learnership_details = serializers.CharField(write_only=True, required=False, allow_blank=True, default='')
    
    # Documentation Checklist
    has_id_copy = serializers.BooleanField(write_only=True, required=False, default=False)
    has_qualification_certificates = serializers.BooleanField(write_only=True, required=False, default=False)
    has_proof_of_residence = serializers.BooleanField(write_only=True, required=False, default=False)
    has_cv = serializers.BooleanField(write_only=True, required=False, default=False)
    has_motivational_letter = serializers.BooleanField(write_only=True, required=False, default=False)
    
    # Payment & Funding
    funding_source = serializers.CharField(write_only=True, required=False)
    company_vat_number = serializers.CharField(write_only=True, required=False)
    purchase_order_number = serializers.CharField(write_only=True, required=False)
    
    # Debit Order Banking
    requires_debit_order = serializers.CharField(write_only=True, required=False)
    bank_name = serializers.CharField(write_only=True, required=False)
    bank_account_number = serializers.CharField(write_only=True, required=False)
    bank_branch_code = serializers.CharField(write_only=True, required=False)
    bank_account_type = serializers.CharField(write_only=True, required=False)
    bank_account_holder_name = serializers.CharField(write_only=True, required=False)
    
    # Legal Declarations
    terms_accepted = serializers.BooleanField(write_only=True, required=False, default=False)
    data_protection_accepted = serializers.BooleanField(write_only=True, required=False, default=False)
    certification_declaration_accepted = serializers.BooleanField(write_only=True, required=False, default=False)
    seta_declaration_accepted = serializers.BooleanField(write_only=True, required=False, default=False)
    
    # Additional
    referral_source = serializers.CharField(write_only=True, required=False)
    additional_notes = serializers.CharField(write_only=True, required=False)
    
    # Metadata
    programme_title = serializers.CharField(source='programme.title', read_only=True)
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)

    class Meta:
        model = LearnershipEnrollment
        fields = (
            'id', 'programme', 'programme_title', 'user', 'user_email', 'user_name',
            'enrollment_type', 'status', 'payment_option', 'payment_status',
            'amount_paid', 'currency', 'user_data', 'corporate_learners',
            'evidence', 'company', 'enrolled_at', 'metadata',
            # Flat fields
            'learner_full_name', 'learner_email', 'learner_phone', 'learner_id_number',
            'learner_dob', 'learner_gender', 'learner_address', 'learner_city',
            'learner_country', 'learner_postal_code',
            'current_occupation', 'education_level', 'institution',
            'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relationship',
            'race', 'disability', 'nationality',
            'highest_qualification', 'qualification_institution', 'qualification_year',
            'employer', 'job_title', 'employment_status', 'monthly_income', 'existing_skills',
            'next_of_kin_name', 'next_of_kin_phone', 'next_of_kin_relationship',
            'next_of_kin_email', 'next_of_kin_address',
            'medical_conditions', 'allergies', 'medications',
            'accessibility_needs', 'dietary_requirements',
            'requires_learning_support', 'learning_support_details',
            'has_previous_learnership_experience', 'previous_learnership_details',
            'has_id_copy', 'has_qualification_certificates', 'has_proof_of_residence',
            'has_cv', 'has_motivational_letter',
            'funding_source', 'company_vat_number', 'purchase_order_number',
            'requires_debit_order', 'bank_name', 'bank_account_number',
            'bank_branch_code', 'bank_account_type', 'bank_account_holder_name',
            'terms_accepted', 'data_protection_accepted',
            'certification_declaration_accepted', 'seta_declaration_accepted',
            'referral_source', 'additional_notes',
        )
        read_only_fields = ('id', 'user', 'status', 'enrolled_at')

    def create(self, validated_data):
        user_data = validated_data.pop('user_data', {})
        corporate_learners = validated_data.pop('corporate_learners', [])
        evidence_data = validated_data.pop('evidence', [])
        company_data = validated_data.pop('company', {})
        payment_option = validated_data.pop('payment_option', 'installments')

        # Extract flat fields for metadata storage
        flat_fields = {}
        flat_field_names = [
            'learner_full_name', 'learner_email', 'learner_phone', 'learner_id_number',
            'learner_dob', 'learner_gender', 'learner_address', 'learner_city',
            'learner_country', 'learner_postal_code',
            'current_occupation', 'education_level', 'institution',
            'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relationship',
            'race', 'disability', 'nationality',
            'highest_qualification', 'qualification_institution', 'qualification_year',
            'employer', 'job_title', 'employment_status', 'monthly_income', 'existing_skills',
            'next_of_kin_name', 'next_of_kin_phone', 'next_of_kin_relationship',
            'next_of_kin_email', 'next_of_kin_address',
            'medical_conditions', 'allergies', 'medications',
            'accessibility_needs',
            'requires_learning_support', 'learning_support_details',
            'has_previous_learnership_experience', 'previous_learnership_details',
            'has_id_copy', 'has_qualification_certificates', 'has_proof_of_residence',
            'has_cv', 'has_motivational_letter',
            'funding_source', 'company_vat_number', 'purchase_order_number',
            'requires_debit_order', 'bank_name', 'bank_account_number',
            'bank_branch_code', 'bank_account_type', 'bank_account_holder_name',
            'terms_accepted', 'data_protection_accepted',
            'certification_declaration_accepted', 'seta_declaration_accepted',
            'referral_source', 'additional_notes',
        ]
        for field in flat_field_names:
            if field in validated_data:
                flat_fields[field] = validated_data.pop(field)

        is_corporate = bool(corporate_learners) or bool(company_data)
        validated_data['enrollment_type'] = 'corporate' if is_corporate else 'individual'

        request = self.context.get('request')
        user = None

        if is_corporate:
            user = request.user if request and request.user.is_authenticated else None
        else:
            # Handle both nested user_data and flat fields format
            if user_data:
                email = user_data.get('email')
                full_name = user_data.get('full_name', '')
            else:
                # Use flat fields
                email = flat_fields.get('learner_email', '')
                full_name = flat_fields.get('learner_full_name', '')
            
            if email:
                user, created = User.objects.get_or_create(
                    email=email,
                    defaults={
                        'username': email,
                        'first_name': full_name.split()[0] if full_name else '',
                        'last_name': ' '.join(full_name.split()[1:]) if full_name and len(full_name.split()) > 1 else '',
                        'phone': flat_fields.get('learner_phone', ''),
                        'idnumber': flat_fields.get('learner_id_number', ''),
                    }
                )
                
                # Update user profile with all available data
                user.phone = flat_fields.get('learner_phone', user.phone)
                user.idnumber = flat_fields.get('learner_id_number', user.idnumber)
                user.dob = flat_fields.get('learner_dob') or user.dob
                user.save()

        if user:
            validated_data['user'] = user

        if is_corporate and company_data:
            validated_data['company_name'] = company_data.get('name', '')
            validated_data['company_registration_number'] = company_data.get('registration_number', '')
            validated_data['company_tax_number'] = company_data.get('tax_number', '')
            validated_data['company_contact_person'] = company_data.get('contact_person', '')
            validated_data['company_email'] = company_data.get('email', '')
            validated_data['company_phone'] = company_data.get('phone', '')
            validated_data['company_address'] = company_data.get('address', '')

        validated_data['payment_option'] = payment_option
        if validated_data.get('amount_paid') is not None:
            validated_data['payment_status'] = 'pending'

        # dietary_requirements is saved directly to database via validated_data
        # (already in validated_data from the serializer field)

        enrollment = super().create(validated_data)

        # Store flat fields in metadata for later retrieval
        if flat_fields and not is_corporate:
            enrollment.metadata = enrollment.metadata or {}
            enrollment.metadata.update(flat_fields)
            enrollment.save()

        if not is_corporate and evidence_data:
            for evidence_item in evidence_data:
                PrerequisiteEvidence.objects.create(
                    enrollment=enrollment,
                    prerequisite_key=evidence_item.get('prerequisite_key', ''),
                    prerequisite_name=evidence_item.get('prerequisite_name', ''),
                    evidence_description=evidence_item.get('description', ''),
                    status='pending_submission' if not evidence_item.get('file_path') else 'submitted',
                )

        if is_corporate and corporate_learners:
            self._send_corporate_invitations(enrollment, corporate_learners)

        return enrollment

    def _send_corporate_invitations(self, enrollment, corporate_learners):
        """Send enrollment invitation emails to corporate learners"""
        try:
            from apps.notifications.tasks import send_learnership_invitation_task
            for learner in corporate_learners:
                send_learnership_invitation_task.delay(
                    enrollment_id=enrollment.id,
                    learner_name=learner.get('full_name', ''),
                    learner_email=learner.get('email', ''),
                )
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to send corporate invitations: {e}")


class LearnershipEnrollmentDetailSerializer(serializers.ModelSerializer):
    """Detailed serializer for viewing enrollment information"""
    programme = LearnershipProgrammeSerializer(read_only=True)
    user = serializers.StringRelatedField(read_only=True)
    schedules = LearnershipScheduleSerializer(many=True, read_only=True)
    prerequisite_evidences = PrerequisiteEvidenceSerializer(many=True, read_only=True)
    verified_by = serializers.StringRelatedField(read_only=True)
    has_all_evidence_submitted = serializers.BooleanField(read_only=True)
    has_all_evidence_approved = serializers.BooleanField(read_only=True)
    pending_evidence_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = LearnershipEnrollment
        fields = (
            'id', 'programme', 'user', 'enrollment_type', 'status',
            'payment_status', 'amount_paid', 'currency', 'payment_option',
            'prerequisites_verified', 'verification_notes', 'verified_by',
            'verified_at', 'enrolled_at', 'confirmed_at', 'started_at',
            'completed_at', 'schedules', 'prerequisite_evidences',
            'has_all_evidence_submitted', 'has_all_evidence_approved',
            'pending_evidence_count', 'active', 'metadata',
            'company_name', 'company_registration_number', 'company_tax_number',
            'company_contact_person', 'company_email', 'company_phone',
            'company_address',
        )
