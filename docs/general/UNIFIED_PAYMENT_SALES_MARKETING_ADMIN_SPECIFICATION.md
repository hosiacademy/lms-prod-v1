# 🎯 UNIFIED PAYMENT, SALES & MARKETING ADMIN SPECIFICATION
## Country-Based Access Control System

**Date:** March 18, 2026  
**Status:** ✅ SPECIFICATION COMPLETE - Ready for Implementation  
**Scope:** Unified admin role covering Payments, Sales Analytics, and Marketing Operations

---

## 📋 EXECUTIVE SUMMARY

### Current State Analysis

The current system has ** Payment Admin** role that already includes:
- ✅ Payment transaction management
- ✅ Sales analytics (revenue by country, payment methods)
- ✅ Marketing analytics (wishlist, cart conversion)

**However**, the role naming and permissions structure needs enhancement to:
1. **Explicitly recognize** the 3-in-1 nature (Payment + Sales + Marketing)
2. **Strengthen country-based access control** for all data types
3. **Unify dashboard** to show all three aspects with country filtering

---

## 🎯 PROPOSED ARCHITECTURE

### Unified Admin Role Structure

```
┌─────────────────────────────────────────────────────────────┐
│         UNIFIED PAYMENT, SALES & MARKETING ADMIN            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Role Name: `payment_sales_marketing_admin`                │
│  (Backward compatible with existing `payment_admin`)       │
│                                                             │
│  Three Pillars:                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   PAYMENT    │  │    SALES     │  │  MARKETING   │     │
│  │  OPERATIONS  │  │   ANALYTICS  │  │  OPERATIONS  │     │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤     │
│  │• Transactions│  │• Revenue     │  │• Wishlist    │     │
│  │• Refunds     │  │• Trends      │  │• Cart        │     │
│  │• Reconciliation││• Forecasting │  │• Conversion  │     │
│  │• Webhooks    │  │• Country     │  │• Leads       │     │
│  │• Disputes    │  │  Performance │  │• Campaigns   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  Country Access:                                           │
│  • Assigned via AdminCountryAccess                         │
│  • Filters ALL data (payments, sales, marketing)           │
│  • Multi-country support                                   │
│  • Per-country drill-down                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🗄️ DATABASE MODEL ENHANCEMENTS

### Current AdminRole Model (Already Perfect)

```python
class AdminRole(models.Model):
    role_type = models.CharField(max_length=50, choices=[
        ('payment_admin', 'Payment Admin'),  # Keep for backward compatibility
        ('payment_sales_marketing_admin', 'Payment, Sales & Marketing Admin'),  # NEW
        ('hr_admin', 'HR Admin'),
        ('executive_admin', 'Executive Admin'),
    ])
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)
    permissions = models.JSONField(default=dict)  # For granular permissions
    
    # Country access via AdminCountryAccess relation
    # - If no countries assigned: access to ALL countries
    # - If countries assigned: access restricted to those countries
```

### Country-Based Filtering (Already Implemented)

```python
class AdminCountryAccess(models.Model):
    admin_role = models.ForeignKey('payments.AdminRole', on_delete=models.CASCADE)
    country = models.ForeignKey('localization.Country', on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)
    
    # If admin has these countries assigned:
    # Kenya (KE), Zimbabwe (ZW)
    # → Can ONLY see data from KE and ZW
    # → All queries automatically filtered by country
```

---

## 🔐 COUNTRY-BASED ACCESS CONTROL

### Access Control Logic

```python
# Pseudo-code for country filtering

def get_allowed_countries(admin_user):
    """Get countries this admin can access"""
    role = AdminRole.get_admin_role(admin_user, 'payment_sales_marketing_admin')
    
    if not role:
        return Country.objects.none()  # No access
    
    # Get assigned countries
    countries = role.country_accesses.filter(
        is_active=True
    ).values_list('country_id', flat=True)
    
    # If no countries assigned, return ALL countries
    if not countries.exists():
        return Country.objects.filter(is_active=True)
    
    return Country.objects.filter(id__in=countries)


def filter_queryset_by_country(queryset, admin_user, country_field='country'):
    """Filter any queryset by admin's allowed countries"""
    allowed_countries = get_allowed_countries(admin_user)
    
    if not allowed_countries.exists():
        return queryset.none()  # No access
    
    # Check if no restrictions (all countries)
    if allowed_countries.count() == Country.objects.filter(is_active=True).count():
        return queryset  # No filtering needed
    
    # Filter by allowed countries
    filter_kwargs = {f'{country_field}__in': allowed_countries}
    return queryset.filter(**filter_kwargs)
```

### Application to Different Data Types

```python
# Payment Transactions
PaymentTransaction.objects.filter(
    country__in=admin_allowed_countries
)

# Wishlist Items
Wishlist.objects.filter(
    user__country__in=admin_allowed_countries
)

# Course Carts
CourseCart.objects.filter(
    user__country__in=admin_allowed_countries
)

# Enrollments
Enrollment.objects.filter(
    learner_country__in=admin_allowed_countries
)

# Revenue Reports
PaymentTransaction.objects.filter(
    country__in=admin_allowed_countries
).annotate(
    total_revenue=Sum('amount')
)
```

---

## 📊 UNIFIED DASHBOARD SPECIFICATION

### Dashboard Tabs Structure

```
┌─────────────────────────────────────────────────────────────┐
│  UNIFIED PAYMENT, SALES & MARKETING ADMIN DASHBOARD        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Country Filter: [All Countries ▼] [Kenya] [Zimbabwe]      │
│  Date Range: [Last 30 days ▼]                              │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ TAB 1: OVERVIEW                                      │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ KPI Cards (Filtered by Country):                     │ │
│  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │ │
│  │ │Total     │ │Revenue   │ │Wishlist  │ │Cart      │ │ │
│  │ │Revenue   │ │This Month│ │Items     │ │Abandonment│ │ │
│  │ │$150,000  │ │$52,000   │ │450       │ │12.5%     │ │ │
│  │ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │ │
│  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ │ │
│  │ │Payment   │ │Conversion│ │Pending   │ │Refunds   │ │ │
│  │ │Success   │ │Rate      │ │Payments  │ │This Month│ │ │
│  │ │Rate      │ │12.5%     │ │23        │ │$2,500    │ │ │
│  │ │94.5%     │ │          │ │          │ │          │ │ │
│  │ └──────────┘ └──────────┘ └──────────┘ └──────────┘ │ │
│  │                                                      │ │
│  │ Charts:                                              │ │
│  │ • Revenue Trend (line chart by country)              │ │
│  │ • Payment Method Breakdown (pie chart)               │ │
│  │ • Wishlist → Enrollment Funnel (funnel chart)        │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ TAB 2: PAYMENTS                                      │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ • Pending Payments (Cash + EFT + Card)              │ │
│  │ • Payment Verification                               │ │
│  │ • Refund Management                                  │ │
│  │ • Payment Disputes                                   │ │
│  │ • Reconciliation Status                              │ │
│  │ • Webhook Logs                                       │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ TAB 3: SALES ANALYTICS                               │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ • Revenue by Country                                 │ │
│  │ • Revenue by Course Type                             │ │
│  │ • Revenue by Payment Method                          │ │
│  │ • Sales Trends (daily/weekly/monthly)               │ │
│  │ • Top Performing Courses                             │ │
│  │ • Country Performance Comparison                     │ │
│  │ • Revenue Forecasting                                │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ TAB 4: MARKETING OPERATIONS                          │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ • Wishlist Items (high priority leads)              │ │
│  │ • Cart Abandonment Tracking                          │ │
│  │ • Conversion Funnel Analysis                         │ │
│  │ • Lead Nurturing Campaigns                           │ │
│  │ • Marketing ROI by Country                           │ │
│  │ • Customer Acquisition Cost                          │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ TAB 5: COUNTRY PERFORMANCE                           │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ Country Cards (one per allowed country):             │ │
│  │ ┌──────────────────────────────────────────────────┐ │ │
│  │ │ 🇰🇪 KENYA                                        │ │ │
│  │ │ Revenue: $75,000 (50%)                          │ │ │
│  │ │ Students: 625 | Courses: 42                     │ │ │
│  │ │ Growth: +15.5% (vs last month)                 │ │ │
│  │ │ Payment Methods: M-Pesa 60%, Card 25%, EFT 15% │ │ │
│  │ │ Wishlist Items: 180 | Conversion: 14.2%        │ │ │
│  │ └──────────────────────────────────────────────────┘ │ │
│  │ ┌──────────────────────────────────────────────────┐ │ │
│  │ │ 🇿🇼 ZIMBABWE                                     │ │ │
│  │ │ Revenue: $45,000 (30%)                          │ │ │
│  │ │ Students: 375 | Courses: 28                     │ │ │
│  │ │ Growth: +12.3% (vs last month)                 │ │ │
│  │ │ Payment Methods: PayNow 50%, EFT 30%, Card 20% │ │ │
│  │ │ Wishlist Items: 120 | Conversion: 11.8%        │ │ │
│  │ └──────────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ TAB 6: REPORTS & EXPORTS                             │ │
│  ├──────────────────────────────────────────────────────┤ │
│  │ • Generate Monthly Revenue Report (PDF/Excel)       │ │
│  │ • Export Payment Transactions (CSV)                 │ │
│  │ • Export Wishlist Leads (CSV)                       │ │
│  │ • Country Performance Report (PDF)                  │ │
│  │ • Scheduled Reports (email automation)              │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 BACKEND API ENHANCEMENTS

### Existing Endpoints (To Be Enhanced with Country Filtering)

```python
# Current endpoint - needs country filtering enhancement
@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def get_admin_payments(request):
    """Get payments for admin review - NOW WITH COUNTRY FILTERING"""
    
    # Get admin's allowed countries
    allowed_countries = get_allowed_countries(request.user)
    
    # Filter PaymentReference by country
    queryset = PaymentReference.objects.filter(
        country__in=allowed_countries
    )
    
    # ... rest of existing logic
```

### New Unified Dashboard Endpoint

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin  # Works for unified role too
def get_unified_payment_sales_marketing_dashboard(request):
    """
    Unified dashboard data with country-based filtering.
    
    Query Parameters:
    - country: Optional country ID to filter by (must be in allowed countries)
    - period: Time period (day, week, month, quarter, year)
    """
    user = request.user
    
    # Get allowed countries
    allowed_countries = get_allowed_countries(user)
    
    # Optional: Filter by specific country
    country_param = request.query_params.get('country')
    if country_param:
        if not allowed_countries.filter(id=country_param).exists():
            return Response(
                {'error': 'You do not have access to this country'},
                status=403
            )
        filtered_countries = Country.objects.filter(id=country_param)
    else:
        filtered_countries = allowed_countries
    
    # Get period
    period = request.query_params.get('period', 'month')
    start_date, end_date = calculate_date_range(period)
    
    # ===== PAYMENT DATA (Country-Filtered) =====
    payment_transactions = PaymentTransaction.objects.filter(
        country__in=filtered_countries,
        created_at__range=[start_date, end_date]
    )
    
    total_revenue = payment_transactions.filter(
        status=PaymentStatus.SUCCESSFUL
    ).aggregate(total=Sum('amount'))['total'] or 0
    
    pending_payments = payment_transactions.filter(
        status=PaymentStatus.PENDING
    ).count()
    
    # ===== SALES DATA (Country-Filtered) =====
    enrollments = Enrollment.objects.filter(
        learner_country__in=filtered_countries,
        created_at__range=[start_date, end_date]
    )
    
    revenue_by_course_type = enrollments.values(
        'enrollment_type'
    ).annotate(
        revenue=Sum('total_amount'),
        count=Count('id')
    ).order_by('-revenue')
    
    # ===== MARKETING DATA (Country-Filtered) =====
    wishlist_items = Wishlist.objects.filter(
        user__country__in=filtered_countries,
        created_at__range=[start_date, end_date]
    )
    
    wishlist_conversion_rate = (
        wishlist_items.filter(converted_to_enrollment=True).count() /
        wishlist_items.count() * 100
    ) if wishlist_items.exists() else 0
    
    carts = CourseCart.objects.filter(
        user__country__in=filtered_countries,
        updated_at__range=[start_date, end_date]
    )
    
    cart_abandonment_rate = (
        carts.filter(status='abandoned').count() /
        carts.filter(status__in=['active', 'checkout']).count() * 100
    ) if carts.exists() else 0
    
    # ===== COUNTRY BREAKDOWN =====
    country_breakdown = []
    for country in filtered_countries:
        country_revenue = PaymentTransaction.objects.filter(
            country=country,
            status=PaymentStatus.SUCCESSFUL,
            created_at__range=[start_date, end_date]
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        country_wishlist = Wishlist.objects.filter(
            user__country=country,
            created_at__range=[start_date, end_date]
        ).count()
        
        country_breakdown.append({
            'country_id': country.id,
            'country_name': country.name,
            'country_code': country.code,
            'revenue': float(country_revenue),
            'wishlist_items': country_wishlist,
            'percentage': float(country_revenue / total_revenue * 100) if total_revenue > 0 else 0
        })
    
    # ===== RESPONSE =====
    return Response({
        'period': period,
        'countries': {
            'allowed': list(allowed_countries.values('id', 'name', 'code')),
            'filtered': list(filtered_countries.values('id', 'name', 'code')),
        },
        'payment_metrics': {
            'total_revenue': float(total_revenue),
            'pending_payments': pending_payments,
            'payment_success_rate': 0.0,  # Calculate from transactions
        },
        'sales_metrics': {
            'revenue_by_course_type': list(revenue_by_course_type),
            'total_enrollments': enrollments.count(),
        },
        'marketing_metrics': {
            'wishlist_conversion_rate': wishlist_conversion_rate,
            'cart_abandonment_rate': cart_abandonment_rate,
            'total_wishlist': wishlist_items.count(),
            'total_carts': carts.count(),
        },
        'country_breakdown': country_breakdown,
    })
```

---

## 📱 FRONTEND IMPLEMENTATION

### Country Filter Component

```dart
// Country filter widget for dashboard
class CountryFilterWidget extends StatefulWidget {
  final List<Map<String, dynamic>> allowedCountries;
  final Function(String?) onCountrySelected;
  
  @override
  _CountryFilterWidgetState createState() => _CountryFilterWidgetState();
}

class _CountryFilterWidgetState extends State<CountryFilterWidget> {
  String? _selectedCountry;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Country:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCountry,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text('All Countries (${widget.allowedCountries.length})'),
                ),
                ...widget.allowedCountries.map((country) => DropdownMenuItem(
                  value: country['code'],
                  child: Row(
                    children: [
                      Text(country['flag_emoji'] ?? '🌍'),
                      SizedBox(width: 8),
                      Text(country['name']),
                    ],
                  ),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedCountry = value);
                widget.onCountrySelected(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### Dashboard Data Loading with Country Filter

```dart
// In PaymentAdminPage (now unified dashboard)
class _PaymentAdminPageState extends State<PaymentAdminPage> {
  List<Map<String, dynamic>> _allowedCountries = [];
  String? _selectedCountry;
  Map<String, dynamic>? _dashboardData;
  
  @override
  void initState() {
    super.initState();
    _loadAllowedCountries();
  }
  
  Future<void> _loadAllowedCountries() async {
    try {
      // Get user's role and allowed countries
      final roleData = await ApiClient.get('/api/v1/admin/role-assignment/');
      
      if (roleData.data != null && roleData.data['countries'] != null) {
        setState(() {
          _allowedCountries = List<Map<String, dynamic>>.from(
            roleData.data['countries']
          );
          
          // Default to first country if only one allowed
          if (_allowedCountries.length == 1) {
            _selectedCountry = _allowedCountries.first['code'];
          }
        });
        
        // Load dashboard data with country filter
        _loadDashboardData();
      }
    } catch (e) {
      debugPrint('Error loading countries: $e');
    }
  }
  
  Future<void> _loadDashboardData() async {
    try {
      final queryParams = <String, dynamic>{
        'period': 'month',
      };
      
      if (_selectedCountry != null) {
        queryParams['country'] = _selectedCountry;
      }
      
      final response = await ApiClient.get(
        '/api/v1/payments/admin/unified-dashboard/',
        queryParams: queryParams,
      );
      
      setState(() {
        _dashboardData = response.data;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Country Filter
        CountryFilterWidget(
          allowedCountries: _allowedCountries,
          onCountrySelected: (country) {
            setState(() => _selectedCountry = country);
            _loadDashboardData(); // Reload data with new country filter
          },
        ),
        
        // Dashboard Content
        Expanded(
          child: _dashboardData == null
              ? Center(child: CircularProgressIndicator())
              : _buildDashboardContent(),
        ),
      ],
    );
  }
}
```

---

## 🎯 IMPLEMENTATION CHECKLIST

### Backend (Priority 1)

- [ ] Add new role type `payment_sales_marketing_admin` to AdminRole model
- [ ] Create migration for new role type
- [ ] Enhance existing payment endpoints with country filtering
- [ ] Create unified dashboard endpoint
- [ ] Add country filtering to wishlist/cart queries
- [ ] Add country filtering to sales analytics
- [ ] Update permission decorators to support unified role
- [ ] Add country breakdown to all analytics endpoints
- [ ] Create data export endpoints with country filtering
- [ ] Add email report scheduling with country filters

### Frontend (Priority 2)

- [ ] Rename PaymentAdminPage to UnifiedPaymentSalesMarketingAdminPage
- [ ] Add country filter widget to dashboard header
- [ ] Update all dashboard tabs to respect country filter
- [ ] Add country performance tab
- [ ] Enhance KPI cards with country context
- [ ] Update charts to show country breakdown
- [ ] Add country-specific export functionality
- [ ] Update navigation/ routing to reflect new role name
- [ ] Add loading states for country filtering
- [ ] Add error handling for country access violations

### Data Migration (Priority 3)

- [ ] Migrate existing `payment_admin` roles to `payment_sales_marketing_admin`
- [ ] Preserve existing country assignments
- [ ] Update admin UI to show new role name
- [ ] Update documentation
- [ ] Update email templates to reference new role name

---

## 🔒 SECURITY CONSIDERATIONS

### Country Access Validation

```python
# ALWAYS validate country access on backend
def validate_country_access(user, requested_country_id):
    """Validate user has access to requested country"""
    allowed_countries = get_allowed_countries(user)
    
    if not allowed_countries.filter(id=requested_country_id).exists():
        raise PermissionDenied(
            f"User does not have access to country {requested_country_id}"
        )
```

### API Rate Limiting by Country

```python
# Prevent country data scraping via repeated queries
@throttle_classes([UserRateThrottle])
@throttle_scope='country_data'
def get_country_data(request, country_id):
    # ...
```

---

## 📊 SUMMARY

### What Changes:

1. **Role Naming:** `payment_admin` → `payment_sales_marketing_admin` (backward compatible)
2. **Dashboard Scope:** Explicitly includes Payment + Sales + Marketing
3. **Country Filtering:** Strengthened and applied to ALL data types
4. **Unified Endpoint:** Single dashboard endpoint with country parameter

### What Stays the Same:

1. **AdminRole Model Structure:** No breaking changes
2. **AdminCountryAccess:** Works exactly as before
3. **Existing Permissions:** Backward compatible
4. **Database Schema:** No changes required

### Benefits:

1. **Clearer Role Definition:** Admins understand full scope
2. **Better Country Isolation:** Data strictly filtered by country
3. **Unified Analytics:** All metrics in one place
4. **Scalable:** Easy to add more countries/admins

---

**Ready for implementation!** Would you like me to proceed with building this unified system?
