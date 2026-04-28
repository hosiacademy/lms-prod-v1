from django.contrib import admin
from django.urls import path
from django.shortcuts import render
from django.utils.translation import gettext_lazy as _
from django.db.models import Sum, Count
from django.utils import timezone
from datetime import timedelta

class HosiAdminSite(admin.AdminSite):
    """Custom admin site for Hosi Academy with integrated Executive Dashboard"""
    site_header = _("HOSI TECHNOLOGIES | LMS Administration")
    site_title = _("Hosi Academy Admin")
    index_title = _("LMS Management Console")

    def get_each_context(self, request):
        context = super().each_context(request)
        context['version'] = '1.2.0'
        context['environment'] = 'Production'
        
        # Add stats if it's the index page
        if request.path == '/admin/':
            context.update(self.get_stats())
            
        return context

    def index(self, request, extra_context=None):
        """Override index to include stats"""
        if extra_context is None:
            extra_context = {}
        extra_context.update(self.get_stats())
        return super().index(request, extra_context)

    def get_stats(self):
        """Helper to get dashboard statistics"""
        from apps.users.models import User
        from apps.payments.models import Transaction, Enrollment
        from apps.masterclasses.models import Masterclass
        
        total_students = User.objects.filter(role='student').count()
        total_revenue = Transaction.objects.filter(status='success').aggregate(Sum('amount'))['amount__sum'] or 0
        total_enrollments = Enrollment.objects.count()
        
        return {
            'stats': {
                'total_students': f"{total_students:,}",
                'total_revenue': f"${total_revenue/1000:,.1f}k" if total_revenue >= 1000 else f"${total_revenue:,.2f}",
                'total_enrollments': f"{total_enrollments:,}",
                'revenue_growth': "↑ 12% this month", # Placeholder for growth logic
            }
        }

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('dashboard/', self.admin_view(self.dashboard_view), name='hosi_dashboard'),
        ]
        return custom_urls + urls

    def dashboard_view(self, request):
        """Main executive dashboard showing cross-app statistics"""
        # We can dynamically import models here to avoid circular imports
        from apps.aicerts_courses.models import AiCertsCourse
        from apps.masterclasses.models import Masterclass
        from apps.learnerships.models import LearnershipProgramme
        from apps.users.models import User
        from apps.payments.models import Transaction
        
        # Stats
        total_students = User.objects.filter(role='student').count()
        total_revenue = Transaction.objects.filter(status='success').aggregate(Sum('amount'))['amount__sum'] or 0
        active_masterclasses = Masterclass.objects.filter(status='ongoing').count()
        available_courses = AiCertsCourse.objects.filter(is_offered=True).count()
        
        # Recent Activities
        recent_users = User.objects.all().order_by('-date_joined')[:5]
        
        context = {
            **self.each_context(request),
            'title': _('Hosi Executive Dashboard'),
            'total_students': total_students,
            'total_revenue': total_revenue,
            'active_masterclasses': active_masterclasses,
            'available_courses': available_courses,
            'recent_users': recent_users,
        }
        return render(request, 'admin/hosi_dashboard.html', context)

hosi_admin_site = HosiAdminSite(name='hosi_admin')

# Branding the default site too just in case
admin.site.site_header = "Hosi Academy LMS Administration"
admin.site.site_title = "Hosi Academy Admin"
admin.site.index_title = "Welcome to Hosi Academy LMS"
