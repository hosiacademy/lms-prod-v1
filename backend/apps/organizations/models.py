from django.db import models
from django.core.validators import EmailValidator, RegexValidator
from django.conf import settings
from django.utils.translation import gettext_lazy as _


class HrDepartment(models.Model):
    name = models.CharField(max_length=191)
    details = models.CharField(max_length=191, blank=True, null=True)
    user = models.CharField(max_length=191, blank=True, null=True)
    status = models.BooleanField(default=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'hr_departments'


class Staff(models.Model):
    employee_id = models.CharField(max_length=50, blank=True, null=True)
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, default=1)
    department = models.ForeignKey(HrDepartment, on_delete=models.CASCADE, default=1)
    showroom_id = models.IntegerField(default=1)
    warehouse_id = models.IntegerField(default=1)
    phone = models.CharField(max_length=20, blank=True, null=True)
    bank_name = models.CharField(max_length=255, blank=True, null=True)
    bank_branch_name = models.CharField(max_length=255, blank=True, null=True)
    bank_account_name = models.CharField(max_length=255, blank=True, null=True)
    bank_account_no = models.CharField(max_length=255, blank=True, null=True)
    current_address = models.CharField(max_length=255, blank=True, null=True)
    permanent_address = models.CharField(max_length=255, blank=True, null=True)
    basic_salary = models.CharField(max_length=255, blank=True, null=True)
    employment_type = models.CharField(max_length=150, blank=True, null=True)
    opening_balance = models.FloatField(default=0.0)
    provisional_months = models.SmallIntegerField(default=0)
    date_of_joining = models.DateField(blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    leave_applicable_date = models.DateField(blank=True, null=True)
    carry_forward = models.IntegerField(default=0)
    is_carry_active = models.BooleanField(default=False)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    deleted_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'staffs'

class Company(models.Model):
    name = models.CharField(max_length=255, verbose_name=_("Company Name"), help_text=_("Official registered company name"))
    registration_number = models.CharField(max_length=100, unique=True, verbose_name=_("Company Registration Number"), help_text=_("Official business registration number"))
    tax_number = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Tax/VAT Number"), help_text=_("Tax identification number"))
    
    email = models.EmailField(max_length=255, validators=[EmailValidator()], verbose_name=_("Company Email"))
    phone = models.CharField(max_length=20, validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$', message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed.")], verbose_name=_("Phone Number"))
    website = models.URLField(max_length=255, blank=True, null=True, verbose_name=_("Company Website"))
    
    address = models.TextField(verbose_name=_("Physical Address"))
    city = models.CharField(max_length=100, verbose_name=_("City"))
    country = models.CharField(max_length=100, verbose_name=_("Country"))
    postal_code = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Postal/ZIP Code"))
    
    # Contact Person
    billing_contact_name = models.CharField(max_length=255, verbose_name=_("Billing Contact Name"))
    billing_contact_email = models.EmailField(max_length=255, validators=[EmailValidator()], verbose_name=_("Billing Contact Email"))
    billing_contact_phone = models.CharField(max_length=20, validators=[RegexValidator(regex=r'^\+?1?\d{9,15}$', message="Phone number must be entered in the format: '+999999999'. Up to 15 digits allowed.")], verbose_name=_("Billing Contact Phone"))
    
    # Business Details
    industry = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Industry/Sector"))
    company_size = models.CharField(max_length=20, blank=True, null=True, choices=[
        ('1-10', '1-10 employees'),
        ('11-50', '11-50 employees'),
        ('51-200', '51-200 employees'),
        ('201-500', '201-500 employees'),
        ('501-1000', '501-1000 employees'),
        ('1000+', '1000+ employees')
    ], verbose_name=_("Company Size"))
    payment_terms = models.CharField(max_length=50, default='immediate', choices=[
        ('immediate', 'Immediate Payment'),
        ('net_7', 'Net 7 Days'),
        ('net_15', 'Net 15 Days'),
        ('net_30', 'Net 30 Days'),
        ('net_60', 'Net 60 Days')
    ], verbose_name=_("Payment Terms"))
    preferred_payment_method = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Preferred Payment Method"))
    
    # Status
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    is_verified = models.BooleanField(default=False, verbose_name=_("Verified"), help_text=_("Company verification status by admin"))
    account_manager = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='managed_companies', limit_choices_to={'role_id': 1}, verbose_name=_("Account Manager"))
    
    notes = models.TextField(blank=True, null=True, verbose_name=_("Internal Notes"), help_text=_("Internal notes visible only to admins"))
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'companies'
        verbose_name = _("Company")
        verbose_name_plural = _("Companies")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['registration_number']),
            models.Index(fields=['is_active', 'is_verified']),
        ]

    def __str__(self):
        return self.name


class CompanyLearner(models.Model):
    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name='learners', verbose_name=_("Company"))
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='company_memberships', verbose_name=_("Learner"))
    
    employee_id = models.CharField(max_length=50, blank=True, null=True, verbose_name=_("Employee ID"), help_text=_("Company's internal employee ID"))
    department = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Department"))
    position = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Job Title/Position"))
    
    manager_name = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Manager Name"))
    manager_email = models.EmailField(max_length=255, blank=True, null=True, validators=[EmailValidator()], verbose_name=_("Manager Email"))
    
    is_active = models.BooleanField(default=True, verbose_name=_("Active"))
    joined_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Joined At"))
    left_at = models.DateTimeField(blank=True, null=True, verbose_name=_("Left At"))

    class Meta:
        db_table = 'company_learners'
        verbose_name = _("Company Learner")
        verbose_name_plural = _("Company Learners")
        unique_together = ['company', 'user']
        ordering = ['-joined_at']
        indexes = [
            models.Index(fields=['company', 'is_active']),
            models.Index(fields=['user', 'is_active']),
        ]

    def __str__(self):
        return f"{self.user} - {self.company}"
