# HOSI ACADEMY INFLUENCER/AMBASSADOR PARTNER PROGRAM
## Strategic Implementation Plan

**Document Version:** 1.0  
**Date:** April 16, 2026  
**Status:** Planning Phase - No Code Changes

---

## EXECUTIVE SUMMARY

This document outlines a complete plan for building an Influencer/Ambassador Partner Program to enable marketing partners to promote Hosi Academy courses in their respective regions. The program will provide partners with their own access portal, unique referral tracking, commission management, and marketing resources.

---

## 1. DATABASE MODELS ARCHITECTURE

### 1.1 Partner Profile Model
```python
Fields:
- partner_id (UUID, Primary Key)
- user (ForeignKey to users.User - one-to-one)
- partner_type (Choices: INDIVIDUAL, AGENCY, CORPORATE, INSTITUTION)
- status (Choices: PENDING, ACTIVE, SUSPENDED, TERMINATED)
- application_date (DateTime)
- approval_date (DateTime, nullable)
- approved_by (ForeignKey to users.User, nullable)
- 
# Personal/Business Information
- business_name (CharField)
- registration_number (CharField, optional)
- tax_id (CharField, optional)
- website (URLField, optional)
- 
# Marketing Focus
- primary_market (CharField - country/region)
- secondary_markets (JSONField - list of regions)
- target_audience (TextField - description)
- estimated_reach (PositiveIntegerField - follower count/subscribers)

# Social Media Presence
- instagram_handle (CharField)
- tiktok_handle (CharField)
- twitter_handle (CharField)
- linkedin_profile (URLField)
- youtube_channel (URLField)
- facebook_page (URLField)
- other_platforms (JSONField)

# Contact & Banking
- phone_secondary (CharField)
- payout_method (Choices: BANK_TRANSFER, PAYPAL, PAYONEER, WISE)
- payout_currency (CharField - default to ZAR)
- bank_account_details (EncryptedJSONField)

# Agreement
- terms_accepted (Boolean)
- terms_accepted_date (DateTime)
- commission_rate (DecimalField - default 10-30%)
- custom_agreement (TextField - special terms)
```

### 1.2 Partner Territory Model
```python
Fields:
- territory_id (UUID, Primary Key)
- partner (ForeignKey to PartnerProfile)
- country (ForeignKey to localization.Country)
- region/state (CharField)
- city (CharField, optional)
- exclusivity_level (Choices: EXCLUSIVE, NON_EXCLUSIVE, SHARED)
- start_date (Date)
- end_date (Date, optional)
- performance_quota (DecimalField - monthly sales target)
- active (Boolean)
```

### 1.3 Referral Link Model
```python
Fields:
- referral_id (UUID, Primary Key)
- partner (ForeignKey to PartnerProfile)
- referral_code (CharField, unique - e.g., "HOSI-SARAH-2026")
- generated_url (URLField - full tracking URL)
- 
- created_at (DateTime)
- expires_at (DateTime, optional)
- usage_limit (PositiveIntegerField, optional)
- current_uses (PositiveIntegerField - default 0)
- 
# Targeting
- target_course (ForeignKey to courses.Course, optional)
- target_pathway (CharField - masterclass/learnership/industry/aicerts)
- target_country (CharField, optional)
- discount_code (ForeignKey to payments.CouponCode, optional)
- 
- is_active (Boolean)
- notes (TextField)
```

### 1.4 Referral Tracking Model
```python
Fields:
- tracking_id (UUID, Primary Key)
- referral_link (ForeignKey to ReferralLink)
- partner (ForeignKey to PartnerProfile)
- 
- visitor_ip (GenericIPAddressField)
- visitor_user_agent (TextField)
- referrer_url (URLField)
- landing_page (URLField)
- timestamp (DateTime - click time)
- 
- converted_to_lead (Boolean)
- converted_to_enrollment (Boolean)
- enrollment (ForeignKey to enrollments.Enrollment, nullable)
- conversion_timestamp (DateTime, nullable)
- 
# Attribution
- attribution_window_days (PositiveInteger - default 30)
- cookie_id (CharField)
- session_id (CharField)
```

### 1.5 Commission Model
```python
Fields:
- commission_id (UUID, Primary Key)
- partner (ForeignKey to PartnerProfile)
- referral_tracking (ForeignKey to ReferralTracking)
- enrollment (ForeignKey to enrollments.Enrollment)
- 
- course (ForeignKey to courses.Course)
- original_amount (DecimalField - full course price)
- discount_applied (DecimalField)
- net_amount (DecimalField - after discounts)
- commission_rate (DecimalField - percentage)
- commission_amount (DecimalField - calculated)
- currency (CharField)
- 
- status (Choices: PENDING, APPROVED, PAID, REFUNDED, CANCELLED)
- created_at (DateTime)
- approved_at (DateTime, nullable)
- approved_by (ForeignKey to users.User, nullable)
- paid_at (DateTime, nullable)
- payment_reference (CharField, nullable)
- 
- refund_adjustment (DecimalField - if course refunded)
- notes (TextField)
```

### 1.6 Partner Performance Model (Aggregated Stats)
```python
Fields:
- stat_id (UUID, Primary Key)
- partner (ForeignKey to PartnerProfile)
- period_start (Date)
- period_end (Date)
- 
- total_clicks (PositiveInteger)
- unique_clicks (PositiveInteger)
- leads_generated (PositiveInteger)
- enrollments_generated (PositiveInteger)
- conversion_rate (DecimalField)
- 
- total_revenue (DecimalField)
- total_commission (DecimalField)
- pending_commission (DecimalField)
- paid_commission (DecimalField)
- 
- new_signups (PositiveInteger)
- active_referrals (PositiveInteger)
- expired_referrals (PositiveInteger)
- 
- performance_score (DecimalField - 0-100)
- tier_level (Choices: BRONZE, SILVER, GOLD, PLATINUM)
```

### 1.7 Partner Document Model
```python
Fields:
- document_id (UUID, Primary Key)
- partner (ForeignKey to PartnerProfile)
- document_type (Choices: AGREEMENT, ID_PROOF, TAX_DOC, PORTFOLIO, CERTIFICATE, OTHER)
- title (CharField)
- file (FileField)
- uploaded_at (DateTime)
- verified (Boolean)
- verified_by (ForeignKey to users.User, nullable)
- verified_at (DateTime, nullable)
- notes (TextField)
```

### 1.8 Partner Communication Model
```python
Fields:
- communication_id (UUID, Primary Key)
- partner (ForeignKey to PartnerProfile)
- communication_type (Choices: EMAIL, SMS, IN_APP, CALL, MEETING)
- subject (CharField)
- content (TextField)
- sent_by (ForeignKey to users.User - internal admin)
- sent_at (DateTime)
- opened_at (DateTime, nullable)
- replied_at (DateTime, nullable)
- status (Choices: SENT, DELIVERED, OPENED, REPLIED, FAILED)
```

---

## 2. ADMIN DASHBOARD REQUIREMENTS

### 2.1 Partner Management Dashboard
**Purpose:** Central hub for managing all partners

**Required Views:**
1. **Partner List View**
   - Filterable table with: ID, Name, Type, Status, Country, Commission Rate, Performance Score
   - Quick actions: Approve, Suspend, View Details, Export
   - Bulk operations: Export CSV, Send Email, Update Status

2. **Partner Detail View**
   - Profile information (read-only and editable sections)
   - Social media verification status
   - Territory map visualization
   - Commission history
   - Performance metrics
   - Document verification panel
   - Communication history
   - Activity log

3. **Application Review Queue**
   - New applications pending approval
   - Application details with social media verification
   - One-click approve/reject with notes
   - Bulk approval for trusted applicants

### 2.2 Commission Management Dashboard
**Purpose:** Track, approve, and process partner commissions

**Required Views:**
1. **Commission Overview**
   - Total pending commissions
   - Total paid commissions (monthly/yearly)
   - Average commission per partner
   - Commission by course/pathway
   - Payment processing status

2. **Pending Commissions**
   - Table of all pending commissions
   - Filter by: partner, date range, course, amount
   - Batch approve/reject functionality
   - Export for accounting

3. **Payment Processing**
   - Integration with payment providers
   - Batch payment initiation
   - Payment confirmation tracking
   - Failed payment handling

### 2.3 Performance Analytics Dashboard
**Purpose:** Monitor partner program effectiveness

**Required Metrics:**
1. **Top Performing Partners**
   - By revenue generated
   - By conversion rate
   - By new student acquisition
   - By region

2. **Referral Performance**
   - Click-through rates by partner
   - Conversion funnel visualization
   - Attribution accuracy
   - Referral link performance

3. **Geographic Performance**
   - Map view of partner territories
   - Revenue heat map by region
   - Market penetration analysis

4. **Course Performance via Partners**
   - Which courses perform best through partners
   - Partner-specific course recommendations
   - Commission optimization suggestions

### 2.4 Marketing Resources Management
**Purpose:** Distribute marketing materials to partners

**Required Features:**
1. **Resource Library**
   - Upload marketing assets (banners, videos, copy)
   - Categorize by: course, format, language, region
   - Usage tracking per partner
   - Version control for assets

2. **Campaign Management**
   - Create partner campaigns
   - Assign specific partners to campaigns
   - Track campaign performance
   - Automated commission adjustments for campaigns

---

## 3. API ENDPOINTS SPECIFICATION

### 3.1 Partner Registration & Authentication

**POST /api/v1/partners/register/**
```
Purpose: New partner application
Auth: Public (with email verification)
Payload:
{
  "business_name": "string",
  "email": "string",
  "phone": "string",
  "country": "string (ISO-2)",
  "partner_type": "INDIVIDUAL|AGENCY|CORPORATE",
  "social_media": {
    "instagram": "string",
    "tiktok": "string",
    "youtube": "string",
    "linkedin": "string"
  },
  "estimated_reach": integer,
  "marketing_experience": "string",
  "target_regions": ["list of countries"],
  "why_partner": "string"
}
Response: { "application_id": "uuid", "status": "PENDING", "message": "..." }
```

**POST /api/v1/partners/login/**
```
Purpose: Partner portal authentication
Auth: Returns JWT token
Payload: { "email": "string", "password": "string" }
Response: { "access_token": "string", "refresh_token": "string", "partner_id": "uuid" }
```

**POST /api/v1/partners/refresh-token/**
```
Purpose: Refresh JWT token
Auth: Refresh token required
```

### 3.2 Partner Profile Management

**GET /api/v1/partners/profile/**
```
Purpose: Get own profile
Auth: Partner JWT required
Response: Full partner profile with stats
```

**PUT /api/v1/partners/profile/**
```
Purpose: Update profile (limited fields)
Auth: Partner JWT required
Allowed updates: social_media, bank_details, contact_info
```

**POST /api/v1/partners/documents/upload/**
```
Purpose: Upload documents
Auth: Partner JWT required
Payload: Multipart form with file
Response: { "document_id": "uuid", "status": "UPLOADED" }
```

### 3.3 Referral Link Management

**POST /api/v1/partners/referral-links/create/**
```
Purpose: Generate new referral link
Auth: Partner JWT required
Payload:
{
  "target_course_id": "uuid (optional)",
  "target_pathway": "masterclass|learnership|industry|aicerts",
  "target_country": "string (ISO-2, optional)",
  "custom_code": "string (optional - vanity URL)",
  "expires_at": "datetime (optional)",
  "usage_limit": integer (optional)
}
Response: { "referral_id": "uuid", "referral_code": "string", "full_url": "string" }
```

**GET /api/v1/partners/referral-links/**
```
Purpose: List all partner's referral links
Auth: Partner JWT required
Query params: active_only, page, per_page
Response: Paginated list with usage stats
```

**DELETE /api/v1/partners/referral-links/{id}/**
```
Purpose: Deactivate referral link
Auth: Partner JWT required (must own the link)
```

### 3.4 Performance & Analytics

**GET /api/v1/partners/dashboard/stats/**
```
Purpose: Get dashboard statistics
Auth: Partner JWT required
Response:
{
  "total_clicks": integer,
  "total_conversions": integer,
  "conversion_rate": float,
  "total_earnings": decimal,
  "pending_commissions": decimal,
  "paid_commissions": decimal,
  "this_month": {
    "clicks": integer,
    "conversions": integer,
    "earnings": decimal
  },
  "tier_level": "BRONZE|SILVER|GOLD|PLATINUM",
  "performance_score": float
}
```

**GET /api/v1/partners/analytics/clicks/**
```
Purpose: Get click analytics
Auth: Partner JWT required
Query params: start_date, end_date, granularity (day/week/month)
Response: Time series data with breakdown by: referrer, device, country
```

**GET /api/v1/partners/analytics/conversions/**
```
Purpose: Get conversion/enrollment analytics
Auth: Partner JWT required
Query params: start_date, end_date, course_id
Response: Conversion data with course breakdown
```

**GET /api/v1/partners/commissions/history/**
```
Purpose: Get commission history
Auth: Partner JWT required
Query params: status, start_date, end_date, page
Response: Paginated list of commissions with enrollment details
```

### 3.5 Commission & Payments

**GET /api/v1/partners/commissions/pending/**
```
Purpose: View pending commissions
Auth: Partner JWT required
Response: List of pending commissions awaiting approval
```

**GET /api/v1/partners/payments/history/**
```
Purpose: View payment history
Auth: Partner JWT required
Response: List of processed payments with references
```

**POST /api/v1/partners/payments/request-withdrawal/**
```
Purpose: Request commission withdrawal
Auth: Partner JWT required (minimum threshold applies)
Payload: { "amount": decimal, "payout_method": "string" }
Response: { "request_id": "uuid", "status": "PROCESSING" }
```

### 3.6 Marketing Resources

**GET /api/v1/partners/resources/**
```
Purpose: Get available marketing resources
Auth: Partner JWT required
Query params: category, course_id, format
Response: List of resources with download URLs
```

**POST /api/v1/partners/resources/{id}/download/**
```
Purpose: Track resource download
Auth: Partner JWT required
Response: Temporary download URL
```

**GET /api/v1/partners/campaigns/**
```
Purpose: Get active campaigns
Auth: Partner JWT required
Response: List of campaigns partner is enrolled in
```

### 3.7 Admin Endpoints (for internal staff)

**GET /api/v1/admin/partners/**
```
Purpose: List all partners
Auth: Admin JWT required
Query params: status, country, tier, search, page
Response: Paginated partner list
```

**POST /api/v1/admin/partners/{id}/approve/**
```
Purpose: Approve partner application
Auth: Admin JWT required
Payload: { "commission_rate": decimal, "tier": "string", "notes": "string" }
```

**POST /api/v1/admin/partners/{id}/suspend/**
```
Purpose: Suspend partner
Auth: Admin JWT required
Payload: { "reason": "string", "duration_days": integer (optional) }
```

**GET /api/v1/admin/commissions/pending/**
```
Purpose: List all pending commissions across partners
Auth: Admin JWT required
Response: List for approval
```

**POST /api/v1/admin/commissions/{id}/approve/**
```
Purpose: Approve commission
Auth: Admin JWT required
Payload: { "notes": "string" }
```

**POST /api/v1/admin/commissions/bulk-approve/**
```
Purpose: Bulk approve commissions
Auth: Admin JWT required
Payload: { "commission_ids": ["uuid list"], "notes": "string" }
```

**GET /api/v1/admin/analytics/overview/**
```
Purpose: Get program-wide analytics
Auth: Admin JWT required
Response: Comprehensive analytics dashboard data
```

---

## 4. FRONTEND COMPONENTS SPECIFICATION

### 4.1 Public-Facing Components

**A. Partner Program Landing Page**
```
Route: /partner-program
Content:
- Hero section: "Become a Hosi Academy Partner"
- Benefits cards: Commission rates, exclusive resources, dedicated support
- How it works: 3-step process (Apply → Promote → Earn)
- Success stories/testimonials
- FAQ section
- CTA: "Apply Now" button
```

**B. Partner Application Form**
```
Route: /partner-program/apply
Form Sections:
1. Personal/Business Information
   - Business name
   - Business type dropdown
   - Country of operation
   - Years of experience

2. Contact Information
   - Full name
   - Email (with verification)
   - Phone (with country code validation)
   - Preferred communication method

3. Social Media & Reach
   - Instagram handle (with follower count verification)
   - TikTok handle
   - YouTube channel
   - LinkedIn profile
   - Other platforms
   - Total estimated reach

4. Marketing Experience
   - Previous partnerships
   - Target audience description
   - Marketing strategies used
   - Target regions/countries

5. Agreement
   - Terms & conditions checkbox
   - Commission structure acknowledgment
   - Digital signature or checkbox

Validation: Real-time validation, social media URL format checking
Submit: Shows confirmation, sends email notification
```

**C. Application Status Page**
```
Route: /partner-program/application-status?token={verification_token}
Content:
- Application status display (Pending/Approved/Rejected)
- Submitted information summary
- Estimated review time
- Contact support option
- Next steps if approved
```

### 4.2 Partner Portal (Authenticated)

**A. Partner Dashboard Home**
```
Route: /partner-portal/dashboard
Components:
- Welcome header with partner name
- Quick stats cards:
  * Total earnings (MTD, YTD)
  * Active referral links
  * Clicks this month
  * Conversions this month
- Conversion rate chart (line graph)
- Recent activity feed
- Performance tier badge
- Quick actions: Create link, Download resources, View payments
```

**B. Referral Links Management**
```
Route: /partner-portal/links
Components:
- "Create New Link" button
- Table of existing links:
  * Referral code
  * Target (course/pathway)
  * Created date
  * Clicks/Conversions
  * Status (active/inactive)
  * Actions (copy, view stats, deactivate)
- Link creation modal:
  * Course/pathway selector
  * Custom code input
  * Expiration date picker
  * Usage limit setting
- Copy-to-clipboard functionality
- QR code generation for each link
```

**C. Performance Analytics**
```
Route: /partner-portal/analytics
Components:
- Date range selector
- Key metrics cards:
  * Total clicks
  * Unique clicks
  * Conversions
  * Conversion rate
  * Total revenue generated
  * Commission earned
- Charts:
  * Clicks over time (line/bar)
  * Conversions by course (pie)
  * Top performing links (bar)
  * Geographic distribution (map)
- Data table with export to CSV
```

**D. Commission & Payments**
```
Route: /partner-portal/earnings
Components:
- Earnings summary:
  * Available for withdrawal
  * Pending approval
  * Paid to date
  * Next payout date
- Commission history table:
  * Date
  * Student name (masked)
  * Course
  * Amount
  * Commission rate
  * Commission earned
  * Status
- Payment history:
  * Payment date
  * Amount
  * Method
  * Reference
  * Status
- Withdrawal request button
- Withdrawal modal with method selection
```

**E. Marketing Resources**
```
Route: /partner-portal/resources
Components:
- Category filters: Banners, Videos, Copy, Logos, Social Media Kits
- Search functionality
- Resource grid/list view:
  * Thumbnail preview
  * Title & description
  * File type & size
  * Download count
  * Download button
- Preview modal for images/videos
- Batch download option
- Usage guidelines section
```

**F. Partner Profile**
```
Route: /partner-portal/profile
Components:
- Profile information (read-only):
  * Business details
  * Approved territories
  * Commission rate
  * Tier level
- Editable sections:
  * Social media links
  * Contact information
  * Payout preferences
  * Bank account details
- Document upload:
  * Tax documents
  * ID verification
  * Business registration
- Activity log
- Change password
```

**G. Campaigns (if applicable)**
```
Route: /partner-portal/campaigns
Components:
- Active campaigns list
- Campaign details:
  * Description
  * Special commission rates
  * Target courses
  * Timeline
  * Creative assets
- Join/Leave campaign buttons
- Campaign performance tracking
```

**H. Support & Communication**
```
Route: /partner-portal/support
Components:
- FAQ section
- Contact form
- Chat widget integration (optional)
- Communication history with admin
- Resource links
```

### 4.3 Admin Dashboard Components (Internal)

**A. Partner Management Interface**
- Partner list with filters and search
- Quick actions dropdown
- Bulk operations toolbar
- Export functionality

**B. Partner Detail View**
- Tabbed interface:
  * Overview (stats & quick actions)
  * Profile information
  * Documents verification
  * Commission history
  * Performance charts
  * Communication log
- Approval workflow UI
- Suspension/termination controls

**C. Commission Approval Workflow**
- Queue of pending commissions
- Side-by-side enrollment details
- Approve/Reject with notes
- Bulk approval interface
- Payment processing integration

**D. Analytics Dashboard**
- Program-wide KPIs
- Partner performance leaderboard
- Revenue attribution charts
- Geographic heat maps
- Course performance via partners

---

## 5. USER FLOWS

### 5.1 Partner Application Flow
```
1. Landing Page (/partner-program)
   ↓
2. Click "Apply Now"
   ↓
3. Application Form (/partner-program/apply)
   ↓
4. Email verification sent
   ↓
5. Verify email (click link)
   ↓
6. Application Status Page
   ↓
7. Admin receives notification
   ↓
8. Admin reviews application
   ↓
9. Decision: Approved/Rejected
   ↓
10. Partner receives email notification
   ↓
11. If approved: Set password, access portal
```

### 5.2 Referral Conversion Flow
```
1. Partner creates referral link (partner-portal/links)
   ↓
2. Partner shares link on social media/channel
   ↓
3. Potential student clicks link
   ↓
4. System: Track click, set cookie (30-day attribution)
   ↓
5. Student browses courses
   ↓
6. Student enrolls in course
   ↓
7. System: Attribution check (cookie/referral code)
   ↓
8. Enrollment completed & payment confirmed
   ↓
9. Commission calculated & recorded (status: PENDING)
   ↓
10. Admin approves commission (after refund period)
   ↓
11. Commission status: APPROVED
   ↓
12. Payment processed (monthly/bi-weekly)
   ↓
13. Commission status: PAID
   ↓
14. Partner sees earnings in portal
```

### 5.3 Partner Portal Login Flow
```
1. Partner receives approval email with login link
   ↓
2. Clicks link, sets initial password
   ↓
3. Redirected to dashboard
   ↓
4. JWT token stored, session active
   ↓
5. Partner can:
   - View dashboard
   - Create referral links
   - Access resources
   - Track performance
   - Request withdrawals
```

---

## 6. COMMISSION STRUCTURE RECOMMENDATIONS

### 6.1 Tier-Based Commission
```
BRONZE (New Partners):
- Commission: 10-15%
- Requirements: Approved application
- Benefits: Basic referral links, standard resources

SILVER (Active Partners):
- Commission: 15-20%
- Requirements: 10+ conversions OR R10,000+ revenue
- Benefits: Priority support, early access to new courses

GOLD (High Performers):
- Commission: 20-25%
- Requirements: 50+ conversions OR R50,000+ revenue
- Benefits: Exclusive resources, co-marketing opportunities

PLATINUM (Top Partners):
- Commission: 25-30%
- Requirements: 100+ conversions OR R100,000+ revenue
- Benefits: Dedicated account manager, custom campaigns
```

### 6.2 Product-Specific Rates
```
AICERTS Courses: 20-30% (higher commission)
Masterclasses: 15-20%
Learnerships: 10-15% (longer sales cycle)
Industry Training: 15-25%
```

### 6.3 Attribution Rules
```
- Cookie duration: 30 days
- Last-click attribution
- No self-referrals
- Refund protection: Commission held for 14-30 days
```

---

## 7. TECHNICAL CONSIDERATIONS

### 7.1 Tracking Implementation
```
- URL structure: https://hosiacademy.africa/ref/{CODE}
- Cookie name: hosi_partner_ref
- Cookie expiration: 30 days
- Server-side tracking for accuracy
```

### 7.2 Security Requirements
```
- JWT token authentication for portal
- Rate limiting on API endpoints
- Document upload: Virus scan, size limits
- PII protection for student data in partner view
- Admin approval for all payouts
```

### 7.3 Integration Points
```
- Users app: Partner user creation
- Payments app: Commission calculation
- Enrollments app: Attribution tracking
- Courses app: Course data for links
- Localization app: Territory management
```

### 7.4 Scalability Considerations
```
- High-volume click tracking (separate table)
- Batch commission processing
- Async email notifications
- Caching for partner stats
```

---

## 8. IMPLEMENTATION PHASES

### Phase 1: Core Infrastructure (Weeks 1-2)
- Database models
- Admin dashboard
- Basic API endpoints
- Partner application flow

### Phase 2: Portal Development (Weeks 3-4)
- Partner portal UI
- Referral link management
- Basic analytics
- Marketing resources section

### Phase 3: Commission System (Weeks 5-6)
- Commission calculation
- Payment processing
- Commission approval workflow
- Withdrawal requests

### Phase 4: Advanced Features (Weeks 7-8)
- Advanced analytics
- Campaign management
- Performance tiers
- Mobile optimization

---

## 9. SUCCESS METRICS

### Partner Program KPIs
- Number of active partners
- Average partner earnings
- Total revenue via partners
- Partner retention rate
- Conversion rate by partner
- Cost per acquisition vs. direct

### Target Goals (First 6 Months)
- 50+ approved partners
- 20% of enrollments via partners
- R500,000+ in partner-generated revenue
- 15% average partner conversion rate
- 80% partner satisfaction rating

---

## 10. RISKS & MITIGATION

| Risk | Mitigation |
|------|------------|
| Fraudulent applications | Document verification + manual review |
| Self-referrals | Email/IP matching detection |
| Commission disputes | Clear attribution rules + audit trail |
| Partner churn | Tier incentives + dedicated support |
| Brand reputation risk | Partner code of conduct + monitoring |
| Payment fraud | Bank verification + payment delays |

---

**END OF PLAN**

This document is ready for review and can be used to guide development when you decide to proceed.
