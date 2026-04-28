# apps/payments/models_admin.py
"""
Admin chat system models for country-based admin relationships and direct chats.
These models correspond to tables created in implement_admin_chat_system.py
"""

from django.db import models
from django.utils.translation import gettext_lazy as _
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.contrib.auth import get_user_model

User = get_user_model()


class Administrator(models.Model):
    """
    Administrator model mapping to the 'administrators' table.
    This table was created via SQL and needs to be represented in Django.
    """
    admin_id = models.CharField(
        max_length=100,
        unique=True,
        verbose_name=_("Admin ID"),
        help_text=_("Unique identifier like ADM-DB8E23C1")
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='administrator_profiles',
        verbose_name=_("User Account")
    )
    admin_type = models.CharField(
        max_length=50,
        choices=[
            ('hr', _('HR Administrator')),
            ('executive', _('Executive Administrator')),
            ('sales', _('Sales Administrator')),
            ('marketing', _('Marketing Administrator')),
            ('payment', _('Payment Administrator')),
            ('system', _('System Administrator')),
            ('general', _('General Administrator')),
        ],
        default='general',
        verbose_name=_("Administrator Type")
    )
    is_executive_admin = models.BooleanField(
        default=False,
        verbose_name=_("Executive Admin"),
        help_text=_("Has executive admin privileges")
    )
    is_sales_admin = models.BooleanField(
        default=False,
        verbose_name=_("Sales Admin"),
        help_text=_("Has sales admin privileges")
    )
    is_marketing_admin = models.BooleanField(
        default=False,
        verbose_name=_("Marketing Admin"),
        help_text=_("Has marketing admin privileges")
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Is this administrator account active?")
    )
    permissions = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("Custom Permissions"),
        help_text=_("Additional role-specific permissions")
    )
    assigned_countries = models.ManyToManyField(
        'localization.Country',
        through='ExecutiveCountryAssignment',
        blank=True,
        related_name='executive_admins',
        verbose_name=_("Assigned Countries")
    )
    notes = models.TextField(
        blank=True,
        verbose_name=_("Notes"),
        help_text=_("Administrative notes about this admin")
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'administrators'
        verbose_name = _("Administrator")
        verbose_name_plural = _("Administrators")
        ordering = ['admin_type', 'admin_id']

    def __str__(self):
        return f"{self.admin_id} - {self.get_admin_type_display()}"

    @property
    def display_name(self):
        return f"{self.admin_id} ({self.user.name or self.user.username})"


class ExecutiveCountryAssignment(models.Model):
    """
    Executive admin country assignments for country-level coverage.
    Maps to 'executive_country_assignments' table.
    """
    executive_admin = models.ForeignKey(
        Administrator,
        on_delete=models.CASCADE,
        related_name='executive_country_assignments',
        verbose_name=_("Executive Administrator"),
        help_text=_("Executive admin assigned to this country")
    )
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.CASCADE,
        related_name='executive_admin_assignments',
        verbose_name=_("Country")
    )
    region_level = models.CharField(
        max_length=50,
        choices=[
            ('country', _('Country Level')),
            ('region', _('Regional Level')),
            ('subregion', _('Sub-Region Level')),
            ('province', _('Province/State Level')),
        ],
        default='country',
        verbose_name=_("Region Level")
    )
    assignment_type = models.CharField(
        max_length=50,
        choices=[
            ('executive_coverage', _('Executive Coverage')),
            ('supervision', _('Supervision')),
            ('accountability', _('Accountability')),
            ('support', _('Support')),
        ],
        default='executive_coverage',
        verbose_name=_("Assignment Type")
    )
    assigned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_executive_countries',
        verbose_name=_("Assigned By")
    )
    assigned_at = models.DateTimeField(default=timezone.now)
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    coverage_area = models.TextField(
        blank=True,
        verbose_name=_("Coverage Area"),
        help_text=_("Specific geographic area coverage details")
    )
    responsibilities = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Responsibilities"),
        help_text=_("List of responsibilities for this assignment")
    )
    notes = models.TextField(blank=True, verbose_name=_("Notes"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'executive_country_assignments'
        verbose_name = _("Executive Country Assignment")
        verbose_name_plural = _("Executive Country Assignments")
        unique_together = ['executive_admin', 'country']
        ordering = ['country__name', 'executive_admin__admin_id']

    def __str__(self):
        return f"{self.executive_admin} → {self.country.name}"

    @property
    def coverage_type(self):
        """Get human-readable coverage type"""
        if self.region_level == 'country':
            return _("Country Coverage")
        elif self.region_level == 'region':
            return _("Regional Coverage")
        elif self.region_level == 'subregion':
            return _("Sub-Regional Coverage")
        return _("Specific Area Coverage")


class SalesMarketingCountryAssignment(models.Model):
    """
    Sales and marketing admin country assignments for business development.
    Maps to 'sales_marketing_country_assignments' table.
    """
    sales_marketing_admin = models.ForeignKey(
        Administrator,
        on_delete=models.CASCADE,
        related_name='sales_marketing_country_assignments',
        verbose_name=_("Sales/Marketing Administrator"),
        help_text=_("Sales or marketing admin assigned to this country")
    )
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.CASCADE,
        related_name='sales_marketing_assignments',
        verbose_name=_("Country")
    )
    admin_type = models.CharField(
        max_length=50,
        choices=[
            ('sales', _('Sales Admin')),
            ('marketing', _('Marketing Admin')),
            ('both', _('Sales & Marketing Admin')),
        ],
        default='sales',
        verbose_name=_("Admin Type")
    )
    assignment_type = models.CharField(
        max_length=50,
        choices=[
            ('sales_coverage', _('Sales Coverage')),
            ('market_development', _('Market Development')),
            ('client_acquisition', _('Client Acquisition')),
            ('brand_promotion', _('Brand Promotion')),
        ],
        default='sales_coverage',
        verbose_name=_("Assignment Type")
    )
    assigned_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_sales_marketing_countries',
        verbose_name=_("Assigned By")
    )
    assigned_at = models.DateTimeField(default=timezone.now)
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    sales_target = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name=_("Sales Target"),
        help_text=_("Sales target amount for this country")
    )
    marketing_budget = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        null=True,
        blank=True,
        verbose_name=_("Marketing Budget"),
        help_text=_("Marketing budget for this country")
    )
    performance_metrics = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("Performance Metrics"),
        help_text=_("KPIs and performance metrics for this assignment")
    )
    notes = models.TextField(blank=True, verbose_name=_("Notes"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'sales_marketing_country_assignments'
        verbose_name = _("Sales/Marketing Country Assignment")
        verbose_name_plural = _("Sales/Marketing Country Assignments")
        unique_together = ['sales_marketing_admin', 'country']
        ordering = ['country__name', 'sales_marketing_admin__admin_id']

    def __str__(self):
        return f"{self.sales_marketing_admin} ({self.get_admin_type_display()}) → {self.country.name}"

    @property
    def is_sales_admin(self):
        return self.admin_type in ['sales', 'both']

    @property
    def is_marketing_admin(self):
        return self.admin_type in ['marketing', 'both']


class AdminChatRelationship(models.Model):
    """
    Chat relationship between administrators for direct messaging.
    Maps to 'admin_chat_relationships' table.
    """
    admin1 = models.ForeignKey(
        Administrator,
        on_delete=models.CASCADE,
        related_name='chat_relationships_as_admin1',
        verbose_name=_("Admin 1")
    )
    admin2 = models.ForeignKey(
        Administrator,
        on_delete=models.CASCADE,
        related_name='chat_relationships_as_admin2',
        verbose_name=_("Admin 2")
    )
    relationship_type = models.CharField(
        max_length=50,
        choices=[
            ('country_linked', _('Country-Linked')),
            ('hierarchical', _('Hierarchical (HR→Executive)')),
            ('functional', _('Functional Collaboration')),
            ('operational', _('Operational Coordination')),
            ('emergency', _('Emergency Contact')),
        ],
        default='country_linked',
        verbose_name=_("Relationship Type")
    )
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='admin_chat_relationships',
        verbose_name=_("Linked Country"),
        help_text=_("Country linking these admins (if applicable)")
    )
    can_chat_directly = models.BooleanField(
        default=True,
        verbose_name=_("Can Chat Directly"),
        help_text=_("Allow direct 1-on-1 chats between these admins")
    )
    chat_permissions = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("Chat Permissions"),
        help_text=_("Specific permissions for this chat relationship")
    )
    chat_room = models.ForeignKey(
        'communication.ChatRoom',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='admin_chat_relationships',
        verbose_name=_("Chat Room"),
        help_text=_("Socket.io chat room for this relationship")
    )
    last_chat_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Last Chat At"),
        help_text=_("When was the last chat between these admins")
    )
    chat_count = models.IntegerField(
        default=0,
        verbose_name=_("Chat Count"),
        help_text=_("Number of chats between these admins")
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Is this chat relationship active?")
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'admin_chat_relationships'
        verbose_name = _("Admin Chat Relationship")
        verbose_name_plural = _("Admin Chat Relationships")
        unique_together = ['admin1', 'admin2', 'country']
        ordering = ['-last_chat_at', '-created_at']

    def __str__(self):
        return f"{self.admin1.admin_id} ↔ {self.admin2.admin_id} ({self.get_relationship_type_display()})"

    def save(self, *args, **kwargs):
        # Ensure admin1 and admin2 are ordered consistently
        if self.admin1_id and self.admin2_id and self.admin1_id > self.admin2_id:
            self.admin1_id, self.admin2_id = self.admin2_id, self.admin1_id
        super().save(*args, **kwargs)

    @property
    def chat_partners(self):
        """Get both admins as a list"""
        return [self.admin1, self.admin2]

    def update_chat_stats(self):
        """Update chat statistics"""
        self.last_chat_at = timezone.now()
        self.chat_count += 1
        self.save()


class SystemAdminChatAccess(models.Model):
    """
    Direct chat access to system administrator for issue reporting.
    Maps to 'system_admin_chat_access' table.
    """
    admin = models.ForeignKey(
        Administrator,
        on_delete=models.CASCADE,
        related_name='system_admin_chat_accesses',
        verbose_name=_("Administrator"),
        help_text=_("Admin who has system admin chat access")
    )
    system_admin = models.ForeignKey(
        Administrator,
        on_delete=models.CASCADE,
        related_name='admin_chat_accesses',
        verbose_name=_("System Administrator"),
        help_text=_("System admin available for support")
    )
    chat_room = models.ForeignKey(
        'communication.ChatRoom',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='system_admin_chat_accesses',
        verbose_name=_("Chat Room"),
        help_text=_("Socket.io chat room for system admin support")
    )
    issue_category = models.CharField(
        max_length=100,
        choices=[
            ('technical', _('Technical Issue')),
            ('billing', _('Billing/Payment Issue')),
            ('access', _('Access/Login Issue')),
            ('data', _('Data/Report Issue')),
            ('system', _('System Performance')),
            ('security', _('Security Concern')),
            ('feature', _('Feature Request')),
            ('complaint', _('Complaint')),
            ('other', _('Other')),
        ],
        blank=True,
        verbose_name=_("Issue Category"),
        help_text=_("General category of issues discussed")
    )
    issue_priority = models.CharField(
        max_length=20,
        choices=[
            ('critical', _('Critical')),
            ('high', _('High')),
            ('normal', _('Normal')),
            ('low', _('Low')),
        ],
        default='normal',
        verbose_name=_("Issue Priority"),
        help_text=_("Priority level for issues")
    )
    issue_description = models.TextField(
        blank=True,
        verbose_name=_("Issue Description"),
        help_text=_("General description of typical issues")
    )
    last_report_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Last Report At"),
        help_text=_("When was the last issue reported")
    )
    report_count = models.IntegerField(
        default=0,
        verbose_name=_("Report Count"),
        help_text=_("Number of issues reported through this channel")
    )
    resolution_status = models.CharField(
        max_length=50,
        choices=[
            ('open', _('Open')),
            ('in_progress', _('In Progress')),
            ('resolved', _('Resolved')),
            ('escalated', _('Escalated')),
            ('closed', _('Closed')),
        ],
        default='open',
        verbose_name=_("Resolution Status"),
        help_text=_("Current status of reported issues")
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Is this chat access channel active?")
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'system_admin_chat_access'
        verbose_name = _("System Admin Chat Access")
        verbose_name_plural = _("System Admin Chat Access")
        unique_together = ['admin', 'system_admin']
        ordering = ['-last_report_at', 'admin__admin_id']

    def __str__(self):
        return f"{self.admin.admin_id} → {self.system_admin.admin_id}"

    def record_report(self, issue_category=None, priority=None, description=None):
        """Record a new issue report"""
        self.last_report_at = timezone.now()
        self.report_count += 1
        if issue_category:
            self.issue_category = issue_category
        if priority:
            self.issue_priority = priority
        if description:
            self.issue_description = description
        self.resolution_status = 'open'
        self.save()

    @property
    def is_resolved(self):
        return self.resolution_status in ['resolved', 'closed']