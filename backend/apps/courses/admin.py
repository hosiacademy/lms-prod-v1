from django.contrib import admin
from .models import CourseProvider, Course

@admin.register(CourseProvider)
class CourseProviderAdmin(admin.ModelAdmin):
    list_display = ("name", "code", "active")
    list_filter = ("active",)
    search_fields = ("name", "code")


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ("title", "provider", "active")
    list_filter = ("provider", "active")
    search_fields = ("title",)
