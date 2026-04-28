# Twilio & Email Marketing Messaging System - Frontend Implementation

**Date:** April 17, 2026  
**Status:** ✅ COMPLETE  
**Framework:** Flutter Web  
**Backend:** Django REST Framework (3 weeks ahead)

---

## Overview

Complete implementation of Twilio SMS marketing and email campaign messaging system in the Payment and Marketing admin portal. This system enables administrators to send bulk SMS campaigns and email communications to users, with comprehensive delivery tracking and statistics.

### Key Features

- **Bulk SMS Campaigns** - Send SMS to 500+ recipients with Twilio integration
- **Email Campaigns** - Compose and send email communications
- **User Targeting** - Select recipients from LMS users or manual phone number entry
- **Country Filtering** - Support for ZA (+27), KE (+254), ZW (+263), ZM (+260)
- **Campaign History** - Track all sent communications with delivery stats
- **Real-time Stats** - Dashboard showing sent, failed, and skipped messages
- **CSV Upload Ready** - Infrastructure for batch recipient import

---

## Architecture

### Data Models (`lib/src/data/models/messaging.dart`)

```dart
// SMS Campaign
class SMSCampaign {
  String messageText;
  List<String> recipientNumbers;
  List<int> userIds;
  String status; // 'draft', 'sending', 'sent', 'failed'
  int totalRecipients;
  int successCount, failureCount, skippedCount;
  List<SMSDeliveryResult> results;
}

// Email Campaign
class EmailCampaign {
  String subject, body;
  String templateType;
  List<String> recipientEmails;
  String status;
  int successCount, failureCount;
}

// User selection
class UserPhone {
  int id;
  String name, email, phone;
  String country;
}

// Communication tracking
class CommunicationLog {
  String type; // 'sms', 'email', 'whatsapp'
  String recipient, content, status;
  DateTime createdAt, sentAt;
}
```

### API Integration (`lib/src/core/api/api_client.dart`)

#### Bulk SMS Endpoints

```dart
// Send bulk SMS campaign
sendBulkSMS({
  required String message,
  required List<String> numbers,
  List<int> userIds,
}) → Future<Map>
// POST /api/v1/payments/admin/bulk-sms/send/

// Get users with phone numbers (for targeting)
getUserPhoneList({
  String search,
  String country,
}) → Future<List<Map>>
// GET /api/v1/payments/admin/bulk-sms/users/
// Query params: search, country (ZA|KE|ZW|ZM)

// Campaign history
getSMSCampaignHistory({
  int limit,
  int offset,
}) → Future<List<Map>>
// GET /api/v1/payments/admin/bulk-sms/campaigns/

// Campaign details
getSMSCampaignDetail(int campaignId) → Future<Map>
// GET /api/v1/payments/admin/bulk-sms/campaigns/{id}/
```

#### Email Endpoints

```dart
// Send bulk email
sendBulkEmail({
  required String subject,
  required String body,
  required List<String> emails,
  List<int> userIds,
  String templateType,
}) → Future<Map>
// POST /api/v1/communications/email/send/

// Email campaign history
getEmailCampaignHistory({
  int limit,
  int offset,
}) → Future<List<Map>>
// GET /api/v1/communications/email/campaigns/
```

#### Communication Logs

```dart
// Get all communications
getCommunicationLogs({
  String campaignId,
  String type, // 'sms', 'email'
  String status, // 'sent', 'failed', 'pending'
  int limit, offset,
}) → Future<List<Map>>
// GET /api/v1/communications/logs/

// Export logs
exportCommunicationLogs({
  String format = 'csv', // 'csv' or 'xlsx'
}) → Future<Uint8List>
// GET /api/v1/communications/logs/export/
```

#### Dashboard & Templates

```dart
// Messaging statistics
getMessagingStats({
  String dateFrom,
  String dateTo,
}) → Future<Map>
// GET /api/v1/communications/stats/

// Message templates
getMessageTemplates({
  String category, // 'sms', 'email', 'whatsapp'
}) → Future<List<Map>>
// GET /api/v1/communications/templates/

// WhatsApp templates
getWhatsAppTemplates() → Future<List<Map>>
// GET /api/v1/communications/templates/?category=whatsapp

// Send WhatsApp
sendWhatsAppMessage({
  required String toNumber,
  required String messageBody,
  String templateSid,
  Map<String, dynamic> templateVariables,
}) → Future<Map>
// POST /api/v1/communications/whatsapp/send/
```

---

## UI Components

### Messaging Tab in Payment Admin Dashboard

Located in the admin portal tabbed interface with three sub-tabs:

#### 1. SMS Campaigns Tab

**Features:**
- Message composer with real-time character count
- SMS count calculator (160 chars = 1 SMS, 153 chars per additional SMS)
- Recipient selection:
  - Manual phone number entry
  - LMS user selection with search and country filtering
  - Support for 500 recipients per campaign
- Campaign summary with stats
- Send confirmation and progress tracking

**UI Components:**
- Message text area (max 1600 chars)
- Manual numbers input field
- User search with country filter dropdown
- Recipient chips showing selected numbers
- Statistics cards (Total SMS, Sent, Failed)
- Send button with loading indicator
- Recipient count display

#### 2. Email Campaigns Tab

**Features:**
- Email subject and body composer
- HTML support
- Recipient selection (similar to SMS)
- Template type selection (optional)
- Campaign tracking

**UI Components:**
- Subject text field
- Body text area with HTML support
- Template selector dropdown
- Recipient selection (search + filters)
- Send button with progress
- Stats display

#### 3. Communication History Tab

**Features:**
- List of all sent campaigns
- Status indicators (Sent, Failed, Pending)
- Per-campaign statistics
  - Total recipients
  - Successfully sent count
  - Failed count
  - Skipped count
- Message preview (first 100 chars)
- Campaign detail access

**UI Components:**
- Campaign list cards
- Status badges with color coding
- Message preview truncation
- Statistics row per campaign
- Empty state message

---

## Frontend Integration Points

### State Management

```dart
// SMS Campaign state
TextEditingController _smsMessageController;
List<String> _selectedPhoneNumbers;
List<int> _selectedUserIds;
bool _isSendingSMS;
String _userPhoneSearchQuery;
String _userPhoneCountryFilter;

// Email Campaign state
TextEditingController _emailSubjectController;
TextEditingController _emailBodyController;
List<String> _selectedEmails;
bool _isSendingEmail;

// Data
List<Map<String, dynamic>> _userPhoneList;
List<Map<String, dynamic>> _smsCampaigns;
List<Map<String, dynamic>> _communicationLogs;
Map<String, dynamic> _messagingStats;
```

### Key Methods

```dart
// Loading
Future<void> _loadMessagingData() async
  // Loads user phone list and campaigns

// SMS Sending
Future<void> _sendSMSCampaign() async
  // Validates message and recipients
  // Calls ApiClient.sendBulkSMS()
  // Updates UI with results
  // Refreshes campaign history

// Email Sending
Future<void> _sendEmailCampaign() async
  // Similar to SMS but for email

// UI Building
Widget _buildMessagingView(ThemeData, ColorScheme)
Widget _buildSMSCampaignView(ThemeData, ColorScheme)
Widget _buildEmailCampaignView(ThemeData, ColorScheme)
Widget _buildCommunicationHistoryView(ThemeData, ColorScheme)

// Helpers
int _getSMSCount()
  // Calculates SMS count based on message length
void _addManualPhoneNumbers()
  // Parses and validates phone numbers
```

---

## Backend Integration (Source of Truth)

### Base Endpoint

```
POST /api/v1/payments/admin/bulk-sms/send/
```

**Authentication:** Bearer token (admin only)

**Request Body:**
```json
{
  "message": "Your SMS message text",
  "numbers": ["+27821234567", "+254712345678"],
  "user_ids": [1, 2, 3]
}
```

**Response Success (200):**
```json
{
  "success": true,
  "summary": {
    "total": 3,
    "sent": 2,
    "failed": 1,
    "skipped": 0
  },
  "details": {
    "sent": [
      {"number": "+27821234567", "sid": "SM...", "status": "sent"}
    ],
    "failed": [
      {"number": "+254712345678", "error": "Invalid number format"}
    ],
    "skipped": []
  }
}
```

### Supported Countries

| Country | Code | Prefix |
|---------|------|--------|
| South Africa | ZA | +27 |
| Kenya | KE | +254 |
| Zimbabwe | ZW | +263 |
| Zambia | ZM | +260 |

### Twilio Configuration

**Environment Variables (Backend):**
```
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+27123456789
TWILIO_CONTENT_SID=HXb5b62575e6e4ff6129ad7c8efe1f983e (optional)
```

**Messaging Service SID:**
```
MG17481cdaf787ad333c48f42eec53e005
```

---

## Error Handling

### SMS Sending Errors

```dart
try {
  final result = await ApiClient.sendBulkSMS(
    message: message,
    numbers: numbers,
  );
  
  if (result['success'] != true) {
    showSnackBar('Error: ${result['error']}');
  }
} catch (e) {
  showSnackBar('Failed to send SMS: $e');
}
```

### Phone Number Validation

- Must include country code (e.g., +27, +254)
- Must be E.164 format
- Supports: +27, +254, +263, +260

### Recipient Validation

- At least one recipient required
- Max 500 recipients per campaign
- Automatic deduplication

---

## Statistics & Reporting

### Dashboard Metrics

```dart
_messagingStats = {
  'total_sms': 150,
  'sms_sent': 145,
  'sms_failed': 5,
  'total_emails': 50,
  'email_sent': 48,
  'email_failed': 2,
}
```

### Campaign Analytics

- Total recipients
- Successfully delivered
- Failed deliveries (with reasons)
- Skipped (invalid numbers, duplicates)
- Delivery rate percentage
- Failure rate percentage

---

## Usage Examples

### Send SMS Campaign

```dart
// 1. User enters message
_smsMessageController.text = "Your course is ready! Access now...";

// 2. User selects recipients
_selectedPhoneNumbers = ["+27821234567", "+254712345678"];
_selectedUserIds = [];

// 3. Click "Send SMS Campaign"
await _sendSMSCampaign();

// 4. Result shown:
// "SMS campaign sent! Sent: 2, Failed: 0"

// 5. Campaign history updated with new entry
```

### Filter Users for Targeting

```dart
// Search specific users
_userPhoneSearchQuery = "john";
await _loadMessagingData();

// Filter by country
_userPhoneCountryFilter = "ZA";
await _loadMessagingData();

// Results show matching users with phone numbers
// User can select multiple users for campaign
```

### View Campaign History

```dart
// Switch to History tab
// Shows:
// - Campaign ID
// - Message preview
// - Status (Sent, Failed, Pending)
// - Statistics (Sent: 100, Failed: 2, Skipped: 1)

// Click campaign card for detailed results
```

---

## Security & Permissions

### Admin-Only Access

```dart
// Backend enforces:
// - Admin role required
// - Payment admin, executive admin, or HR admin

// Frontend checks:
// - User authentication token
// - API errors handled gracefully
// - Failed requests with error messages
```

### Data Protection

- Phone numbers not cached locally
- Sensitive data encrypted in transit (HTTPS)
- No plaintext storage of credentials
- Twilio handles SMS encryption

---

## Testing Checklist

- [x] SMS message character counter works correctly
- [x] SMS count calculator accurate (160/153 chars)
- [x] Phone number validation and normalization
- [x] User search and country filtering
- [x] Recipient selection and deselection
- [x] Campaign sending with success/failure handling
- [x] Campaign history display
- [x] Statistics card updates
- [x] Email subject and body validation
- [x] Error messages display properly
- [x] Loading indicators show during sending

---

## Future Enhancements

1. **Message Templates** - Pre-built templates for common messages
2. **Scheduling** - Schedule campaigns for future delivery
3. **A/B Testing** - Split testing for message variations
4. **Advanced Analytics** - Delivery reports and click tracking
5. **WhatsApp Integration** - Send WhatsApp messages via Twilio
6. **CSV Import** - Bulk recipient import from CSV files
7. **Recipient Segmentation** - Target by enrollment status, country, etc.
8. **Compliance** - GDPR/CCPA consent tracking and opt-out management
9. **Response Handling** - Track replies and SMS responses
10. **API Webhooks** - Real-time delivery status webhooks

---

## File Structure

```
frontend/lib/src/
├── data/models/
│   └── messaging.dart                    # SMS/Email models
├── core/api/
│   └── api_client.dart                   # Messaging API methods (added)
└── presentation/pages/admin/
    └── payment_admin_page.dart           # Messaging UI implementation
```

---

## Dependencies

- `flutter` - UI framework
- `dio` - HTTP client
- `intl` - Date formatting
- `material` design components

No additional packages required beyond existing dependencies.

---

## Backend Reference

### Files (Backend)

- `backend/apps/payments/views/bulk_sms_views.py` - SMS API endpoints
- `backend/apps/payments/services/sms_service.py` - Twilio integration
- `backend/apps/notifications/services.py` - Email service
- `backend/apps/notifications/tasks.py` - Celery tasks for async sending

### Endpoints

- `POST /api/v1/payments/admin/bulk-sms/send/` - Send SMS
- `GET /api/v1/payments/admin/bulk-sms/users/` - Get users with phone
- `GET /api/v1/communications/logs/` - Communication history
- `GET /api/v1/communications/stats/` - Stats dashboard

---

## Support & Maintenance

For issues or questions about the messaging system:

1. Check backend logs for API errors
2. Verify Twilio credentials in Django settings
3. Confirm user has admin role
4. Check phone number format (must include country code)
5. Verify recipient count doesn't exceed 500

---

**Implementation Date:** April 17, 2026  
**Status:** Production Ready ✅  
**Last Updated:** April 17, 2026
