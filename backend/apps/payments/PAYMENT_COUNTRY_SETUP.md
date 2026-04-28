# Payment Provider - Country Integration Guide

## Overview

This system provides IP-based geolocation to automatically detect a user's country and show them only the relevant payment providers available in their region. This ensures:

1. **No confusion**: Zimbabwean students see Paynow/EcoCash, not South African Yoco
2. **Higher conversion**: Users see familiar payment methods first
3. **Compliance**: Respects regional payment regulations
4. **Better UX**: Automatic country detection, no manual selection needed

## Architecture

```
User Request → CountryDetectionMiddleware → IP Geolocation → Country Code
                                              ↓
                                    Payment Service
                                              ↓
                            ProviderCountryConfig (filtered)
                                              ↓
                              Relevant Providers Only
```

## Files Created

```
apps/payments/
├── services/
│   └── geolocation_service.py    # IP → Country detection
├── management/commands/
│   └── seed_country_providers.py # Seed country-provider data
├── views/
│   └── country_views.py          # API endpoints
├── middleware.py                  # Country detection middleware
└── urls.py                       # Updated with new routes
```

## Setup Instructions

### Step 1: Install GeoIP2 Dependencies

```bash
# Install Python package
pip install geoip2

# Download GeoLite2 database (free)
cd /home/tk/lms-prod/backend
wget https://git.io/GeoLite2-Country.mmdb
# OR download from MaxMind (requires free account):
# https://dev.maxmind.com/geoip/geolite2-free-geolocation-data
```

### Step 2: Run Management Command

```bash
cd /home/tk/lms-prod/backend
source venv/bin/activate  # or venv_linux/bin/activate

# Seed country-provider relationships
python manage.py seed_country_providers
```

This will create:
- 22 African countries in `localization_countries`
- 50+ payment provider models
- 100+ provider-country configurations
- 22 country payment landscapes

### Step 3: Verify Middleware

Ensure middleware is in `settings.py`:

```python
MIDDLEWARE = [
    # ... other middleware
    'apps.payments.middleware.CountryDetectionMiddleware',
]
```

### Step 4: Test the System

```bash
# Start server
python manage.py runserver

# Test IP detection (from browser or curl)
curl http://localhost:8000/api/payments/detect-country/

# Test with specific IP
curl "http://localhost:8000/api/payments/test-ip-detection/?ip=197.80.0.1"

# Get providers for detected country
curl http://localhost:8000/api/payments/providers/

# Get providers for specific country
curl "http://localhost:8000/api/payments/providers/?country=KE&amount=1000&currency=KES"

# Get all African countries with providers
curl http://localhost:8000/api/payments/countries/
```

## API Endpoints

### 1. Detect Country from IP
```
GET /api/payments/detect-country/
```

**Response:**
```json
{
    "country_code": "ZW",
    "country_name": "Zimbabwe",
    "is_african": true,
    "ip_address": "197.80.0.1",
    "currency": "USD",
    "recommended_providers": ["paynow", "ecash", "telecash"]
}
```

### 2. Get Available Providers
```
GET /api/payments/providers/?country=ZW&amount=50&currency=USD
```

**Response:**
```json
{
    "country": "ZW",
    "country_name": "Zimbabwe",
    "currency": "USD",
    "providers": [
        {
            "code": "paynow",
            "name": "Paynow",
            "category": "local_gateway",
            "methods": ["mobile_money", "ussd", "bank_transfer"],
            "currencies": ["USD", "ZWL"],
            "min_amount": 1.00,
            "max_amount": 10000.00,
            "fee_percentage": 2.5,
            "is_recommended": true,
            "priority": 1
        }
    ]
}
```

### 3. Get All Countries
```
GET /api/payments/countries/?africa_only=true&include_providers=true
```

### 4. Test IP Detection
```
GET /api/payments/test-ip-detection/?ip=197.80.0.1
```

## Country-Provider Mapping

### Zimbabwe (ZW)
- **Primary**: Paynow, EcoCash, OneMoney, Telecash
- **Secondary**: Pesapal, Flutterwave
- **Currency**: USD, ZWL

### Kenya (KE)
- **Primary**: M-Pesa, Airtel Money
- **Secondary**: Flutterwave, Paystack, Pesapal
- **Currency**: KES

### Nigeria (NG)
- **Primary**: Paystack, Flutterwave, Monnify, Interswitch, Remita
- **Secondary**: Opay, PalmPay, Paga
- **Currency**: NGN

### South Africa (ZA)
- **Primary**: PayFast, Yoco, Peach, Ozow, SnapScan
- **Secondary**: Standard Bank API, Absa API, FNB API
- **Currency**: ZAR

### Ghana (GH)
- **Primary**: Paystack, Flutterwave, ExpressPay, Zeepay
- **Secondary**: Slydepay, Hubtel
- **Currency**: GHS

### Egypt (EG)
- **Primary**: Fawry, Paymob, Valu
- **Secondary**: Masary
- **Currency**: EGP

## How IP Detection Works

### Primary Method: GeoLite2 Database
- Uses MaxMind's free GeoLite2 database
- Accurate to country level
- Updated monthly

### Fallback Method: IP Range Matching
If GeoLite2 is unavailable, falls back to known African IP ranges:
- Econet/EcoCash: `197.80.x.x` (Zimbabwe)
- Safaricom M-Pesa: `196.201.x.x` (Kenya)
- MTN Nigeria: `41.184.x.x` (Nigeria)
- Vodacom SA: `196.10.x.x` (South Africa)

## Payment Service Integration

The `PaymentService` now automatically filters providers by country:

```python
from apps.payments.services.payment_service import payment_service

# Get providers for detected country
providers = payment_service.get_available_providers(
    country='ZW',  # Or from request.detected_country_code
    amount=50,
    currency='USD'
)

# Initiate payment with country-aware validation
result = payment_service.initiate_payment(
    user=request.user,
    amount=50,
    currency='USD',
    country='ZW',  # Auto-detected from IP
    provider_code='paynow',
    ip_address=request.ip_address,
)
```

## Middleware Usage

The middleware automatically attaches country info to every request:

```python
# In any view
def payment_view(request):
    country = request.detected_country_code  # 'ZW', 'KE', etc.
    is_african = request.is_african_user
    ip = request.ip_address
    
    # Use in payment logic
    providers = payment_service.get_available_providers(country)
```

## Troubleshooting

### Country not detected
1. Check if IP is in African IP ranges
2. Verify GeoLite2 database exists at `GEOIP_PATH`
3. Check logs: `tail -f logs/debug.log`

### Providers not showing
1. Run `python manage.py seed_country_providers`
2. Check `ProviderCountryConfig` in database
3. Verify provider is active: `ProviderCountryConfig.objects.filter(is_active=True)`

### Middleware not working
1. Verify middleware is in `MIDDLEWARE` list in settings.py
2. Check middleware order (should be after SessionMiddleware)
3. Restart Django server

## Next Steps: Sandbox Testing

Now that countries and providers are linked, proceed to sandbox testing:

```bash
# Test Paynow (Zimbabwe) webhook flow
python manage.py test_paynow_webhook

# Test M-Pesa (Kenya) STK Push
python manage.py test_mpesa_stk

# Test Flutterwave (Nigeria) card payment
python manage.py test_flutterwave_card
```

## Support

For issues or questions:
1. Check logs: `/home/tk/lms-prod/backend/logs/`
2. Review GeoIP service: `apps/payments/services/geolocation_service.py`
3. Test with: `/api/payments/test-ip-detection/`
