# apps/organizations/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse

from .models import HrDepartment, Staff


@admin.register(HrDepartment)
class HrDepartmentAdmin(admin.ModelAdmin):
    """
    Admin interface for HR Departments (from hr_departments table).
    """
    list_display = ('name', 'status', 'staff_count')
    list_filter = ('status',)
    search_fields = ('name', 'details')
    ordering = ('name',)

    def staff_count(self, obj):
        count = obj.staff_set.count()
        if count > 0:
            url = (
                reverse("admin:organizations_staff_changelist")
                + f"?department_id__id__exact={obj.id}"
            )
            return format_html('<a href="{}">{}</a>', url, count)
        return 0
    staff_count.short_description = "Staff Members"


@admin.register(Staff)
class StaffAdmin(admin.ModelAdmin):
    """
    Admin interface for Staff members (from staffs table).
    Linked to real User model for easy navigation.
    """
    list_display = (
        'employee_id', 'user_link', 'department_link',
        'phone', 'employment_type', 'basic_salary',
        'date_of_joining', 'is_active_display'
    )
    list_filter = (
        'employment_type', 'department', 'provisional_months',
        'is_carry_active', 'date_of_joining'
    )
    search_fields = (
        'employee_id', 'user__name', 'user__email', 'user__username',
        'phone', 'bank_account_no'
    )
    readonly_fields = (
        'opening_balance', 'created_at', 'updated_at', 'deleted_at'
    )
    autocomplete_fields = ('user', 'department')
    ordering = ('-date_of_joining',)

    fieldsets = (
        ("Employee Identification", {
            'fields': ('employee_id', 'user', 'department')
        }),
        ("Personal & Contact", {
            'fields': ('phone', 'current_address', 'permanent_address',
                       'date_of_birth', 'date_of_joining')
        }),
        ("Employment Details", {
            'fields': ('employment_type', 'basic_salary', 'provisional_months',
                       'leave_applicable_date', 'carry_forward', 'is_carry_active')
        }),
        ("Banking Information", {
            'fields': ('bank_name', 'bank_branch_name', 'bank_account_name',
                       'bank_account_no'),
            'classes': ('collapse',),
        }),
        ("Financial", {
            'fields': ('opening_balance',),
            'classes': ('collapse',),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at', 'deleted_at'),
            'classes': ('collapse',),
        }),
    )

    def user_link(self, obj):
        if obj.user:
            url = reverse("admin:users_user_change", args=[obj.user.id])
            return format_html('<a href="{}">{}</a>', url, obj.user.name or obj.user.username or obj.user.email)
        return "-"
    user_link.short_description = "User Account"

    def department_link(self, obj):
        if obj.department:
            url = reverse("admin:organizations_hrdepartment_change", args=[obj.department.id])
            return format_html('<a href="{}">{}</a>', url, obj.department.name)
        return "-"
    department_link.short_description = "Department"

    def is_active_display(self, obj):
        # Assuming active if no deleted_at (soft delete pattern)
        return obj.deleted_at is None
    is_active_display.boolean = True
    is_active_display.short_description = "Active"

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'department')