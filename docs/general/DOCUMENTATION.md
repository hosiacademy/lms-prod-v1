# Hosi Academy LMS — Comprehensive Documentation

**Version:** 2.0
**Last Updated:** April 10, 2026
**Status:** Production

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Technical Architecture](#2-technical-architecture)
3. [Infrastructure & Deployment](#3-infrastructure--deployment)
4. [Build & Deploy Workflow](#4-build--deploy-workflow)
5. [Learning Pathways](#5-learning-pathways)
6. [Enrollment System](#6-enrollment-system)
7. [Payment System](#7-payment-system)
8. [BigBlueButton (Live Classes)](#8-bigbluebutton-live-classes)
9. [AI Concierge](#9-ai-concierge)
10. [Notifications & Real-time](#10-notifications--real-time)
11. [Localization & Geolocation](#11-localization--geolocation)
12. [African Offices](#12-african-offices)
13. [Admin Portal Structure](#13-admin-portal-structure)
14. [User Roles & Accounts](#14-user-roles--accounts)
15. [API Reference](#15-api-reference)
16. [Email Configuration](#16-email-configuration)
17. [Troubleshooting](#17-troubleshooting)
18. [Platform Comparison](#18-platform-comparison)

---

## 1. Project Overview

**Hosi Academy LMS** is a full-stack learning management system purpose-built for the African market. It combines a Flutter Web frontend with a Django REST backend, featuring multi-country payment integration, live video sessions, real-time chat, and geolocation-aware currency and payment method selection.

### Live URLs

| Purpose | URL |
|---------|-----|
| Production app | https://www.hosiacademy.africa |
| Backend API | https://www.hosiacademy.africa/api/v1/ |
| Django Admin | https://www.hosiacademy.africa/admin |

### Server

- **IP:** `154.66.211.3`
- **OS:** Ubuntu Linux
- **Entry point:** Nginx on port 443 → proxies to containers

---

## 2. Technical Architecture

### Frontend — Flutter Web

- **Framework:** Flutter 3.22+ (targeting web/JS, not WASM)
- **State management:** BLoC pattern (`flutter_bloc`)
- **Routing:** Named routes with `GoRouter`
- **Theming:** `AppTheme` constants (`hosiMidnight`, `hosiPeach`, `hosiBrown`, `successGreen`); light/dark toggle persisted via `ThemeService` and synced to backend
- **Responsive breakpoints:** mobile < 600px, tablet < 1024px, desktop ≥ 1024px
- **Services (singletons):**
  - `CurrencyService.instance` — detects currency via IP (ipapi.co), initialized in `main.dart`
  - `cartService` — backend-synced shopping cart
  - `wishlistService` — wishlist management
  - `ConciergeManager` — AI concierge iframe lifecycle

### Backend — Django 4.2

- **API framework:** Django REST Framework
- **Database:** PostgreSQL 13 (`hosiacademylms`)
- **Caching / message broker:** Redis
- **Async tasks:** Celery + Celery Beat
- **Real-time:** Socket.IO server (separate Node process)
- **Error monitoring:** Sentry (self-hosted)
- **Task monitoring:** Flower

### Infrastructure

- **Containerization:** Docker Compose (all services)
- **Reverse proxy:** Nginx (host → containers)
- **Static files:** Served by Nginx inside `lms-prod-frontend-1` container (no volume mount — files are baked in image)

---

## 3. Infrastructure & Deployment

### Container Map

| Container | Host Port | Container Port | Purpose |
|-----------|-----------|----------------|---------|
| `lms-prod-frontend-1` | 7000 | 80 | Flutter web app (Nginx) |
| `lms-prod-backend-1` | 7001 | 8000 | Django / Gunicorn API |
| `lms_socketio` | 7002 | 8001 | Socket.IO real-time server |
| `lms_flower` | 7003 | 5555 | Celery task monitoring |
| `lms_nginx` | 7004 | 80 | Secondary Nginx proxy |
| `lms_sentry` | 9000 | 9000 | Sentry error tracking |
| `lms_db` | internal | 5432 | PostgreSQL database |
| `lms_redis` | internal | 6379 | Redis cache + broker |
| `lms_celery_beat` | internal | — | Celery scheduler |
| `lms-prod-celery-1` | internal | — | Celery worker 1 |
| `lms-prod-celery-2` | internal | — | Celery worker 2 |

### Nginx Routing (host)

```
hosiacademy.africa:443  →  lms-prod-frontend-1:80  (Flutter app)
hosiacademy.africa/api/ →  lms-prod-backend-1:8000 (Django API)
```

### Database Setup

- DB container: `lms_db` (postgres:13-alpine)
- Superuser: `lms` (cluster owner — NOT `postgres`)
- Database name: `hosiacademylms`
- The `postgres` role must be created manually if needed:
  ```bash
  docker exec lms_db psql -U lms -c "CREATE ROLE postgres WITH SUPERUSER LOGIN PASSWORD 'MAZAtaka@45';"
  docker exec lms_db psql -U lms -c "CREATE DATABASE hosiacademylms OWNER postgres"
  ```

---

## 4. Build & Deploy Workflow

> **CRITICAL:** The frontend container has NO volume mount. Files must be copied in manually after every build.

### Full Deploy (3 Steps)

**Step 1 — Build Flutter web**
```bash
cd /home/tk/lms-prod/frontend
flutter build web --release --pwa-strategy=none
```
- Do **NOT** pass `--dart-define=API_BASE_URL`. `Environment.apiBaseUrl` falls back to `window.location.origin` at runtime, ensuring same-origin API calls.
- `--pwa-strategy=none` is included but may be deprecated in newer Flutter.

**Step 2 — Patch the service worker**
```bash
cat > /home/tk/lms-prod/frontend/build/web/flutter_service_worker.js << 'EOF'
'use strict';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => { event.waitUntil(self.clients.claim()); });
EOF
```
This replaces the generated SW that calls `client.navigate()` (which breaks navigation on reload).

**Step 3 — Copy into running container**
```bash
docker cp /home/tk/lms-prod/frontend/build/web/. lms-prod-frontend-1:/usr/share/nginx/html/
```

### Backend Deploy

```bash
# Rebuild and restart backend only
docker-compose up -d --no-deps --force-recreate backend

# Run migrations after code changes
docker exec lms-prod-backend-1 python manage.py migrate

# Sync AICERTS courses
docker exec lms-prod-backend-1 python manage.py sync_courses
```

### Useful Management Commands (Operational)

| Command | Purpose |
|---------|---------|
| `python manage.py sync_courses` | Sync AICERTS courses from partner API (partner_id=262) |
| `python manage.py sync_learnerships` | Sync learnership programmes |
| `python manage.py sync_industry_courses` | Sync industry-based training |
| `python manage.py populate_geopolitical_data` | Seed 54 countries, 177 states, 254 cities |
| `python manage.py populate_promotions_announcements` | Seed localized promotions |
| `python manage.py create_country_admins` | Create country-specific admin accounts |
| `python manage.py send_masterclass_invites` | Bulk send masterclass invites |
| `python manage.py send_bulk_email` | Send bulk emails |

---

## 5. Learning Pathways

### 5.1 AICERTS Courses

- Industry-certified AI and technology programmes from the AICERTS partner network (partner_id=262)
- Synced from external API via `sync_courses` management command (69+ courses)
- Frontend fetches from: `GET /api/v1/courses/courses/`
- Response is paginated: `{count, next, previous, results}`
- `AICertsCourse.fromJson` maps: `feature_image_url`, `certificate_badge_url`, `price_individual`, `title`, `id`
- `category_name` field truncated to 499 chars to avoid varchar(500) overflow

### 5.2 Learnerships

- Structured multi-month programmes (NQF 5–7 level certifications)
- Currently 7 active learnership programmes
- Duration: 6–12 months depending on track
- Endpoint: `GET /api/v1/learnerships/programmes/`
- Examples: AI QA/Testing Engineer (NQF 6, 9 months), Cybersecurity Engineer

### 5.3 Masterclasses

- Expert-led intensive sessions (half-day to full-day)
- 139 masterclasses available across SA, Kenya, Nigeria locations
- Schedule runs Mar–Dec 2026
- Endpoint: `GET /api/v1/courses/masterclasses/`
- Displayed as a scrolling marquee on the onboarding page with clickable chips

### 5.4 Corporate / Industry Training

- Enterprise-focused programmes tailored for companies
- Bulk enrollment, NET-terms invoicing, simplified per-learner details
- Route: `/enroll/corporate`

---

## 6. Enrollment System

### Multi-Step Enrollment Flow

1. **Course Selection** — Choose from available pathways
2. **Personal Details** — Name, email, phone, location (cascading country → state → city)
3. **Payment Method** — Auto-selected based on user's detected country
4. **Payment Processing** — Provider-specific flow
5. **Confirmation** — Enrollment confirmed, certificate track created, email sent

### Individual vs Corporate

| Field | Individual | Corporate |
|-------|-----------|-----------|
| ID / Passport | Required | Not required |
| Date of Birth | Required | Not required |
| Gender | Required | Not required |
| Company Name / Reg No. / Tax No. | No | Required |
| Billing Contact | No | Required |
| Learner Name + Email + Phone | Required | Required (per learner) |

### Promo / Discount System

- Backend: `GET /api/v1/localization/promotions/?country=ZA&placement=onboarding`
- Model: `LocalizedPromotion` with `discount_percentage` field
- Frontend: `PromoFlyerWidget` — animated drop-in flyer, auto-dismisses after 9s
- Enrollment modal has `APPLY PROMO` button in step 0 that opens a bottom sheet
- Discount applies to `_totalAmount` via `_discountedBaseAmount`
- Sample promos: ZA 40% youth month, KE 50% AI courses, NG free cert, GH bundle

### Email Verification

1. User registers → system generates token → verification email sent
2. User clicks link → token validated → `email_verify='1'`, `email_verified_at` set
3. User gains full access

---

## 7. Payment System

### Architecture — Adapter Pattern

All payment providers are implemented as adapters in `backend/apps/payments/adapters/`. The `PaymentService` in `services/payment_service.py` orchestrates provider selection based on the user's country and preferred method.

```
Flutter Frontend
  └── Payment Bloc
        └── API Client → POST /api/v1/payments/initiate/
              └── PaymentService (Django)
                    └── PaymentAdapter (per provider)
                          └── External provider API
                          └── Webhook → POST /api/v1/payments/webhook/
```

### Payment Methods by Country

| Country | Methods |
|---------|---------|
| 🇿🇦 South Africa | Cards (Visa/MC), EFT bank transfer, SnapScan, Zapper, Cash/on-site |
| 🇰🇪 Kenya | M-Pesa STK push, Cards, Airtel Money, Cash/on-site |
| 🇿🇼 Zimbabwe | EcoCash, ZimSwitch, InnBucks, Visa/MC, Bank Transfer, Cash/on-site |
| 🇿🇲 Zambia | Mobile Money, Cards, Bank Transfer, Cash/on-site |
| 🇳🇬 Nigeria | Paystack, Cards, Bank Transfer |
| 🇬🇭 Ghana | Mobile Money (MTN/Airtel), Cards, Bank Transfer |

### Payment Providers

| Provider | Region | Methods |
|----------|--------|---------|
| **Flutterwave** | Pan-African | Cards, Mobile Money, Bank Transfer |
| **Paystack** | Nigeria / Ghana | Cards, Bank Transfer |
| **M-Pesa** (Daraja API) | Kenya | STK Push mobile money |
| **SmatPay** | Zimbabwe + UK | ZimSwitch, EcoCash, InnBucks, Visa/MC, subscriptions |
| **Stripe** | International | Cards (Visa/MC/Amex) |
| **PayNow** | Zimbabwe | Local bank transfers |
| **PayPal** | International | Cards + PayPal balance |
| **MTN MoMo** | West/East Africa | Mobile money |
| **Airtel Money** | Multiple countries | Mobile money |
| **Orange Money** | West Africa | Mobile money |
| **Cash/On-site** | All countries | Manual, physical payment |
| **EFT/Bank Transfer** | ZA, ZW, KE, ZM, NG | Bank-to-bank transfer with reference |

### SmatPay (Zimbabwe + UK)

SmatPay is developed by Smatech Group and is the primary gateway for Zimbabwe users.

- **Live API:** `https://live.smatpay.africa`
- **Documentation:** https://doc.smatpay.africa/
- **Support:** support@smatpay.africa
- **Adapter:** `backend/apps/payments/adapters/smatpay.py`

**Authentication flow:**
```
POST /token/production  →  returns bearer token
POST /init/authenticate/merchant/wallet  →  card payments
POST /pay/ecocash  →  EcoCash STK push
POST /pay/innbucks  →  InnBucks
POST /api/v1/payments/status  →  verify payment
POST /api/v1/payments/refund  →  issue refund
POST /generate-payment-token  →  tokenize card for recurring
POST /generate-recurring-payment  →  subscription setup
```

**SmatPay error codes:**

| Code | Meaning |
|------|---------|
| `000` | Success |
| `001` | General error — retry once |
| `002` | Invalid credentials |
| `003` | Insufficient funds |
| `004` | Card declined |
| `005` | Invalid phone number |
| `006` | Timeout |

**SmatPay test cards (sandbox):**
- Visa: `4111 1111 1111 1111`
- Mastercard: `5555 5555 5555 4444`
- ZimSwitch: `4242 4242 4242 4242`
- Expiry: `12/26`, CVV: `123`

### EFT / Bank Transfer

EFT is available in ZA, ZW, KE, ZM. After user initiates EFT:
1. User receives bank account details + unique reference
2. User makes transfer via their bank
3. Admin verifies transfer in Payment Admin portal
4. Enrollment confirmed on verification

EFT admin notifications sent via email templates:
- `eft_initiated.html`, `eft_verified.html`, `eft_rejected.html`

### Cash / On-site Payments

Office addresses used as payment points (matched by user's IP):

| Country | Address |
|---------|---------|
| 🇿🇦 SA (Johannesburg) | 123 Sandton Street, Sandton |
| 🇿🇦 SA (Cape Town) | 456 Long Street, City Centre |
| 🇰🇪 Kenya | The Oval House, Ring Road, Westlands, 2nd floor, Nairobi |
| 🇿🇼 Zimbabwe | 100 Liberation Legacy Way, Harare |
| 🇿🇲 Zambia | Lusaka Conference Center, Cairo Road, Lusaka |

### Payment API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/v1/payments/initiate/` | Initiate a payment |
| POST | `/api/v1/payments/webhook/` | Provider webhook callback |
| GET | `/api/v1/payments/coupons/public/?country={code}` | Available coupons |
| POST | `/api/v1/payments/contact-otp/send/` | Send OTP for contact verification |
| GET | `/api/v1/payments/providers/?country={code}` | Available providers by country |

### Currency Localization

- `CurrencyService.instance` detects user currency via `ipapi.co` on app init
- Supported: USD, ZAR, KES, NGN, GHS, ZMW, ZWL, GBP
- `CurrencyService.instance.formatUSDAmount(amount)` converts USD to local currency
- Exchange rates updated daily via Celery Beat scheduled task
- Course model maps `json['local_price'] ?? json['formatted_price']` → `localPrice`

---

## 8. BigBlueButton (Live Classes)

### Overview

BigBlueButton (BBB) provides live video conferencing for instructor-led sessions.

- **Backend app:** `apps/bbb_integration/`
- **API URL prefix:** `/api/v1/bbb/`
- **Config:** Parsed from `.env` — `BBB_ENABLED`, `BBB_API_URL`, `BBB_SECRET`

### Session Lifecycle

| Role | Action | Endpoint |
|------|--------|----------|
| Instructor | Create session | `POST /api/v1/bbb/sessions/` |
| Instructor | Start session | `POST /api/v1/bbb/sessions/{id}/start/` |
| Student | Join session | `GET /api/v1/bbb/sessions/{id}/join/` → returns `join_url` |
| Both | List upcoming | `GET /api/v1/bbb/sessions/upcoming/` |

### Frontend

- **Student dashboard:** `student_dashboard.dart` — `live_sessions` menu
- **Instructor dashboard:** `instructor_dashboard.dart` — BBB tab
- **Session viewer:** `instructor/bbb_session_viewer.dart`
  - Mobile: WebView
  - Web: opens `join_url` in new tab

### Known Notes

- `.env` had corrupted line `BBB_LOCK_SETTINGS_DISABLE_MIC=FalseFRONTEND_URL=...` (now fixed)
- After any `.env` change, backend must be recreated: `docker-compose up -d --no-deps --force-recreate backend`

---

## 9. AI Concierge

- **URL:** `https://hosi-academy-concierge-510764236399.us-west1.run.app/` (Cloud Run)
- **Implementation:** iframe `hosi-widget-frame`, fixed position bottom-right (`right:16px; bottom:80px`)
- **Size:** 420px wide × 80vh (clamped 480–680px); shrinks on narrow screens
- **Manager:** `lib/src/core/services/concierge_manager.dart`
  - Methods: `open()`, `closeAny()`, `toggleFromFab()`, `openAtBottomRight()`
- **Entry point:** FAB-only (`_ConciergeFab`) at bottom-right of `onboarding_page.dart`
  - FAB retreats to `right:-8` when scrolled past 300px
  - Expands label on hover
- Also toggleable from `dashboard_header.dart` and `enrollment_page_header.dart`
- `ConciergeService.setPrompt()` posts `{type:'user-prompt', text:...}` message to the iframe
- Disposed (closed) automatically on page navigation

---

## 10. Notifications & Real-time

### Email Notifications

Triggered at enrollment and payment events. Templates in `backend/apps/notifications/templates/notifications/emails/`:

| Template | Trigger |
|----------|---------|
| `enrollment_success.html` | Successful enrollment |
| `enrollment_failure.html` | Failed enrollment |
| `eft_initiated.html` | EFT payment submitted |
| `eft_verified.html` | EFT payment verified by admin |
| `eft_rejected.html` | EFT payment rejected |

### Real-time (Socket.IO)

- **Container:** `lms_socketio` (port 7002)
- **Purpose:** Live notifications, instructor–student presence, chat messages
- Communication: frontend connects to Socket.IO, backend emits events via Redis pub/sub
- Instructor notification service: `backend/apps/notifications/instructor_notifications.py`

---

## 11. Localization & Geolocation

### Geopolitical Data API

| Endpoint | Description |
|----------|-------------|
| `GET /api/v1/localization/countries/` | 54 African countries (`{id, code, name, is_active, phone_code}`) |
| `GET /api/v1/localization/states/?country_id={id}` | States/provinces by country integer ID |
| `GET /api/v1/localization/cities/?state_id={id}` | Cities by state ID |
| `GET /api/v1/localization/cities/?country_id={id}` | Cities by country ID |

**DB populated:** 54 countries, 177 states, 254 cities via `populate_geopolitical_data` management command.

### Frontend Localization Widgets

- **LocationBloc:** `lib/src/presentation/blocs/student_portal/location_bloc.dart`
- **CascadingLocationDropdowns:** `cascading_location_dropdowns.dart` — cascading country → state → city selectors with error/retry widget
- **LearnerPortalApiService:** `getCountries()`, `getStates()`, `getCities()`

### Theme Preference

- **Endpoint:** `GET/POST /api/v1/user/theme/`
- **Model:** `UserThemePreference` in `backend/apps/users/`
- **Frontend:** `theme_service.dart` syncs light/dark preference with backend on login/change

---

## 12. African Offices

Physical office locations used for cash payment drop-off and navigation:

| Country | City | Address | Coordinates |
|---------|------|---------|-------------|
| 🇿🇦 South Africa | Johannesburg | 123 Sandton Street, Sandton | -26.1076, 28.0567 |
| 🇿🇦 South Africa | Cape Town | 456 Long Street, City Centre | -33.9249, 18.4241 |
| 🇰🇪 Kenya | Nairobi | The Oval House, Ring Road, Westlands, 2nd floor | -1.2644, 36.8098 |
| 🇿🇼 Zimbabwe | Harare | 100 Liberation Legacy Way | -17.8252, 31.0335 |
| 🇿🇲 Zambia | Lusaka | Lusaka Conference Center, Cairo Road | -15.3875, 28.3228 |

**Frontend widget:** `frontend/lib/src/presentation/pages/onboarding/widgets/sections/africa_addresses.dart`
- Responsive grid: 3 cols desktop / 2 tablet / 1 mobile
- Each card has clickable phone number and "Get Directions" button
- Map opening: Google Maps → Apple Maps → geo URI → Google Maps Web (fallback chain)

---

## 13. Admin Portal Structure

Three admin portals — all follow the same shell pattern as `instructor_dashboard.dart`:

- Shell: `DefaultTabController` + `TabBar`, no gradient, no sidebar
- Mobile: AppBar (primary bg) + TabBar in `bottom` + Drawer
- Desktop: `DashboardHeader` + `Container(color: colors.surface)` TabBar + TabBarView
- Drawer items use `DefaultTabController.of(context).animateTo(index)`
- Badge counts via `Badge(child: Icon(...))` inside `Tab(icon:...)`

### Portal Tabs

| Portal | File | Tabs |
|--------|------|------|
| Payment Admin | `payment_admin_page.dart` | Dashboard / Enrollments / Learners / Verification / Payments |
| HR Admin | `hr_admin_page.dart` | Dashboard / Instructors / Attendance / Overtime / Payroll |
| Executive Admin | `executive_admin_page.dart` | Dashboard / Financials / Performance / Analytics |

---

## 14. User Roles & Accounts

### Role IDs

| role_id | Role |
|---------|------|
| 1 | Admin / Staff |
| 2 | Instructor |
| 3 | Student |

### Super Admins

| Username | Email | Password |
|----------|-------|----------|
| takawira.mazando | mazandotakawira01@gmail.com | `Takawira@Hosi2026!` |
| richard.masukume | richard.masukume@hosiacademy.co.za | `Richard@Hosi2026!` |
| samuel.mokoena | samuel.mokoena@hosiacademy.africa | `Samuel@Hosi2026!` |

### Universal Admin

| Username | Email | Password |
|----------|-------|----------|
| system_admin | system.admin@hosi.academy | `System@Hosi2026!` |

### Country Admins (4 roles × 4 countries = 16 accounts)

Pattern: `{role}_{country_code}` / `{role}.{country}@hosi.academy` / Password: `{CC}-{role}-2026@`

| Country | HR | Payment | System | Executive |
|---------|----|---------|----|-----------|
| Kenya (KE) | `KE-hr-2026@` | `KE-payment-2026@` | `KE-system-2026@` | `KE-exec-2026@` |
| Zimbabwe (ZW) | `ZW-hr-2026@` | `ZW-payment-2026@` | `ZW-system-2026@` | `ZW-exec-2026@` |
| South Africa (ZA) | `ZA-hr-2026@` | `ZA-payment-2026@` | `ZA-system-2026@` | `ZA-exec-2026@` |
| Zambia (ZM) | `ZM-hr-2026@` | `ZM-payment-2026@` | `ZM-system-2026@` | `ZM-exec-2026@` |

### BBB Student Accounts (password: `HosiLearn@2026!`)

| Name | Email |
|------|-------|
| Richard Masukume | richard.masukume@hosiacademy.co.za |
| Amara Diallo | amara.diallo@hosiacademy.africa |
| Chidi Okonkwo | chidi.okonkwo@hosiacademy.africa |
| Fatima Nkosi | fatima.nkosi@hosiacademy.africa |
| Kofi Asante | kofi.asante@hosiacademy.africa |
| Zanele Dlamini | zanele.dlamini@hosiacademy.africa |

---

## 15. API Reference

### Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login/` | User login |
| POST | `/api/v1/auth/register/` | User registration |
| POST | `/api/v1/auth/send-verification/` | Send email verification |
| GET | `/api/v1/auth/verify-email/{token}/` | Verify email token |

### Courses & Learning

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/courses/courses/` | AICERTS courses (paginated) |
| GET | `/api/v1/courses/masterclasses/` | Masterclass sessions |
| GET | `/api/v1/learnerships/programmes/` | Learnership programmes |

### Payments

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/payments/initiate/` | Initiate payment |
| POST | `/api/v1/payments/webhook/` | Payment webhook |
| GET | `/api/v1/payments/coupons/public/?country={code}` | Public coupons |
| GET | `/api/v1/payments/providers/?country={code}` | Providers by country |

### Student Portal

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/student-portal/dashboard/` | Student dashboard data |
| GET | `/api/v1/student-portal/content-types/` | Content type counts |

### Localization

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/localization/countries/` | 54 African countries |
| GET | `/api/v1/localization/states/?country_id={id}` | States by country |
| GET | `/api/v1/localization/cities/?state_id={id}` | Cities by state |
| GET | `/api/v1/localization/promotions/?country={code}&placement=onboarding` | Active promotions |

### BBB Live Sessions

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/bbb/sessions/upcoming/` | Upcoming sessions |
| POST | `/api/v1/bbb/sessions/` | Create session (instructor) |
| POST | `/api/v1/bbb/sessions/{id}/start/` | Start session (instructor) |
| GET | `/api/v1/bbb/sessions/{id}/join/` | Join session (student) |

### User / Preferences

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET/POST | `/api/v1/user/theme/` | Get/set theme preference |

---

## 16. Email Configuration

- **SMTP Host:** `mail.hosiafrica.com`
- **From:** `Hosi Academy <academy@hosiafrica.com>`
- **Backend:** `django.core.mail.backends.smtp.EmailBackend`
- Config in `backend/.env.prod`

---

## 17. Troubleshooting

### Frontend doesn't update after build
Ensure Step 3 (docker cp) was run. The container has no volume mount — files are NOT automatically updated.

### CORS failures on API calls
`Environment.apiBaseUrl` falls back to `window.location.origin` at runtime. Do NOT hardcode `hosiacademy.africa` (no-www) as the site is served on `www.hosiacademy.africa`.

### 400 Bad Request from backend
`ALLOWED_HOSTS` in `.env.prod` must include both `hosiacademy.africa` and `www.hosiacademy.africa`.

### Service worker breaks navigation on reload
Patch `build/web/flutter_service_worker.js` with the no-op content after every build (Step 2 above).

### BBB not working after `.env` change
Must recreate the backend container: `docker-compose up -d --no-deps --force-recreate backend`

### Masterclasses not displaying
Clear browser cache and reload. Check `masterclass_calendar.dart` month filtering logic.

### Sentry 403 errors
Sentry has been disabled in `main.dart`. Safe to ignore if it reappears.

### Theme 403 errors
Authentication check is enforced in `theme_service.dart` — theme sync only runs when user is logged in.

### `postgres` role missing in DB
```bash
docker exec lms_db psql -U lms -c "CREATE ROLE postgres WITH SUPERUSER LOGIN PASSWORD 'MAZAtaka@45';"
```

### `phone_code` column missing on countries table
```bash
docker exec lms_db psql -U lms -d hosiacademylms -c "ALTER TABLE localization_countries ADD COLUMN IF NOT EXISTS phone_code VARCHAR(10);"
```

### Checking logs
```bash
docker logs lms-prod-backend-1 --tail=100 -f
docker logs lms-prod-frontend-1 --tail=50
docker logs lms_socketio --tail=50
```

### Checking API in browser

Open DevTools → Network → filter XHR/Fetch. Look for:
- `/api/v1/courses/masterclasses/?page=1&page_size=500` → 200, 139 items
- `/api/v1/learnerships/programmes/?page=1&page_size=50` → 200, 7 items

Console should show:
```
🌐 API base URL: https://www.hosiacademy.africa
Loaded 139 masterclasses from API
```

---

## 18. Platform Comparison

Hosi Academy LMS compared to major commercial platforms (1,000 active users, 3-year TCO baseline):

### Feature Scores (out of 10)

| Feature Area | Hosi Academy | Moodle | Canvas | Teachable | TalentLMS | Docebo |
|--------------|:---:|:---:|:---:|:---:|:---:|:---:|
| Course management | 10 | 8 | 8 | 5 | 7 | 8 |
| Payment processing | **10** | 3 | 2 | 4 | 4 | 5 |
| Live classes (BBB) | 9 | 6 | 7 | 1 | 6 | 7 |
| Real-time chat | **10** | 3 | 4 | 1 | 3 | 4 |
| Multi-currency (African) | **10** | 3 | 3 | 1 | 3 | 4 |
| Localization / Geolocation | **10** | 7 | 6 | 2 | 5 | 7 |

### Key Differentiators

Hosi Academy LMS leads all compared platforms in:

- **28+ payment gateways** — no other platform natively supports African mobile money (M-Pesa, MTN, Airtel, EcoCash, InnBucks), pan-African aggregators (Flutterwave, Paystack), cash/on-site payments, and QR codes in a single unified system
- **Native African currency detection** — GeoIP-based auto-conversion for ZAR, KES, NGN, GHS, ZMW, ZWL with daily Celery-scheduled exchange rate updates
- **Corporate invoicing with NET terms** — not available in any compared SaaS platform natively
- **Socket.IO real-time chat** — 1-on-1 messaging, group discussions, read receipts, message types (text/image/file/audio/video), user presence — none of the compared platforms match this feature set
- **External course sync (AICERTS API)** — unique to Hosi Academy
- **BBB multi-server load balancing** — enterprise-grade live class infrastructure

---

*Last updated: April 10, 2026*
