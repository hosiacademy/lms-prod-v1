# apps/payments/admin.py additions (or create new admin files)

# For appearance app
from apps.appearance.models import Theme

# For instructors app  
from apps.instructors.models import InstructorApplication, InstructorStatusLog, InstructorHoursClaim, InstructorOvertime, InstructorPayrollSummary

# For learnerships app
from apps.learnerships.models import PhaseCourse, CertificationTrack, CertificationItem

# For localization app
from apps.localization.models import State, City, LocalizedAnnouncement

# For organizations app
from apps.organizations.models import Company, CompanyLearner

# For payments app
from apps.payments.models import CartItem, ProviderCountryConfig, ProviderPaymentMethod, CountryPaymentLandscape, PaymentProviderIntegration, PaymentReference, AfricanCountry, AfricanBank, BankAccountTemplate, CompanyBankAccount, Administrator, ExecutiveCountryAssignment, SalesMarketingCountryAssignment, AdminChatRelationship, SystemAdminChatAccess, ContactVerificationOTP, AdminRoleRequest

# For users app
from apps.users.models import UserThemePreference, AuthOTP
