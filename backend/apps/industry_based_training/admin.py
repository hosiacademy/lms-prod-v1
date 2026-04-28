from django.contrib import admin
from .models import Industry, AiCertsCourse, Offering, IndustryTrainingEnrollment

class CourseInline(admin.TabularInline):
    model = Offering.courses.through
    extra = 1
    verbose_name = 'Course in Offering'
    verbose_name_plural = 'Courses in Offering'

@admin.register(IndustryTrainingEnrollment)
class IndustryTrainingEnrollmentAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'enrollment_type', 'content_object', 'status', 'payment_status', 'amount_paid', 'created_at']
    list_filter = ['enrollment_type', 'status', 'payment_status']
    search_fields = ['user__email', 'user__username', 'content_type__model']
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('User & Type', {
            'fields': ('user', 'enrollment_type')
        }),
        ('Content', {
            'fields': ('content_type', 'object_id', 'content_object')
        }),
        ('Payment', {
            'fields': ('payment_transaction', 'status', 'payment_status', 'amount_paid', 'currency')
        }),
        ('AICerts', {
            'fields': ('aicerts_enrollment_ids', 'aicerts_already_enrolled')
        }),
        ('Metadata', {
            'fields': ('metadata',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )

@admin.register(Industry)
class IndustryAdmin(admin.ModelAdmin):
    list_display = ['name', 'course_count', 'offering_count']
    search_fields = ['name']

    def course_count(self, obj):
        # Changed from obj.courses.count() to obj.industry_courses.count()
        return obj.industry_courses.count()
    course_count.short_description = 'Courses'

    def offering_count(self, obj):
        return obj.offerings.count()
    offering_count.short_description = 'Offerings'

@admin.register(AiCertsCourse)
class AiCertsCourseAdmin(admin.ModelAdmin):
    list_display = ['title', 'industry', 'price_usd', 'course_id', 'lms_id', 'last_synced']
    list_filter = ['industry', 'last_synced']
    search_fields = ['title', 'description', 'categories']
    list_editable = ['price_usd']

@admin.register(Offering)
class OfferingAdmin(admin.ModelAdmin):
    list_display = ['name', 'industry', 'price_usd', 'course_count', 'updated_at']
    list_filter = ['industry']
    search_fields = ['name', 'description']
    inlines = [CourseInline]

    def course_count(self, obj):
        return obj.courses.count()
    course_count.short_description = 'Courses in Bucket'