# Role-Based Dashboard with Multi-Country Support

## Overview

This implementation provides role-based access control for admin dashboards with **multi-country support**. All admin roles (HR Admin, Payment Admin, Executive Admin) can be assigned to multiple countries. **System Admin (superuser)** has unrestricted access to all countries and cannot be restricted.

## Architecture

### Files Created/Modified

1. **`apps/payments/models.py`** - Added `AdminCountryAccess` model
2. **`apps/payments/admin.py`** - Admin interface for country assignment
3. **`apps/users/permissions.py`** - Permission classes for multi-country access
4. **`apps/users/filters.py`** - Country filtering utilities with multi-country support
5. **`apps/users/dashboard_serializers.py`** - Updated with multi-country filtering
6. **`apps/users/views_dashboard.py`** - Dashboard API endpoints with country selection
7. **`apps/users/urls.py`** - Updated with dashboard routes
8. **`apps/users/tests_dashboard_multicountry.py`** - Test cases
9. **`apps/payments/migrations/0014_admincountryaccess.py`** - Migration for new model

## User Roles

### System Admin (Superuser)
- **Unrestricted access** to all countries
- Cannot be restricted by country assignments
- Highest level of access
- `is_superuser=True`

### HR Admin (`role_type='hr_admin'`)
- Can be assigned to **one, multiple, or all countries**
- If no countries assigned: access to all countries by default
- Can select specific country to view (if multi-country)
- Access endpoints: `/api/v1/users/dashboard/`, `/api/v1/users/dashboard/hr-admin/`

### Payment Admin (`role_type='payment_admin'`)
- Can be assigned to **one, multiple, or all countries**
- If no countries assigned: access to all countries by default
- Can select specific country to view (if multi-country)
- Access endpoints: `/api/v1/users/dashboard/`, `/api/v1/users/dashboard/payment-admin/`

### Executive Admin (`role_type='executive_admin'`)
- Can be assigned to **one, multiple, or all countries**
- If no countries assigned: access to all countries by default
- Can select specific country to view (if multi-country)
- Access endpoints: `/api/v1/users/dashboard/`, `/api/v1/users/dashboard/executive/`

## Database Model

### AdminCountryAccess

```python
class AdminCountryAccess(models.Model):
    """
    Many-to-many relationship between AdminRole and Country.
    Allows assigning specific countries to admin roles.
    If no countries are assigned, admin has access to all countries.
    """
    admin_role = ForeignKey(AdminRole, related_name='country_accesses')
    country = ForeignKey(Country, related_name='admin_role_accesses')
    is_active = BooleanField(default=True)
    granted_at = DateTimeField(auto_now_add=True)
    granted_by = ForeignKey(User, on_delete=models.SET_NULL, null=True)
    revoked_at = DateTimeField(null=True, blank=True)
    revoked_by = ForeignKey(User, on_delete=models.SET_NULL, null=True)
    notes = TextField(blank=True)
```

## API Endpoints

### Main Dashboard Endpoint
```
GET /api/v1/users/dashboard/
```
Returns role-appropriate dashboard data with automatic country filtering.

**Query Parameters:**
- `country`: Optional country ID to filter by (for multi-country admins)

**Response Example (Multi-Country HR Admin):**
```json
{
  "role": "admin",
  "system_stats": {
    "total_users": 300,
    "total_students": 250,
    "total_instructors": 40,
    "total_admins": 10
  },
  "country_context": {
    "restricted": true,
    "country_id": null,
    "country_name": null,
    "can_view_all": false,
    "allowed_countries": [
      {"id": 1, "name": "South Africa", "code": "ZA"},
      {"id": 2, "name": "Kenya", "code": "KE"}
    ],
    "is_multi_country": true,
    "has_country_assignment": true
  },
  "user_role": {
    "role_id": 1,
    "role_name": "Admin",
    "is_superuser": false,
    "is_system_admin": false,
    "is_hr_admin": true,
    "is_payment_admin": false,
    "is_executive_admin": false,
    "allowed_countries_count": 2,
    "is_multi_country_admin": true
  }
}
```

### Filter by Specific Country (Multi-Country Admin)
```
GET /api/v1/users/dashboard/?country=1
```

**Response Example:**
```json
{
  "role": "admin",
  "system_stats": {
    "total_users": 150,
    "total_students": 120
  },
  "country_context": {
    "restricted": true,
    "country_id": 1,
    "country_name": "South Africa",
    "can_view_all": false,
    "allowed_countries": [
      {"id": 1, "name": "South Africa", "code": "ZA"},
      {"id": 2, "name": "Kenya", "code": "KE"}
    ],
    "is_multi_country": true,
    "selected_country_id": 1
  }
}
```

### HR Admin Specific Endpoint
```
GET /api/v1/users/dashboard/hr-admin/?country=1
```
Requires HR Admin role. Returns dashboard data with optional country filtering.

### Payment Admin Specific Endpoint
```
GET /api/v1/users/dashboard/payment-admin/?country=1
```
Requires Payment Admin role. Returns dashboard data with optional country filtering.

### Executive Dashboard Endpoint
```
GET /api/v1/users/dashboard/executive/?country=1
```
Requires Executive Admin role or System Admin. Returns dashboard data.

### Country Access Info Endpoint
```
GET /api/v1/users/dashboard/country-access/
```
Returns information about which countries the user can access.

**Response Example:**
```json
{
  "country_access": {
    "restricted": true,
    "country_id": null,
    "country_name": null,
    "can_view_all": false,
    "allowed_countries": [
      {"id": 1, "name": "South Africa", "code": "ZA"},
      {"id": 2, "name": "Kenya", "code": "KE"}
    ],
    "is_multi_country": true,
    "has_country_assignment": true
  },
  "allowed_countries": [
    {"id": 1, "name": "South Africa", "code": "ZA"},
    {"id": 2, "name": "Kenya", "code": "KE"}
  ],
  "user_country": {
    "id": 1,
    "name": "South Africa",
    "code": "ZA"
  },
  "role_countries": {
    "hr_admin": [
      {"id": 1, "name": "South Africa", "code": "ZA"},
      {"id": 2, "name": "Kenya", "code": "KE"}
    ]
  }
}
```

### Country Selection Validation
```
GET /api/v1/users/dashboard/country-selection/<country_id>/
```
Validates if user can access a specific country.

## Usage

### Setting Up Multi-Country HR Admin

1. Create admin role:
```python
from django.contrib.auth import get_user_model
from apps.payments.models import AdminRole, AdminCountryAccess
from apps.localization.models import Country

User = get_user_model()

# Create user
hr_admin = User.objects.create_user(
    username='hr_south_africa_kenya',
    email='hr.za.ke@hosi.academy',
    password='SecurePassword123!',
    role_id=1,
    name='HR Admin - SA & Kenya'
)

# Assign HR Admin role
hr_role = AdminRole.objects.create(
    user=hr_admin,
    role_type='hr_admin',
    is_active=True,
    assigned_by=request.user  # Current admin assigning the role
)

# Assign multiple countries
country_za = Country.objects.get(code='ZA')
country_ke = Country.objects.get(code='KE')

AdminCountryAccess.objects.create(
    admin_role=hr_role,
    country=country_za,
    is_active=True,
    granted_by=request.user
)

AdminCountryAccess.objects.create(
    admin_role=hr_role,
    country=country_ke,
    is_active=True,
    granted_by=request.user
)
```

### Setting Up Admin with All Countries (No Restrictions)

```python
# Create admin role WITHOUT country assignments
exec_role = AdminRole.objects.create(
    user=exec_admin,
    role_type='executive_admin',
    is_active=True
)
# No AdminCountryAccess entries = access to ALL countries
```

### Setting Up System Admin

```python
# System Admin (superuser) - unrestricted access
system_admin = User.objects.create_superuser(
    username='system',
    email='system@hosi.academy',
    password='SecurePassword123!',
    name='System Administrator'
)
# No AdminRole or AdminCountryAccess needed
# Superusers automatically have unrestricted access
```

### Using the Filters in Custom Queries

```python
from apps.users.filters import (
    get_user_country_filter,
    filter_queryset_by_user_country,
    get_allowed_countries,
    can_user_access_country
)

# Get country filter Q object (supports multi-country)
country_filter = get_user_country_filter(request.user)

# Filter to specific country (for multi-country admins)
country_filter = get_user_country_filter(request.user, selected_country_id=5)

# Apply to any queryset
from apps.learnerships.models import LearnershipEnrollment
enrollments = filter_queryset_by_user_country(
    request.user,
    Enrollment.objects.all(),
    country_field='user__country_id'
)

# Check if user can access specific country
if can_user_access_country(request.user, country_id=5):
    # User has access
    pass

# Get all allowed countries
countries = get_allowed_countries(request.user)

# Get countries for specific role
hr_countries = get_allowed_countries(request.user, role_type='hr_admin')
```

### Using Permission Classes in Views

```python
from rest_framework.views import APIView
from apps.users.permissions import (
    IsHrAdmin, 
    IsPaymentAdmin, 
    IsExecutiveAdmin,
    IsSystemAdmin,
    CanSelectCountry,
    IsMultiCountryAdmin
)

class MyHrView(APIView):
    permission_classes = [IsAuthenticated, IsHrAdmin]
    
    def get(self, request):
        # Only HR Admins can access this
        ...

class MultiCountryView(APIView):
    permission_classes = [IsAuthenticated, IsMultiCountryAdmin]
    
    def get(self, request):
        # Only admins with multiple countries can access
        ...

class CountrySpecificView(APIView):
    permission_classes = [IsAuthenticated, CanSelectCountry]
    
    def get(self, request):
        # Validates country selection from query params
        country_id = request.query_params.get('country')
        ...
```

## Testing

Run the tests:
```bash
cd backend
source venv_linux/bin/activate
python manage.py test apps.users.tests_dashboard_multicountry
```

## Admin Interface

### Assigning Countries to Admin Roles

1. Go to Django Admin: `/admin/`
2. Navigate to **Payments → Admin Country Accesses**
3. Click **Add Admin Country Access**
4. Select:
   - **Admin Role**: The admin role to assign countries to
   - **Country**: The country to grant access to
   - **Is Active**: Whether the access is currently active
   - **Notes**: Optional notes

### Managing Admin Roles

1. Go to Django Admin: `/admin/`
2. Navigate to **Payments → Admin Roles**
3. Click **Add Admin Role**
4. Select:
   - **User**: The user to assign the role to
   - **Role Type**: HR Admin, Payment Admin, or Executive Admin
   - **Is Active**: Whether the role is currently active

## Security Considerations

1. **System Admin (Superuser)**: Cannot be restricted by country. Always has full access.

2. **Country Assignment**: Admins without specific country assignments have access to ALL countries by default.

3. **Filter Bypass Prevention**: All data retrieval methods apply the country filter automatically.

4. **Permission Checks**: All dashboard endpoints require authentication and appropriate role permissions.

5. **Country Selection Validation**: When a multi-country admin selects a country, access is validated before returning data.

## Frontend Integration

### Flutter/Dart Example

```dart
// Fetch dashboard data
Future<DashboardData> fetchDashboard({int? countryId}) async {
  final uri = countryId != null
      ? Uri.parse('/api/v1/users/dashboard/?country=$countryId')
      : Uri.parse('/api/v1/users/dashboard/');
  
  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    
    // Check if user is multi-country admin
    if (data['country_context']['is_multi_country']) {
      // Show country selector dropdown
      final countries = data['country_context']['allowed_countries'];
      showCountrySelector(countries, onSelect: (countryId) {
        fetchDashboard(countryId: countryId);
      });
    }
    
    // Check if viewing specific country
    if (data['country_context']['country_id'] != null) {
      showCountryBanner('Viewing data for: ${data['country_context']['country_name']}');
    }
    
    return DashboardData.fromJson(data);
  }
  
  throw Exception('Failed to load dashboard');
}

// Check country access
Future<bool> canAccessCountry(int countryId) async {
  final response = await http.get(
    Uri.parse('/api/v1/users/dashboard/country-selection/$countryId/'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  return response.statusCode == 200;
}
```

## Access Control Summary

| Role | Country Assignment | Default Access | Can Select Country |
|------|-------------------|----------------|-------------------|
| System Admin (Superuser) | N/A | All countries | Yes (any) |
| HR Admin (with countries) | Specific countries | Assigned countries only | Yes (assigned only) |
| HR Admin (no countries) | None | All countries | Yes (any) |
| Payment Admin (with countries) | Specific countries | Assigned countries only | Yes (assigned only) |
| Payment Admin (no countries) | None | All countries | Yes (any) |
| Executive Admin (with countries) | Specific countries | Assigned countries only | Yes (assigned only) |
| Executive Admin (no countries) | None | All countries | Yes (any) |
| Student/Instructor | Personal country | Personal country only | No |

## Troubleshooting

### Admin sees no data
- Verify the admin role is active (`is_active=True`)
- Check `AdminCountryAccess` entries exist and are active
- Ensure there is data in the database for assigned countries

### Admin cannot select country
- Verify country is in the admin's allowed countries list
- Check `AdminCountryAccess` entry is active
- Ensure country is active (`is_active=True`)

### System Admin restricted unexpectedly
- System Admin (superuser) cannot be restricted
- Verify `is_superuser=True` on the user account
- Check no middleware is overriding superuser permissions

### Permission denied errors
- Ensure the user is authenticated
- Check admin role assignments in `admin_roles` table
- Verify country access in `admin_country_access` table
- Check permission classes in view configuration

## Migration

After adding the new model, run migrations:

```bash
cd backend
source venv_linux/bin/activate
python manage.py makemigrations payments
python manage.py migrate payments
```
