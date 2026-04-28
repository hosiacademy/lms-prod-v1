# apps/enrollments/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.shortcuts import render
from django.http import HttpResponseRedirect
from django.template.response import TemplateResponse
from django.utils import timezone
from .models import ProvisionalEnrollment


@admin.register(ProvisionalEnrollment)
class ProvisionalEnrollmentAdmin(admin.ModelAdmin):
    list_display = [
        'reference_code',
        'user_email',
        'enrollment_type_badge',
        'status_badge',
        'created_at',
        'expires_at',
        'days_until_expiry',
        'prerequisites_verified',
    ]

    list_filter = [
        'status',
        'enrollment_type',
        'prerequisites_verified',
        'created_at',
    ]

    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
        'reference_code',
    ]

    readonly_fields = [
        'reference_code',
        'created_at',
        'expires_at',
        'is_expired',
        'verified_at',
        'verified_by',
        'metadata',
    ]

    actions = [
        'activate_cash_enrollment',
        'confirm_learnership_enrollment',
        'reject_and_refund',
    ]

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'User'

    def enrollment_type_badge(self, obj):
        colors = {
            'masterclass': '#2196F3',
            'learnership': '#FF9800',
            'industry': '#4CAF50',
            'custom_selection': '#9C27B0',
        }
        color = colors.get(obj.enrollment_type, '#757575')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px;">{}</span>',
            color,
            obj.get_enrollment_type_display()
        )
    enrollment_type_badge.short_description = 'Type'

    def status_badge(self, obj):
        colors = {
            'cash_pending': '#FF9800',
            'provisional': '#2196F3',
            'confirmed': '#4CAF50',
            'rejected': '#F44336',
            'refunded': '#9E9E9E',
            'expired': '#757575',
        }
        color = colors.get(obj.status, '#757575')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

    def days_until_expiry(self, obj):
        delta = obj.expires_at - timezone.now()
        days = delta.days

        if obj.is_expired:
            return format_html('<span style="color: red; font-weight: bold;">EXPIRED</span>')
        elif days <= 2:
            return format_html('<span style="color: orange; font-weight: bold;">{} days</span>', days)
        else:
            return f"{days} days"
    days_until_expiry.short_description = 'Expires In'

    @admin.action(description='Activate cash enrollments (payment received)')
    def activate_cash_enrollment(self, request, queryset):
        """Admin action to activate cash enrollments after payment received at office"""
        selected = queryset.filter(status='cash_pending')

        for enrollment in selected:
            if enrollment.enrollment_type == 'learnership':
                # For learnership, move to provisional for prerequisite verification
                enrollment.status = 'provisional'
                enrollment.save()
                
                # Also update LearnershipEnrollment payment status
                from apps.learnerships.models import LearnershipEnrollment
                learnership_enrollment = LearnershipEnrollment.objects.filter(
                    payment_transaction=enrollment.payment_transaction
                ).first()
                
                if learnership_enrollment:
                    learnership_enrollment.payment_status = 'paid'
                    learnership_enrollment.amount_paid = enrollment.payment_transaction.amount if enrollment.payment_transaction else 0
                    learnership_enrollment.save()
            else:
                # Direct confirmation for other types
                try:
                    enrollment.confirm_enrollment()
                except Exception as e:
                    self.message_user(
                        request,
                        f"Error activating enrollment {enrollment.reference_code}: {e}",
                        level='error'
                    )

        self.message_user(request, f"Activated {selected.count()} cash enrollments")

    @admin.action(description='Confirm learnership (prerequisites verified)')
    def confirm_learnership_enrollment(self, request, queryset):
        """Admin action to confirm learnership enrollments after verifying prerequisites"""
        selected = queryset.filter(status='provisional', enrollment_type='learnership')

        for enrollment in selected:
            enrollment.prerequisites_verified = True
            enrollment.verified_by = request.user
            enrollment.verified_at = timezone.now()
            
            # Also update LearnershipEnrollment
            from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
            learnership_enrollment = LearnershipEnrollment.objects.filter(
                payment_transaction=enrollment.payment_transaction
            ).first()
            
            if learnership_enrollment:
                learnership_enrollment.status = LearnershipEnrollmentStatus.CONFIRMED
                learnership_enrollment.prerequisites_verified = True
                learnership_enrollment.verified_by = request.user
                learnership_enrollment.verified_at = timezone.now()
                learnership_enrollment.confirmed_at = timezone.now()
                learnership_enrollment.save()
            
            try:
                enrollment.confirm_enrollment()
            except Exception as e:
                self.message_user(
                    request,
                    f"Error confirming enrollment {enrollment.reference_code}: {e}",
                    level='error'
                )

        self.message_user(request, f"Confirmed {selected.count()} learnership enrollments")

    @admin.action(description='Reject and refund (prerequisites not met)')
    def reject_and_refund(self, request, queryset):
        """Admin action to reject and refund enrollments"""
        selected = queryset.filter(status='provisional')

        # If applying rejection
        if 'apply' in request.POST:
            reason = request.POST.get('rejection_reason')

            for enrollment in selected:
                try:
                    enrollment.reject_and_refund(reason)
                    
                    # Also update LearnershipEnrollment
                    from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
                    learnership_enrollment = LearnershipEnrollment.objects.filter(
                        payment_transaction=enrollment.payment_transaction
                    ).first()
                    
                    if learnership_enrollment:
                        learnership_enrollment.status = LearnershipEnrollmentStatus.REJECTED
                        learnership_enrollment.payment_status = 'refunded'
                        learnership_enrollment.verified_by = request.user
                        learnership_enrollment.verified_at = timezone.now()
                        learnership_enrollment.verification_notes = reason
                        learnership_enrollment.save()
                        
                except Exception as e:
                    self.message_user(
                        request,
                        f"Error rejecting enrollment {enrollment.reference_code}: {e}",
                        level='error'
                    )

            self.message_user(request, f"Rejected and refunded {selected.count()} enrollments")
            return HttpResponseRedirect(request.get_full_path())

        # Show intermediate form for rejection reason
        context = {
            **self.admin_site.each_context(request),
            'enrollments': selected,
            'action': 'reject_and_refund',
            'opts': self.model._meta,
        }
        return TemplateResponse(request, 'admin/enrollments/reject_reason_form.html', context)
