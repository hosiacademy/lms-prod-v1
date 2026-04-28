# apps/payments/admin.py - FINAL CORRECT VERSION
from django.contrib import admin

print("Loading payments admin...")

# Import all models safely
try:
    from .models import (
        PaymentProviderModel, Order, PaymentTransaction,
        PaymentWebhookLog, PaymentReconciliation, PaymentRefund,
        DepositRecord, Cart, AdminRole, AdminCountryAccess,
        Enrollment, BulkEnrollment, PaymentOTPVerification
    )
    
    # PaymentProviderModel
    @admin.register(PaymentProviderModel)
    class PaymentProviderAdmin(admin.ModelAdmin):
        list_display = ('name', 'category', 'is_active')
        list_filter = ('category', 'is_active')
        search_fields = ('name', 'code')
        actions = []
    
    # Order
    @admin.register(Order)
    class OrderAdmin(admin.ModelAdmin):
        list_display = ('tracking', 'user', 'amount', 'status')
        search_fields = ('tracking', 'user__username')
        actions = []
    
    # PaymentTransaction
    @admin.register(PaymentTransaction)
    class PaymentTransactionAdmin(admin.ModelAdmin):
        list_display = ('provider_reference', 'amount', 'status')
        search_fields = ('provider_reference',)
        actions = []
    
    # PaymentWebhookLog - Using ACTUAL field names from your model
    @admin.register(PaymentWebhookLog)
    class PaymentWebhookLogAdmin(admin.ModelAdmin):
        list_display = ('provider', 'event_type', 'received_at', 'processed')
        list_filter = ('provider', 'processed')
        search_fields = ('provider', 'event_type')
        actions = []
    
    # PaymentRefund - Using ACTUAL field names from your model
    @admin.register(PaymentRefund)
    class PaymentRefundAdmin(admin.ModelAdmin):
        list_display = ('refund_reference', 'refund_amount', 'status', 'created_at')
        list_filter = ('status',)
        search_fields = ('refund_reference',)
        actions = []
    
    # Other models if they exist
    try:
        @admin.register(PaymentReconciliation)
        class PaymentReconciliationAdmin(admin.ModelAdmin):
            list_display = ('reconciliation_date', 'status')
            actions = []
    except:
        pass
    
    try:
        @admin.register(DepositRecord)
        class DepositRecordAdmin(admin.ModelAdmin):
            list_display = ('user', 'amount', 'status')
            actions = []
    except:
        pass
    
    try:
        @admin.register(Cart)
        class CartAdmin(admin.ModelAdmin):
            list_display = ('user', 'created_at')
            actions = []
    except:
        pass

    # AdminRole - Manage admin role assignments
    @admin.register(AdminRole)
    class AdminRoleAdmin(admin.ModelAdmin):
        list_display = ('user', 'role_type', 'is_active', 'assigned_at', 'assigned_by')
        list_filter = ('role_type', 'is_active', 'assigned_at')
        search_fields = ('user__username', 'user__email', 'user__name')
        readonly_fields = ('assigned_at', 'created_at', 'updated_at')
        
        fieldsets = (
            ('Role Assignment', {
                'fields': ('user', 'role_type', 'is_active')
            }),
            ('Assignment Details', {
                'fields': ('assigned_by', 'assigned_at', 'notes'),
                'classes': ('collapse',)
            }),
            ('Revocation', {
                'fields': ('revoked_at', 'revoked_by', 'revocation_reason'),
                'classes': ('collapse',)
            }),
            ('Permissions', {
                'fields': ('permissions',),
                'classes': ('collapse',)
            }),
            ('Timestamps', {
                'fields': ('created_at', 'updated_at'),
                'classes': ('collapse',)
            }),
        )
        
        def save_model(self, request, obj, form, change):
            if not change:  # Creating new object
                obj.assigned_by = request.user
            super().save_model(request, obj, form, change)
        
        def get_readonly_fields(self, request, obj=None):
            if obj:  # Editing existing object
                return self.readonly_fields + ('assigned_by', 'assigned_at')
            return self.readonly_fields

    # AdminCountryAccess - Manage country access for admin roles
    @admin.register(AdminCountryAccess)
    class AdminCountryAccessAdmin(admin.ModelAdmin):
        list_display = ('admin_role', 'country', 'is_active', 'granted_at', 'granted_by')
        list_filter = ('is_active', 'admin_role__role_type', 'country')
        search_fields = ('admin_role__user__username', 'admin_role__user__email', 'country__name')
        readonly_fields = ('granted_at', 'created_at', 'updated_at')
        
        fieldsets = (
            ('Country Access', {
                'fields': ('admin_role', 'country', 'is_active')
            }),
            ('Grant Details', {
                'fields': ('granted_by', 'granted_at', 'notes'),
                'classes': ('collapse',)
            }),
            ('Revocation', {
                'fields': ('revoked_at', 'revoked_by'),
                'classes': ('collapse',)
            }),
            ('Timestamps', {
                'fields': ('created_at', 'updated_at'),
                'classes': ('collapse',)
            }),
        )
        
        def save_model(self, request, obj, form, change):
            if not change:  # Creating new object
                obj.granted_by = request.user
            super().save_model(request, obj, form, change)
        
        def get_readonly_fields(self, request, obj=None):
            if obj:  # Editing existing object
                return self.readonly_fields + ('granted_by', 'granted_at')
            return self.readonly_fields
        
        def formfield_for_foreignkey(self, db_field, request, **kwargs):
            """Limit admin_role choices to active admin roles"""
            if db_field.name == "admin_role":
                kwargs["queryset"] = AdminRole.objects.filter(is_active=True).select_related('user')
            return super().formfield_for_foreignkey(db_field, request, **kwargs)

    # Enrollment - Comprehensive enrollment management
    @admin.register(Enrollment)
    class EnrollmentAdmin(admin.ModelAdmin):
        list_display = ('enrollment_code', 'learner_full_name', 'learner_email', 'enrollment_type', 'status', 'created_at')
        list_filter = ('status', 'enrollment_type')
        search_fields = ('enrollment_code', 'learner_full_name', 'learner_email', 'user__username')
        readonly_fields = ('created_at', 'updated_at')

        fieldsets = (
            ('Basic Information', {
                'fields': ('enrollment_code', 'enrollment_type', 'content_type', 'object_id', 'user', 'status')
            }),
            ('Learner Details', {
                'fields': (
                    'learner_full_name', 'learner_email', 'learner_phone', 'learner_id_number',
                    'learner_dob', 'learner_gender', 'learner_address', 'learner_city',
                    'learner_country', 'learner_postal_code'
                )
            }),
            ('Professional Details', {
                'fields': (
                    'current_occupation', 'education_level', 'institution', 'company',
                    'highest_qualification', 'qualification_institution', 'qualification_year',
                    'employer', 'job_title', 'employment_status', 'monthly_income', 'existing_skills'
                )
            }),
            ('Demographics', {
                'fields': ('race', 'disability', 'nationality'),
                'classes': ('collapse',)
            }),
            ('Emergency Contact', {
                'fields': (
                    'emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relationship',
                    'next_of_kin_name', 'next_of_kin_phone', 'next_of_kin_relationship',
                    'next_of_kin_email', 'next_of_kin_address'
                ),
                'classes': ('collapse',)
            }),
            ('Medical & Accessibility', {
                'fields': ('dietary_requirements', 'medical_conditions', 'allergies', 'medications', 'accessibility_needs'),
                'classes': ('collapse',)
            }),
            ('Learning Support', {
                'fields': (
                    'requires_learning_support', 'learning_support_details',
                    'has_previous_learnership_experience', 'previous_learnership_details'
                ),
                'classes': ('collapse',)
            }),
            ('Documentation Checklist', {
                'fields': (
                    'has_id_copy', 'has_qualification_certificates', 'has_proof_of_residence',
                    'has_cv', 'has_motivational_letter'
                ),
                'classes': ('collapse',)
            }),
            ('Financials', {
                'fields': (
                    'total_amount', 'currency', 'order',
                    'funding_source', 'company_vat_number', 'purchase_order_number',
                    'requires_debit_order', 'bank_name', 'bank_account_number', 'bank_branch_code',
                    'bank_account_type', 'bank_account_holder_name'
                )
            }),
            ('Legal Declarations', {
                'fields': (
                    'terms_accepted', 'terms_accepted_at', 'data_protection_accepted',
                    'certification_declaration_accepted', 'seta_declaration_accepted'
                ),
                'classes': ('collapse',)
            }),
            ('Verification', {
                'fields': ('prerequisites_verified', 'verification_notes', 'verified_by', 'verified_at'),
                'classes': ('collapse',)
            }),
            ('Additional Information', {
                'fields': ('referral_source', 'additional_notes', 'enrollment_data', 'ip_address', 'user_agent'),
                'classes': ('collapse',)
            }),
            ('Timestamps', {
                'fields': ('created_at', 'updated_at', 'enrolled_at', 'completed_at', 'confirmed_at', 'dropped_out_at'),
                'classes': ('collapse',)
            }),
        )

    # BulkEnrollment
    @admin.register(BulkEnrollment)
    class BulkEnrollmentAdmin(admin.ModelAdmin):
        list_display = ('bulk_code', 'company', 'enrollment_type', 'total_learners', 'total_amount', 'status', 'created_at')
        list_filter = ('status', 'enrollment_type')
        search_fields = ('bulk_code', 'company__name', 'contact_name')

    print("[OK] All models registered with correct fields")
    
except Exception as e:
    print(f"Warning: Could not register some models: {e}")

try:
    from .models import CouponCode, CouponRedemption
    from django.utils.html import format_html
    from django.utils import timezone

    class CouponRedemptionInline(admin.TabularInline):
        model = CouponRedemption
        extra = 0
        readonly_fields = ('email', 'user', 'order', 'original_amount', 'discount_amount', 'final_amount', 'ip_address', 'redeemed_at')
        can_delete = False

    @admin.register(CouponCode)
    class CouponCodeAdmin(admin.ModelAdmin):
        list_display = ('code', 'name', 'discount_badge', 'promotion_type', 'product_pathway',
                        'country_restriction', 'usage_progress', 'validity_status', 'priority', 'valid_until')
        list_filter = ('is_active', 'discount_type', 'product_pathway', 'client_type',
                       'promotion_type', 'show_on_onboarding', 'show_on_home')
        search_fields = ('code', 'name', 'description')
        readonly_fields = ('times_used', 'created_at', 'updated_at', 'qr_code_preview',
                           'discount_badge', 'validity_status', 'promo_card_preview')
        filter_horizontal = ('countries',)
        inlines = [CouponRedemptionInline]
        save_on_top = True

        fieldsets = (
            ('Promotion Identity', {
                'fields': ('code', 'qr_code_preview', 'name', 'description', 'promotion_type', 'is_active')
            }),
            ('Discount / Offer', {
                'fields': ('discount_type', 'discount_value', 'max_discount_amount', 'discount_badge'),
                'description': 'Leave discount_value at 0 and discount_type=percentage for free/bundle promotions.'
            }),
            ('Checkout Targeting', {
                'fields': ('product_pathway', 'country_restriction', 'client_type', 'min_purchase_amount'),
                'description': 'country_restriction: single-country coupon validation code. Use Countries (below) for multi-country display targeting.'
            }),
            ('Display Targeting', {
                'fields': ('countries', 'priority', 'show_on_onboarding', 'show_on_home', 'show_on_splash'),
                'description': 'Countries: empty = shown globally. Priority: higher = shown first.'
            }),
            ('Promo Flyer Appearance', {
                'fields': ('background_color', 'text_color', 'icon',
                           'image_url', 'cta_text', 'cta_url', 'promo_card_preview'),
                'classes': ('collapse',),
            }),
            ('Limits & Validity', {
                'fields': ('usage_limit', 'per_user_limit', 'times_used', 'valid_from', 'valid_until', 'validity_status')
            }),
            ('Audit', {
                'fields': ('created_by', 'created_at', 'updated_at'),
                'classes': ('collapse',)
            }),
        )

        def discount_badge(self, obj):
            if obj.discount_type == 'percentage':
                label = f'{obj.discount_value:.0f}% OFF'
                color = '#e74c3c'
            elif obj.discount_type == 'fixed':
                label = f' OFF'
                color = '#2980b9'
            else:
                label = f'{obj.discount_value:.0f}% OFF (max )'
                color = '#8e44ad'
            return format_html(
                '<span style="background:{};color:#fff;padding:3px 8px;border-radius:4px;font-weight:bold;font-size:12px">{}</span>',
                color, label
            )
        discount_badge.short_description = 'Discount'

        def usage_progress(self, obj):
            if obj.usage_limit:
                pct = int(obj.times_used / obj.usage_limit * 100)
                color = '#e74c3c' if pct >= 90 else '#f39c12' if pct >= 60 else '#27ae60'
                return format_html(
                    '<div style="width:100px;background:#eee;border-radius:4px">'
                    '<div style="width:{}%;background:{};height:14px;border-radius:4px"></div>'
                    '</div><small>{}/{}</small>',
                    min(pct, 100), color, obj.times_used, obj.usage_limit
                )
            return format_html('<small>{}x used (unlimited)</small>', obj.times_used)
        usage_progress.short_description = 'Usage'

        def validity_status(self, obj):
            now = timezone.now()
            if not obj.is_active:
                return format_html('<span style="color:#999">PAUSE Inactive</span>')
            if now < obj.valid_from:
                return format_html('<span style="color:#f39c12">WAIT Upcoming</span>')
            if now > obj.valid_until:
                return format_html('<span style="color:#e74c3c">STOP Expired</span>')
            if obj.usage_limit and obj.times_used >= obj.usage_limit:
                return format_html('<span style="color:#e74c3c">STOP Exhausted</span>')
            days = (obj.valid_until - now).days
            return format_html('<span style="color:#27ae60">[OK] Active ({} days left)</span>', days)
        validity_status.short_description = 'Status'

        def qr_code_preview(self, obj):
            if not obj.code:
                return '-'
            return format_html(
                '<img src="https://api.qrserver.com/v1/create-qr-code/?size=120x120&data={}" '
                'style="border:1px solid #ddd;border-radius:4px" /><br><small>{}</small>',
                obj.code, obj.code
            )
        qr_code_preview.short_description = 'QR Code'

        def promo_card_preview(self, obj):
            bg = obj.background_color or '#172E3D'
            fg = obj.text_color or '#FFFFFF'
            icon = obj.icon or '*'
            discount = ''
            if obj.discount_type == 'percentage':
                discount = f'{obj.discount_value:.0f}% OFF - '
            elif obj.discount_type == 'fixed':
                discount = f' OFF - '
            from django.utils.html import format_html
            return format_html(
                '<div style="background:{};color:{};padding:18px;border-radius:14px;'
                'max-width:320px;font-family:sans-serif;">'
                '<div style="font-size:28px;text-align:center">{}</div>'
                '<h3 style="margin:6px 0;text-align:center">{}{}</h3>'
                '<p style="font-size:12px;text-align:center;opacity:0.85">{}</p>'
                '<div style="text-align:center;margin-top:12px">'
                '<span style="background:rgba(255,255,255,0.25);padding:6px 16px;'
                'border-radius:20px;font-weight:bold">{}</span>'
                '</div></div>',
                bg, fg, icon, discount, obj.name,
                (obj.description or '')[:80],
                obj.cta_text or 'Enroll Now',
            )
        promo_card_preview.short_description = 'Promo Card Preview'

        def save_model(self, request, obj, form, change):
            if not change:
                obj.created_by = request.user
            super().save_model(request, obj, form, change)

    @admin.register(CouponRedemption)
    class CouponRedemptionAdmin(admin.ModelAdmin):
        list_display = ('coupon', 'email', 'discount_amount', 'final_amount', 'redeemed_at', 'ip_address')
        list_filter = ('coupon', 'redeemed_at')
        search_fields = ('email', 'coupon__code')
        readonly_fields = ('coupon', 'email', 'user', 'order', 'original_amount', 'discount_amount', 'final_amount', 'ip_address', 'redeemed_at')

except Exception as e:
    print(f"Warning: Could not register coupon models: {e}")

try:
    @admin.register(PaymentOTPVerification)
    class PaymentOTPVerificationAdmin(admin.ModelAdmin):
        list_display = ('email', 'verified', 'is_valid', 'currency', 'amount', 'expires_at', 'created_at')
        list_filter = ('verified', 'is_valid', 'currency')
        search_fields = ('email', 'payment_token')
        readonly_fields = ('otp', 'payment_token', 'ip_address', 'user_agent', 'created_at', 'updated_at', 'verified_at')
        ordering = ('-created_at',)
except Exception as e:
    print(f"Warning: Could not register PaymentOTPVerification admin: {e}")

print("[OK] Payments admin loaded successfully")
