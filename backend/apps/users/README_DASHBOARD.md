# Role-Based Dashboard with Country/Region Filtering

## Overview

This implementation provides role-based access control for the HR Admin Dashboard with country/region filtering. HR Admins can only view data for their assigned country, while Executive Admins and Superusers have unrestricted access to all countries.

## Architecture

### Files Created/Modified

1. **`apps/users/permissions.py`** - Permission classes for role-based access
2. **`apps/users/filters.py`** - Country filtering utilities
3. **`apps/users/dashboard_serializers.py`** - Updated with country filtering support
4. **`apps/users/views_dashboard.py`** - Dashboard API endpoints
5. **`apps/users/urls.py`** - Updated with dashboard routes
6. **`apps/users/tests_dashboard.py`** - Test cases

## User Roles

### HR Admin (`role_type='hr_admin'`)
- Can only view data for their assigned country
- Must have a country assigned to the user account
- Access endpoints: `/api/v1/users/dashboard/`, `/api/v1/users/dashboard/hr-admin/`

### Executive Admin (`role_type='executive_admin'`)
- Can view data for all countries
- No country restrictions
- Access endpoints: `/api/v1/users/dashboard/`, `/api/v1/users/dashboard/executive/`

### Payment Admin (`role_type='payment_admin'`)
- Can view data for all countries (payment data is global)
- No country restrictions by default

### Superuser
- Unrestricted access to all data and countries

## API Endpoints

### Main Dashboard Endpoint
```
GET /api/v1/users/dashboard/
```
Returns role-appropriate dashboard data with automatic country filtering.

**Response Example (HR Admin):**
```json
{
  "role": "admin",
  "system_stats": {
    "total_users": 150,
    "total_students": 120,
    "total_instructors": 25,
    "total_admins": 5,
    "total_courses": 50,
    "total_enrollments": 200
  },
  "user_metrics": {
    "new_users_week": 10,
    "new_users_month": 45,
    "active_users_week": 80
  },
  "pathway_metrics": {
    "masterclass": 30,
    "industry": 20,
    "learnership": 100,
    "custom_selection": 50
  },
  "geographic_metrics": {
    "by_country": [
      {
        "country_code": "ZA",
        "country_name": "South Africa",
        "count": 1,
        "is_restricted": true
      }
    ],
    "is_restricted": true,
    "restricted_country": "South Africa"
  },
  "revenue_metrics": {
    "revenue_mtd": 50000.00,
    "revenue_ytd": 0
  },
  "engagement": {
    "active_learners_week": 75,
    "average_platform_progress": 0,
    "engagement_rate": 0
  },
  "country_context": {
    "restricted": true,
    "country_id": 1,
    "country_name": "South Africa",
    "country_code": "ZA"
  },
  "user_role": {
    "role_id": 1,
    "role_name": "Admin",
    "is_hr_admin": true,
    "is_payment_admin": false,
    "is_executive_admin": false,
    "is_superuser": false
  }
}
```

### HR Admin Specific Endpoint
```
GET /api/v1/users/dashboard/hr-admin/
```
Requires HR Admin role. Returns dashboard data filtered by assigned country.

**Response Example:**
```json
{
  "role": "admin",
  "...": "dashboard data filtered by country",
  "user_role": {
    "role_id": 1,
    "role_name": "HR Admin",
    "is_hr_admin": true,
    "assigned_country": {
      "id": 1,
      "name": "South Africa",
      "code": "ZA"
    }
  }
}
```

### Executive Dashboard Endpoint
```
GET /api/v1/users/dashboard/executive/
```
Requires Executive Admin role or Superuser. Returns system-wide data with no country restrictions.

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
    "country_id": 1,
    "country_name": "South Africa",
    "can_view_all": false
  },
  "allowed_countries": [
    {
      "id": 1,
      "name": "South Africa",
      "code": "ZA"
    }
  ],
  "user_country": {
    "id": 1,
    "name": "South Africa",
    "code": "ZA"
  }
}
```

## Usage

### Setting Up HR Admin

1. Create a user with `role_id=1`:
```python
from django.contrib.auth import get_user_model
from apps.localization.models import Country
from apps.payments.models import AdminRole

User = get_user_model()

# Create user with country assignment
country = Country.objects.get(code='ZA')
hr_admin = User.objects.create_user(
    username='hr_south_africa',
    email='hr.za@hosi.academy',
    password='SecurePassword123!',
    role_id=1,
    country=country,
    name='HR Admin - South Africa'
)

# Assign HR Admin role
AdminRole.objects.create(
    user=hr_admin,
    role_type='hr_admin',
    is_active=True
)
```

### Using the Filters in Custom Queries

```python
from apps.users.filters import get_user_country_filter, filter_queryset_by_user_country

# Get country filter Q object
country_filter = get_user_country_filter(request.user)

# Apply to any queryset
from apps.learnerships.models import LearnershipEnrollment
enrollments = LearnershipEnrollment.objects.all()
filtered_enrollments = filter_queryset_by_user_country(
    request.user,
    enrollments,
    country_field='user__country_id'
)
```

### Using Permission Classes in Views

```python
from rest_framework.views import APIView
from apps.users.permissions import IsHrAdmin, IsExecutiveAdmin

class MyHrView(APIView):
    permission_classes = [IsAuthenticated, IsHrAdmin]
    
    def get(self, request):
        # Only HR Admins can access this
        ...
```

## Testing

Run the tests:
```bash
cd backend
source venv_linux/bin/activate
python manage.py test apps.users.tests_dashboard
```

## Security Considerations

1. **Country Assignment**: HR Admins must have a country assigned. Without a country, they cannot access the dashboard.

2. **Filter Bypass Prevention**: All data retrieval methods in `AdminDashboardSerializer` accept and apply the country filter.

3. **Permission Checks**: All dashboard endpoints require authentication and appropriate role permissions.

4. **Frontend Display**: The `country_context` in the response helps the frontend display appropriate UI indicators (e.g., "Viewing data for: South Africa").

## Frontend Integration

### Flutter/Dart Example

```dart
// Fetch dashboard data
Future<DashboardData> fetchDashboard() async {
  final response = await http.get(
    Uri.parse('/api/v1/users/dashboard/'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    
    // Check if view is country-restricted
    if (data['country_context']['restricted']) {
      // Display country indicator
      final countryName = data['country_context']['country_name'];
      showCountryBanner('Viewing data for: $countryName');
    }
    
    return DashboardData.fromJson(data);
  }
  
  throw Exception('Failed to load dashboard');
}
```

## Extending for Multi-Country HR Admins

Currently, HR Admins are restricted to a single country. To support multi-country access:

1. Create a through model for HR Admin ↔ Country relationships
2. Modify `get_allowed_countries()` to return multiple countries
3. Add a country selector in the frontend
4. Update the `DashboardView` to accept and validate country parameter

## Troubleshooting

### HR Admin sees no data
- Verify the user has a country assigned
- Check that `AdminRole` entry exists with `is_active=True`
- Ensure there is data in the database for that country

### Executive Admin sees restricted data
- Verify `AdminRole` entry has `role_type='executive_admin'`
- Check that the role is active (`is_active=True`)

### Permission denied errors
- Ensure the user is authenticated
- Check role assignments in `admin_roles` table
- Verify permission classes in view configuration
