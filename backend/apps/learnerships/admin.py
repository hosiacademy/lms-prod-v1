# apps/learnerships/admin.py
from django.contrib import admin
from django import forms

from .models import (
    LearnershipProgramme,
    LearnershipPhase,
    LearnershipEnrollment,
    LearnershipSchedule,
    CourseProvider,
    Course,
    PhaseCourse,
    PrerequisiteEvidence,
    EnrollmentStatusHistory,
)

# =====================================================
# COURSE PROVIDERS & COURSES (AiCerts + others)
# =====================================================

@admin.register(CourseProvider)
class CourseProviderAdmin(admin.ModelAdmin):
    list_display = ("name", "active")
    list_filter = ("active",)
    search_fields = ("name",)


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("title", "provider", "category_name", "active", "last_synced")
    list_filter = ("provider", "active")
    search_fields = ("title", "shortname", "summary", "category_name")
    ordering = ("provider", "title")


# =====================================================
# PHASE ↔ COURSE LINK (BESPOKE PATHWAYS)
# =====================================================

class PhaseCourseInline(admin.TabularInline):
    model = PhaseCourse
    extra = 1
    fields = ("course", "order")
    ordering = ("order",)

    def formfield_for_foreignkey(self, db_field, request=None, **kwargs):
        if db_field.name == "course":
            kwargs["queryset"] = Course.objects.filter(active=True).select_related("provider")
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


# =====================================================
# LEARNERSHIP PHASE
# =====================================================

@admin.register(LearnershipPhase)
class LearnershipPhaseAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "programme",
        "order",
        "start_date",
        "end_date",
        "duration_weeks",
    )
    list_filter = ("programme",)
    search_fields = ("name", "programme__title")
    ordering = ("programme", "order")
    inlines = [PhaseCourseInline]


# =====================================================
# LEARNERSHIP PROGRAMME
# =====================================================

class LearnershipPhaseInline(admin.TabularInline):
    model = LearnershipPhase
    extra = 1
    fields = (
        "name",
        "order",
        "start_date",
        "end_date",
        "duration_weeks",
        "description",
    )
    show_change_link = True


@admin.register(LearnershipProgramme)
class LearnershipProgrammeAdmin(admin.ModelAdmin):
    list_display = ("title", "duration_weeks", "active", "is_offered", "created_at")
    list_filter = ("active", "is_offered", "category", "provider")
    search_fields = ("title", "focus", "prerequisites", "category")
    ordering = ("title",)
    inlines = [LearnershipPhaseInline]


# =====================================================
# LEARNERSHIP SCHEDULE
# =====================================================

class LearnershipScheduleInline(admin.TabularInline):
    model = LearnershipSchedule
    extra = 1
    fields = (
        "phase",
        "start_date",
        "end_date",
        "country",
        "location",
        "venue",
        "max_participants",
        "current_participants",
        "notes",
    )
    show_change_link = True

    def formfield_for_foreignkey(self, db_field, request=None, **kwargs):
        if db_field.name == "phase" and hasattr(request, "_programme_id"):
            kwargs["queryset"] = LearnershipPhase.objects.filter(
                programme_id=request._programme_id
            )
        return super().formfield_for_foreignkey(db_field, request, **kwargs)


# =====================================================
# LEARNERSHIP ENROLLMENT
# =====================================================

class LearnershipEnrollmentAdminForm(forms.ModelForm):
    class Meta:
        model = LearnershipEnrollment
        fields = "__all__"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            self.request_programme_id = self.instance.programme_id


class PrerequisiteEvidenceInline(admin.TabularInline):
    model = PrerequisiteEvidence
    extra = 0
    fields = (
        "prerequisite_name",
        "status",
        "uploaded_at",
        "review_notes",
    )
    readonly_fields = (
        "prerequisite_name",
        "evidence_file",
        "status",
        "uploaded_at",
        "reviewed_by",
        "reviewed_at",
        "review_notes",
    )

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(LearnershipEnrollment)
class LearnershipEnrollmentAdmin(admin.ModelAdmin):
    form = LearnershipEnrollmentAdminForm
    list_display = (
        "user",
        "programme",
        "status",
        "enrollment_type",
        "payment_status",
        "prerequisites_verified",
        "enrolled_at",
        "confirmed_at",
    )
    list_filter = (
        "status",
        "enrollment_type",
        "payment_status",
        "prerequisites_verified",
        "programme",
    )
    search_fields = (
        "user__username",
        "user__email",
        "programme__title",
        "company_name",
    )
    ordering = ("-enrolled_at",)
    inlines = [PrerequisiteEvidenceInline, LearnershipScheduleInline]
    
    fieldsets = (
        ("Basic Information", {
            "fields": ("programme", "user", "enrollment_type", "active")
        }),
        ("Status & Verification", {
            "fields": (
                "status",
                "prerequisites_verified",
                "verification_notes",
                "verified_by",
                "verified_at",
            )
        }),
        ("Corporate Enrollment", {
            "fields": (
                "company_name",
                "company_registration_number",
                "company_tax_number",
                "company_contact_person",
                "company_email",
                "company_phone",
                "company_address",
                "company_country",
            ),
            "classes": ("collapse",)
        }),
        ("Payment Information", {
            "fields": (
                "payment_transaction",
                "payment_status",
                "amount_paid",
                "currency",
            ),
            "classes": ("collapse",)
        }),
        ("Timeline", {
            "fields": (
                "enrolled_at",
                "confirmed_at",
                "started_at",
                "completed_at",
                "dropped_out_at",
            ),
            "classes": ("collapse",)
        }),
    )

    def get_form(self, request, obj=None, **kwargs):
        if obj:
            request._programme_id = obj.programme_id
        return super().get_form(request, obj, **kwargs)

    def save_model(self, request, obj, form, change):
        """Track who made status changes"""
        if change and 'status' in form.changed_data:
            obj._changed_by = request.user
            # Get the reason from a potential admin note field
            obj._change_reason = form.cleaned_data.get('verification_notes', 'Updated by admin')
        super().save_model(request, obj, form, change)


# =====================================================
# LEARNERSHIP SCHEDULE (STANDALONE)
# =====================================================

@admin.register(LearnershipSchedule)
class LearnershipScheduleAdmin(admin.ModelAdmin):
    list_display = (
        "enrollment",
        "phase",
        "start_date",
        "end_date",
        "country",
        "location",
        "venue",
        "current_participants",
        "max_participants",
    )
    list_filter = ("country", "phase", "venue")
    search_fields = (
        "enrollment__user__username",
        "enrollment__user__email",
        "enrollment__programme__title",
        "phase__name",
        "venue",
        "location",
    )
    ordering = ("start_date",)


# =====================================================
# PREREQUISITE EVIDENCE
# =====================================================

class PrerequisiteEvidenceInline(admin.TabularInline):
    model = PrerequisiteEvidence
    extra = 0
    fields = (
        "prerequisite_name",
        "evidence_file",
        "status",
        "uploaded_at",
        "reviewed_by",
        "review_notes",
    )
    readonly_fields = (
        "prerequisite_name",
        "evidence_file",
        "uploaded_at",
        "reviewed_by",
        "reviewed_at",
        "review_notes",
        "resubmission_count",
    )

    def has_add_permission(self, request, obj=None):
        return False  # Evidence can only be added via frontend upload


@admin.register(PrerequisiteEvidence)
class PrerequisiteEvidenceAdmin(admin.ModelAdmin):
    list_display = (
        "enrollment",
        "prerequisite_name",
        "status",
        "uploaded_at",
        "reviewed_by",
        "reviewed_at",
    )
    list_filter = ("status", "reviewed_at")
    search_fields = (
        "enrollment__user__username",
        "enrollment__user__email",
        "enrollment__programme__title",
        "prerequisite_name",
    )
    readonly_fields = (
        "enrollment",
        "prerequisite_key",
        "prerequisite_name",
        "evidence_file",
        "file_type",
        "file_size",
        "evidence_description",
        "uploaded_at",
        "resubmission_count",
    )
    actions = ["approve_evidence", "reject_evidence"]

    def approve_evidence(self, request, queryset):
        """Bulk approve selected evidence"""
        for evidence in queryset.filter(status__in=['submitted', 'pending_review']):
            evidence.approve(
                reviewed_by=request.user,
                notes=f"Approved by {request.user.email}"
            )
        self.message_user(request, f"Approved {queryset.count()} evidence records")
    approve_evidence.short_description = "Approve selected evidence"

    def reject_evidence(self, request, queryset):
        """Bulk reject selected evidence"""
        for evidence in queryset.filter(status__in=['submitted', 'pending_review']):
            evidence.reject(
                reviewed_by=request.user,
                notes=f"Rejected by {request.user.email} - requires resubmission"
            )
        self.message_user(request, f"Rejected {queryset.count()} evidence records")
    reject_evidence.short_description = "Reject selected evidence"


# =====================================================
# ENROLLMENT STATUS HISTORY
# =====================================================

@admin.register(EnrollmentStatusHistory)
class EnrollmentStatusHistoryAdmin(admin.ModelAdmin):
    list_display = (
        "enrollment",
        "from_status",
        "to_status",
        "changed_by",
        "changed_at",
    )
    list_filter = ("to_status", "from_status", "changed_at")
    search_fields = (
        "enrollment__user__username",
        "enrollment__programme__title",
        "changed_by__username",
        "changed_by__email",
    )
    readonly_fields = (
        "enrollment",
        "from_status",
        "to_status",
        "changed_by",
        "reason",
        "changed_at",
    )

    def has_add_permission(self, request):
        return False  # History is auto-generated

    def has_change_permission(self, request, obj=None):
        return False  # History is immutable
