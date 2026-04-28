"""
Add to backend/apps/payments/admin.py
"""
from django.contrib import admin
from .quotation_models import ClientQuotation, QuotationItem, QuotationActivityLog, QuotationTemplate

@admin.register(ClientQuotation)
class ClientQuotationAdmin(admin.ModelAdmin):
    list_display = (
        'quotation_number', 'client_name', 'client_email', 'training_type',
        'training_item_name', 'total_amount', 'status', 'email_sent', 'sms_sent',
        'created_at'
    )
    list_filter = ('status', 'training_type', 'client_country', 'email_sent', 'sms_sent')
    search_fields = ('quotation_number', 'client_name', 'client_email', 'client_company')
    readonly_fields = ('quotation_number', 'created_at', 'updated_at', 'expires_at')
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Quotation Identity', {
            'fields': ('quotation_number', 'status', 'created_by')
        }),
        ('Client Information', {
            'fields': ('client_name', 'client_email', 'client_phone', 'client_company', 'client_country')
        }),
        ('Training Selection', {
            'fields': ('training_type', 'course_name', 'masterclass_name', 'learnership_name')
        }),
        ('Pricing', {
            'fields': (
                'base_price', 'quantity', 'discount_percentage', 'discount_amount',
                'subtotal', 'vat_amount', 'total_amount',
                'local_currency', 'local_amount', 'exchange_rate'
            )
        }),
        ('SmatPay Integration', {
            'fields': ('smatpay_payment_link', 'smatpay_reference'),
            'classes': ('collapse',)
        }),
        ('Delivery Status', {
            'fields': ('email_sent', 'email_sent_at', 'sms_sent', 'sms_sent_at'),
        }),
        ('Tracking', {
            'fields': ('viewed_at', 'viewed_count'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at', 'expires_at'),
            'classes': ('collapse',)
        }),
    )
    
    actions = ['send_email_action', 'send_sms_action', 'mark_accepted', 'mark_paid']
    
    def send_email_action(self, request, queryset):
        for quotation in queryset:
            # Trigger email send
            from .views.quotation_views import SendQuotationEmailView
            view = SendQuotationEmailView()
            view._send_email(quotation)
            quotation.email_sent = True
            quotation.email_sent_at = timezone.now()
            quotation.save()
        self.message_user(request, f'{queryset.count()} quotation(s) sent via email')
    send_email_action.short_description = 'Send selected quotations via email'
    
    def send_sms_action(self, request, queryset):
        for quotation in queryset:
            if quotation.client_phone:
                view = SendQuotationSMSView()
                view._send_sms(quotation)
                quotation.sms_sent = True
                quotation.sms_sent_at = timezone.now()
                quotation.save()
        self.message_user(request, f'{queryset.count()} quotation(s) sent via SMS')
    send_sms_action.short_description = 'Send selected quotations via SMS'
    
    def mark_accepted(self, request, queryset):
        queryset.update(status='accepted')
        self.message_user(request, f'{queryset.count()} quotation(s) marked as accepted')
    mark_accepted.short_description = 'Mark as accepted'
    
    def mark_paid(self, request, queryset):
        queryset.update(status='paid')
        self.message_user(request, f'{queryset.count()} quotation(s) marked as paid')
    mark_paid.short_description = 'Mark as paid'


@admin.register(QuotationItem)
class QuotationItemAdmin(admin.ModelAdmin):
    list_display = ('quotation', 'description', 'quantity', 'unit_price', 'total_price')
    list_filter = ('quotation__status',)
    search_fields = ('quotation__quotation_number', 'description')


@admin.register(QuotationActivityLog)
class QuotationActivityLogAdmin(admin.ModelAdmin):
    list_display = ('quotation', 'activity_type', 'description', 'created_at')
    list_filter = ('activity_type',)
    search_fields = ('quotation__quotation_number', 'description')
    readonly_fields = ('created_at',)
    date_hierarchy = 'created_at'


@admin.register(QuotationTemplate)
class QuotationTemplateAdmin(admin.ModelAdmin):
    list_display = ('name', 'training_type', 'is_active', 'validity_days', 'created_at')
    list_filter = ('training_type', 'is_active')
    search_fields = ('name',)
