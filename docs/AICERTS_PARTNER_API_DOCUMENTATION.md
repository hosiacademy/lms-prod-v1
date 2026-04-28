# AICERTs LMS-to-LMS Partner API Documentation

**Version:** 2.0
**Date:** 2026-02-20
**Audience:** Partner LMS Integration Teams
**© AICERTs 2025–2026. All Rights Reserved.**

---

## Table of Contents

1. [Introduction](#introduction)
2. [Environments & Base URLs](#environments--base-urls)
3. [Authentication & Security](#authentication--security)
4. [Signature Generation](#signature-generation)
5. [API Endpoints](#api-endpoints)
   - [1. Create User](#1-create-user)
   - [2. Course Enrollment](#2-course-enrollment)
   - [3. Authenticate User (SSO)](#3-authenticate-user-sso)
   - [4. List All Courses](#4-list-all-courses)
   - [5. Get Course by ID](#5-get-course-by-id)
   - [6. Access Course Assets](#6-access-course-assets)
6. [Complete Integration Flow](#complete-integration-flow)
7. [Error Reference](#error-reference)
8. [Code Examples](#code-examples)
9. [Contact & Support](#contact--support)
10. [Version History](#version-history)

---

## Introduction

This document describes the full AICERTs Partner LMS integration API. As a partner LMS, you have access to two API surfaces:

| Surface | Purpose | Base URL |
|---|---|---|
| **LMS SSO API** | User management, enrollment, authentication | `https://learn.aicerts.io/webservice/rest/server.php` |
| **Course Data API** | Course catalog, metadata, assets | `https://www.aicerts.ai/wp-json/aicerts-api/v1` |

The integration flow for a typical user session is:

```
Partner LMS
    │
    ├─ 1. Create User ──────────────► AICERTs LMS (POST core_user_create_users)
    │                                       ↓ returns aicerts_user_id
    ├─ 2. Enroll in Course ─────────► AICERTs LMS (POST enrol_manual_enrol_users)
    │                                       ↓ returns enrollment confirmation
    └─ 3. SSO Redirect ─────────────► AICERTs LMS (GET authenticate_user)
                                            ↓ auto-logs user in, redirects to course
```

---

## Environments & Base URLs

### LMS SSO API (User, Enrollment, Authentication)

| Environment | Base URL |
|---|---|
| Production | `https://learn.aicerts.io/webservice/rest/server.php` |

### Course Data API (Catalog & Assets)

| Environment | Base URL |
|---|---|
| Production | `https://www.aicerts.ai/wp-json/aicerts-api/v1` |
| Swagger UI | `https://www.aicerts.ai/api-swagger/` (username: `apiadmin`, password: `pass@123`) |

---

## Authentication & Security

All LMS SSO API calls (Create User, Enroll, Authenticate) require:

| Parameter | Description |
|---|---|
| `wstoken` | Your partner API token — provided by AICERTs during onboarding |
| `partner_id` | Your unique partner integer ID — provided by AICERTs |
| `timestamp` | Current Unix epoch time (integer seconds) |
| `signature` | HMAC-SHA256 signature — see [Signature Generation](#signature-generation) |

> **Important:** Signatures expire. Requests with a timestamp older than ±5 minutes from the server clock are rejected. Always generate a fresh timestamp at call time.

The Course Data API (`www.aicerts.ai`) does **not** require authentication at this stage.

---

## Signature Generation

The HMAC-SHA256 signature is computed as:

```
data      = "<identifier>:<timestamp>"
signature = HMAC-SHA256(data, secret_key)
```

Where:
- `identifier` is the **user's email** for user-creation and auth calls, or the **user's email / AICERTs user ID** for enrollment calls
- `timestamp` is the same integer epoch value sent in the request
- `secret_key` is your partner secret — provided by AICERTs during onboarding (never expose this in client-side code)

### PHP

```php
$secret    = 'your_secret_key';
$email     = 'user@example.com';
$timestamp = time();                              // e.g. 1753383259
$data      = $email . ':' . $timestamp;
$signature = hash_hmac('sha256', $data, $secret); // 64-char hex string
```

### Python

```python
import hmac, hashlib, time

secret    = 'your_secret_key'
email     = 'user@example.com'
timestamp = int(time.time())
data      = f"{email}:{timestamp}"
signature = hmac.new(secret.encode(), data.encode(), hashlib.sha256).hexdigest()
```

### Node.js

```javascript
const crypto = require('crypto');

const secret    = 'your_secret_key';
const email     = 'user@example.com';
const timestamp = Math.floor(Date.now() / 1000);
const data      = `${email}:${timestamp}`;
const signature = crypto.createHmac('sha256', secret).update(data).digest('hex');
```

---

## API Endpoints

### 1. Create User

Creates a new user account in the AICERTs LMS. Call this the **first time** a user from your platform accesses an AICERTs course. If the user already exists (same email), AICERTs returns the existing user record — it is safe to call this idempotently.

**Endpoint**
```
POST https://learn.aicerts.io/webservice/rest/server.php
```

**Query Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `wstoken` | string | Yes | Partner API token |
| `wsfunction` | string | Yes | Must be `core_user_create_users` |
| `moodlewsrestformat` | string | Yes | Must be `json` |
| `users[0][firstname]` | string | Yes | User's first name |
| `users[0][lastname]` | string | Yes | User's last name |
| `users[0][email]` | string | Yes | User's email address |
| `users[0][username]` | string | Yes | Username (typically same as email) |
| `users[0][partner_id]` | integer | Yes | Your partner ID |
| `users[0][source]` | string | Yes | Must be `sso` |
| `timestamp` | integer | Yes | Unix epoch timestamp |
| `signature` | string | Yes | HMAC-SHA256 signature (signed with user's email) |

**Signature input for this call:**
```
data = "<users[0][email]>:<timestamp>"
```

**Example Request**

```
POST https://learn.aicerts.io/webservice/rest/server.php
  ?wstoken={wstoken}
  &wsfunction=core_user_create_users
  &moodlewsrestformat=json
  &users[0][firstname]=Jane
  &users[0][lastname]=Doe
  &users[0][email]=jane.doe@partner.com
  &users[0][username]=jane.doe@partner.com
  &users[0][partner_id]={partner_id}
  &users[0][source]=sso
  &timestamp=1753383259
  &signature=a6c410e46a37cbc808b81031f8c95252e68c05c8d74bff4a4768b0507cb0a2bc
```

**Success Response (200)**

```json
[
  {
    "status": "success",
    "message": "User registered successfully",
    "id": 37429,
    "username": "jane.doe@partner.com"
  }
]
```

> **Important:** Save the returned `id` as the user's **AICERTs User ID**. You need it for the Enrollment call.

**Error Responses**

```json
[
  {
    "status": "error",
    "message": "Invalid Token"
  }
]
```

| Scenario | Message |
|---|---|
| Bad token | `Invalid Token` |
| Signature mismatch | `Authentication Failed` |
| Missing required field | `Missing Parameters` |

---

### 2. Course Enrollment

Enrolls a user in a specific AICERTs course. The user must already exist in AICERTs LMS (obtained from step 1). This endpoint is idempotent — if the user is already enrolled, `isUserAlreadyEnrolled` is returned as `"1"`.

**Endpoint**
```
POST https://learn.aicerts.io/webservice/rest/server.php
```

**Query Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `wstoken` | string | Yes | Partner API token |
| `wsfunction` | string | Yes | Must be `enrol_manual_enrol_users` |
| `moodlewsrestformat` | string | Yes | Must be `json` |
| `enrolments[0][roleid]` | integer | Yes | Role ID (`5` = student) |
| `enrolments[0][userid]` | integer | Yes | AICERTs User ID (from Create User response) |
| `enrolments[0][courseid]` | integer | Yes | AICERTs Course ID (from course catalog) |
| `enrolments[0][enrollmentsourcefrom]` | string | Yes | Your partner platform name (e.g. `hosi-academy`) |
| `enrolments[0][partner_id]` | integer | Yes | Your partner ID |
| `timestamp` | integer | Yes | Unix epoch timestamp |
| `signature` | string | Yes | HMAC-SHA256 signature |

**Signature input for this call:**
```
data = "<user_email>:<timestamp>"
```
(Use the user's email or their AICERTs user ID as identifier — email is preferred.)

**Example Request**

```
POST https://learn.aicerts.io/webservice/rest/server.php
  ?wstoken={wstoken}
  &wsfunction=enrol_manual_enrol_users
  &moodlewsrestformat=json
  &enrolments[0][roleid]=5
  &enrolments[0][userid]=37429
  &enrolments[0][courseid]=524
  &enrolments[0][enrollmentsourcefrom]=hosi-academy
  &enrolments[0][partner_id]={partner_id}
  &timestamp=1754411677
  &signature=feea2e91d2dfc06d894c26ad22168490b631b618f6f9a089524c47b3192c1463
```

**Success Response (200)**

```json
{
  "status": "success",
  "message": "User enrol successfully",
  "isUserAlreadyEnrolled": "0"
}
```

| `isUserAlreadyEnrolled` | Meaning |
|---|---|
| `"0"` | Newly enrolled |
| `"1"` | Was already enrolled (no change) |

**Error Responses**

| Scenario | Message |
|---|---|
| Invalid token | `Invalid Token` |
| User not found | `User Not Found` |
| Course not found | `Course Not Found` |
| Signature invalid | `Authentication Failed` |

---

### 3. Authenticate User (SSO)

Generates an SSO auto-login link that signs the user into the AICERTs LMS. Open this URL in the user's browser — AICERTs validates the signature and automatically logs the user in, optionally redirecting them directly to a course.

**Endpoint**
```
GET https://learn.aicerts.io/webservice/rest/server.php
```

> **Browser-only.** This endpoint is designed to be opened as a browser redirect, not called from server-to-server. The response is a full page redirect into the AICERTs LMS session.

**Query Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `wstoken` | string | Yes | Partner API token |
| `wsfunction` | string | Yes | Must be `local_myauthplugin_authenticate_user` |
| `moodlewsrestformat` | string | Yes | Must be `json` |
| `username` | string | Yes | User's email address |
| `partner_id` | integer | Yes | Your partner ID |
| `timestamp` | integer | Yes | Unix epoch timestamp |
| `signature` | string | Yes | HMAC-SHA256 signature |
| `courseid` | integer | No | If provided, redirects directly to this course after login |

**Signature input for this call:**
```
data = "<username>:<timestamp>"
```

**Example URL (for browser redirect)**

```
https://learn.aicerts.io/webservice/rest/server.php
  ?wstoken={wstoken}
  &wsfunction=local_myauthplugin_authenticate_user
  &moodlewsrestformat=json
  &username=jane.doe@partner.com
  &partner_id={partner_id}
  &timestamp=1754411216
  &signature=684bd3dcfbcb78c54d2e85830d8c36535b2eeebccfacbb8b509c90eccd6de5aa
  &courseid=524
```

**Behaviour**

- On success: browser is redirected to the AICERTs LMS dashboard (or directly to the course if `courseid` was supplied).
- On failure: returns a JSON error object (see below).

**Error Response (JSON)**

```json
{
  "status": "error",
  "message": "Authentication Failed"
}
```

| Scenario | Message |
|---|---|
| Expired timestamp | `Authentication Failed` |
| Signature mismatch | `Authentication Failed` |
| User not found | `User Not Found` |
| Invalid token | `Invalid Token` |

> **SSO URL expiry:** Generate the SSO URL immediately before redirecting the user. Do not cache or reuse SSO URLs — the embedded timestamp makes them single-use within the allowed clock window.

---

### 4. List All Courses

Returns a paginated, searchable list of all AICERTs courses. Use this to populate your partner LMS course catalog or to sync course data periodically.

**Endpoint**
```
GET https://www.aicerts.ai/wp-json/aicerts-api/v1/courses
```

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `page` | integer | No | `1` | Page number |
| `per_page` | integer | No | `10` | Results per page |
| `search` | string | No | — | Keyword filter (matches title/description) |

**Example Request**

```
GET https://www.aicerts.ai/wp-json/aicerts-api/v1/courses?page=1&per_page=20&search=AI
```

**Success Response (200)**

```json
{
  "success": true,
  "page": 1,
  "per_page": 20,
  "total": 48,
  "total_pages": 3,
  "data": [
    {
      "id": 101,
      "title": "AI Foundations",
      "certificate_badge_url": "https://cdn.aicerts.ai/badges/ai-foundations.png",
      "categories": ["Artificial Intelligence"],
      "description": "Learn the fundamentals of AI with hands-on modules."
    },
    {
      "id": 102,
      "title": "Certified AI Professional",
      "certificate_badge_url": "https://cdn.aicerts.ai/badges/ai-pro.png",
      "categories": ["AI Professional", "Enterprise AI"],
      "description": "Advanced certification for enterprise AI practitioners."
    }
  ]
}
```

**Response Fields**

| Field | Type | Description |
|---|---|---|
| `success` | boolean | `true` on success |
| `page` | integer | Current page returned |
| `per_page` | integer | Items per page |
| `total` | integer | Total number of courses available |
| `total_pages` | integer | Total number of pages |
| `data[].id` | integer | AICERTs Course ID — use for enrollment and detail calls |
| `data[].title` | string | Course title |
| `data[].certificate_badge_url` | string | URL to certificate badge image (PNG/SVG) |
| `data[].categories` | array | Category labels |
| `data[].description` | string | Short course description |

**Error Responses**

| HTTP Code | Meaning |
|---|---|
| `400` | Bad Request — invalid query parameters |
| `500` | Internal Server Error |

---

### 5. Get Course by ID

Returns full detail for a single course including modules, tools, prerequisites, exam format, and all asset URLs.

**Endpoint**
```
GET https://www.aicerts.ai/wp-json/aicerts-api/v1/course/{id}
```

**Path Parameters**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer | Yes | AICERTs Course ID |

**Example Request**

```
GET https://www.aicerts.ai/wp-json/aicerts-api/v1/course/101
```

**Success Response (200)**

```json
{
  "success": true,
  "data": {
    "id": 101,
    "title": "AI Foundations",
    "description": "An introductory course to AI covering ML, DL, and applied models.",
    "feature_image_url": "https://cdn.aicerts.ai/images/ai-foundations.png",
    "certificate_code": "AIC-101",
    "course_tagline": "Start your AI journey today!",
    "certificate_overview": {
      "included_items": "Modules, Exam, Certificate",
      "certificate_duration": "3 Months",
      "prerequisites": "None",
      "exam_format": "Multiple Choice Online Test"
    },
    "certification_modules": [
      {
        "certification_module_title": "Introduction to AI",
        "certification_module_description": "Basics of AI, ML, and DL."
      },
      {
        "certification_module_title": "Applied Machine Learning",
        "certification_module_description": "Supervised and unsupervised learning techniques."
      }
    ],
    "ai_tools": [
      {
        "name": "TensorFlow",
        "tool_image": "https://cdn.aicerts.ai/tools/tensorflow.png"
      },
      {
        "name": "scikit-learn",
        "tool_image": "https://cdn.aicerts.ai/tools/sklearn.png"
      }
    ]
  }
}
```

**Response Fields**

| Field | Type | Description |
|---|---|---|
| `data.id` | integer | AICERTs Course ID |
| `data.title` | string | Full course title |
| `data.description` | string | Full course description |
| `data.feature_image_url` | string | Hero/banner image URL |
| `data.certificate_code` | string | Certificate identifier (e.g. `AIC-101`) |
| `data.course_tagline` | string | Short marketing tagline |
| `data.certificate_overview.included_items` | string | What is included |
| `data.certificate_overview.certificate_duration` | string | Access/validity period |
| `data.certificate_overview.prerequisites` | string | Entry requirements |
| `data.certificate_overview.exam_format` | string | Exam type description |
| `data.certification_modules[]` | array | List of course modules |
| `data.certification_modules[].certification_module_title` | string | Module title |
| `data.certification_modules[].certification_module_description` | string | Module description |
| `data.ai_tools[]` | array | AI tools/technologies covered |
| `data.ai_tools[].name` | string | Tool name |
| `data.ai_tools[].tool_image` | string | Tool logo/image URL |

**Error Responses**

| HTTP Code | Meaning |
|---|---|
| `400` | Invalid Course ID |
| `404` | Course does not exist |
| `500` | Internal Server Error |

---

### 6. Access Course Assets

Course assets (badge images, feature images, tool logos) are served as public CDN URLs embedded in the course data responses. No additional authentication is required to fetch them.

**Asset types and where to find them:**

| Asset | API Field | Example URL |
|---|---|---|
| Certificate badge | `data[].certificate_badge_url` (list) | `https://cdn.aicerts.ai/badges/ai-foundations.png` |
| Course hero image | `data.feature_image_url` (detail) | `https://cdn.aicerts.ai/images/ai-foundations.png` |
| AI tool logo | `data.ai_tools[].tool_image` (detail) | `https://cdn.aicerts.ai/tools/tensorflow.png` |

**Usage notes:**

- All asset URLs are absolute and publicly accessible — no token or signature required.
- Cache CDN URLs locally (recommended TTL: 1 hour) to avoid hammering the course API on every page load.
- Badge/image URLs may change when courses are updated. Re-sync your course cache periodically (daily recommended).
- Use the `certificate_badge_url` for listing views and the `feature_image_url` for course detail/hero display.

**Recommended sync pattern:**

```
1. Call GET /courses?per_page=100 → paginate through all pages
2. For each course, call GET /course/{id} to fetch full detail + all asset URLs
3. Store locally: id, title, description, certificate_badge_url, feature_image_url, ai_tools
4. Repeat daily (or on-demand via webhook when AICERTs notifies you of changes)
```

---

## Complete Integration Flow

This section shows the end-to-end sequence for a partner LMS enabling a user to access an AICERTs course for the first time.

```
┌─────────────┐                    ┌──────────────────────┐     ┌────────────────────────────┐
│ Partner LMS │                    │  AICERTs LMS SSO API │     │  AICERTs Course Data API   │
│             │                    │  learn.aicerts.io    │     │  www.aicerts.ai            │
└──────┬──────┘                    └──────────┬───────────┘     └─────────────┬──────────────┘
       │                                      │                               │
       │──── Sync course catalog ─────────────┼──────────────────────────────►│
       │     GET /courses + GET /course/{id}  │                               │
       │◄─── Returns course list + assets ────┼───────────────────────────────│
       │                                      │                               │
       │  [User selects an AICERTs course]    │                               │
       │                                      │                               │
       │──── POST core_user_create_users ─────►│                               │
       │     (email, name, partner_id, sig)   │                               │
       │◄─── { "id": 37429, "status": "success" }                             │
       │     [Store aicerts_user_id = 37429]  │                               │
       │                                      │                               │
       │──── POST enrol_manual_enrol_users ───►│                               │
       │     (userid=37429, courseid=524, sig) │                               │
       │◄─── { "status": "success", "isUserAlreadyEnrolled": "0" }            │
       │                                      │                               │
       │  [User clicks "Open Course"]         │                               │
       │                                      │                               │
       │──── Generate SSO URL (server-side) ──┤                               │
       │     timestamp + signature            │                               │
       │                                      │                               │
       │──── 302 Redirect browser to SSO URL ─►│                               │
       │     GET authenticate_user            │                               │
       │     (username, courseid, sig)        │                               │
       │                                 [AICERTs validates, auto-logs in]    │
       │◄──────────── User lands on AICERTs course page ─────────────────────-│
```

---

## Error Reference

### LMS SSO API Errors

| Error Message | Cause | Resolution |
|---|---|---|
| `Invalid Token` | `wstoken` is incorrect or revoked | Verify your `wstoken` with AICERTs support |
| `Missing Parameters` | A required parameter was omitted | Check all required fields are present |
| `Authentication Failed` | Signature is invalid, or timestamp is expired (>5 min drift) | Regenerate timestamp and signature fresh at call time |
| `User Not Found` | No user matches the provided email/username | Run Create User first |
| `Course Not Found` | Course ID does not exist in AICERTs | Verify course ID from the Course Data API |

### Course Data API Errors

| HTTP Code | Error | Resolution |
|---|---|---|
| `200` | — | Success |
| `400` | Bad Request | Check query parameter types and values |
| `404` | Not Found | Course ID does not exist |
| `500` | Internal Server Error | Retry after brief delay; contact support if persistent |

---

## Code Examples

### Full PHP Integration

```php
<?php

define('AICERTS_BASE_URL', 'https://learn.aicerts.io/webservice/rest/server.php');
define('AICERTS_WSTOKEN',  'your_wstoken');
define('AICERTS_SECRET',   'your_secret_key');
define('AICERTS_PARTNER',  12345);

/**
 * Generate HMAC timestamp + signature.
 */
function aicerts_sign(string $identifier): array {
    $timestamp = time();
    $data      = $identifier . ':' . $timestamp;
    $signature = hash_hmac('sha256', $data, AICERTS_SECRET);
    return [$timestamp, $signature];
}

/**
 * Step 1: Create user in AICERTs LMS.
 * Returns the AICERTs user ID on success.
 */
function aicerts_create_user(string $email, string $first, string $last): int {
    [$ts, $sig] = aicerts_sign($email);

    $params = http_build_query([
        'wstoken'              => AICERTS_WSTOKEN,
        'wsfunction'           => 'core_user_create_users',
        'moodlewsrestformat'   => 'json',
        'users[0][firstname]'  => $first,
        'users[0][lastname]'   => $last,
        'users[0][email]'      => $email,
        'users[0][username]'   => $email,
        'users[0][partner_id]' => AICERTS_PARTNER,
        'users[0][source]'     => 'sso',
        'timestamp'            => $ts,
        'signature'            => $sig,
    ]);

    $resp = json_decode(file_get_contents(AICERTS_BASE_URL . '?' . $params), true);
    $user = $resp[0] ?? [];

    if (($user['status'] ?? '') !== 'success') {
        throw new RuntimeException('AICERTs create user failed: ' . ($user['message'] ?? 'unknown'));
    }

    return (int) $user['id'];
}

/**
 * Step 2: Enroll user in an AICERTs course.
 */
function aicerts_enroll(int $aicerts_user_id, int $course_id, string $email): bool {
    [$ts, $sig] = aicerts_sign($email);

    $params = http_build_query([
        'wstoken'                              => AICERTS_WSTOKEN,
        'wsfunction'                           => 'enrol_manual_enrol_users',
        'moodlewsrestformat'                   => 'json',
        'enrolments[0][roleid]'                => 5,
        'enrolments[0][userid]'                => $aicerts_user_id,
        'enrolments[0][courseid]'              => $course_id,
        'enrolments[0][enrollmentsourcefrom]'  => 'hosi-academy',
        'enrolments[0][partner_id]'            => AICERTS_PARTNER,
        'timestamp'                            => $ts,
        'signature'                            => $sig,
    ]);

    $resp = json_decode(file_get_contents(AICERTS_BASE_URL . '?' . $params), true);
    return ($resp['status'] ?? '') === 'success';
}

/**
 * Step 3: Generate SSO URL for browser redirect.
 * Open this URL directly in the user's browser.
 */
function aicerts_sso_url(string $email, int $course_id = null): string {
    [$ts, $sig] = aicerts_sign($email);

    $params = [
        'wstoken'            => AICERTS_WSTOKEN,
        'wsfunction'         => 'local_myauthplugin_authenticate_user',
        'moodlewsrestformat' => 'json',
        'username'           => $email,
        'partner_id'         => AICERTS_PARTNER,
        'timestamp'          => $ts,
        'signature'          => $sig,
    ];

    if ($course_id) {
        $params['courseid'] = $course_id;
    }

    return AICERTS_BASE_URL . '?' . http_build_query($params);
}

// --- Usage ---
$aicerts_id = aicerts_create_user('jane.doe@partner.com', 'Jane', 'Doe');
aicerts_enroll($aicerts_id, 524, 'jane.doe@partner.com');
$sso_url = aicerts_sso_url('jane.doe@partner.com', 524);

// Redirect the user's browser to $sso_url
header('Location: ' . $sso_url);
exit;
```

### Full Python Integration

```python
import hmac
import hashlib
import time
import requests

AICERTS_BASE_URL = 'https://learn.aicerts.io/webservice/rest/server.php'
AICERTS_WSTOKEN  = 'your_wstoken'
AICERTS_SECRET   = 'your_secret_key'
AICERTS_PARTNER  = 12345


def aicerts_sign(identifier: str) -> tuple[int, str]:
    """Generate timestamp + HMAC signature."""
    timestamp = int(time.time())
    data      = f"{identifier}:{timestamp}"
    signature = hmac.new(AICERTS_SECRET.encode(), data.encode(), hashlib.sha256).hexdigest()
    return timestamp, signature


def aicerts_create_user(email: str, first_name: str, last_name: str) -> int:
    """Create user in AICERTs LMS. Returns AICERTs user ID."""
    ts, sig = aicerts_sign(email)

    params = {
        'wstoken':              AICERTS_WSTOKEN,
        'wsfunction':           'core_user_create_users',
        'moodlewsrestformat':   'json',
        'users[0][firstname]':  first_name,
        'users[0][lastname]':   last_name,
        'users[0][email]':      email,
        'users[0][username]':   email,
        'users[0][partner_id]': AICERTS_PARTNER,
        'users[0][source]':     'sso',
        'timestamp':            ts,
        'signature':            sig,
    }

    resp = requests.post(AICERTS_BASE_URL, params=params, timeout=15)
    resp.raise_for_status()
    result = resp.json()

    user = result[0] if isinstance(result, list) else result
    if user.get('status') != 'success':
        raise ValueError(f"Create user failed: {user.get('message')}")

    return int(user['id'])


def aicerts_enroll(aicerts_user_id: int, course_id: int, email: str) -> dict:
    """Enroll user in AICERTs course."""
    ts, sig = aicerts_sign(email)

    params = {
        'wstoken':                             AICERTS_WSTOKEN,
        'wsfunction':                          'enrol_manual_enrol_users',
        'moodlewsrestformat':                  'json',
        'enrolments[0][roleid]':               5,
        'enrolments[0][userid]':               aicerts_user_id,
        'enrolments[0][courseid]':             course_id,
        'enrolments[0][enrollmentsourcefrom]': 'hosi-academy',
        'enrolments[0][partner_id]':           AICERTS_PARTNER,
        'timestamp':                           ts,
        'signature':                           sig,
    }

    resp = requests.post(AICERTS_BASE_URL, params=params, timeout=15)
    resp.raise_for_status()
    return resp.json()


def aicerts_sso_url(email: str, course_id: int = None) -> str:
    """Generate SSO auto-login URL (open in user's browser)."""
    ts, sig = aicerts_sign(email)

    params = {
        'wstoken':            AICERTS_WSTOKEN,
        'wsfunction':         'local_myauthplugin_authenticate_user',
        'moodlewsrestformat': 'json',
        'username':           email,
        'partner_id':         AICERTS_PARTNER,
        'timestamp':          ts,
        'signature':          sig,
    }
    if course_id:
        params['courseid'] = course_id

    return AICERTS_BASE_URL + '?' + '&'.join(f"{k}={v}" for k, v in params.items())


def get_aicerts_courses(page: int = 1, per_page: int = 100, search: str = None) -> dict:
    """Fetch course catalog from AICERTs Course Data API."""
    base = 'https://www.aicerts.ai/wp-json/aicerts-api/v1/courses'
    params = {'page': page, 'per_page': per_page}
    if search:
        params['search'] = search

    resp = requests.get(base, params=params, timeout=15)
    resp.raise_for_status()
    return resp.json()


def get_aicerts_course(course_id: int) -> dict:
    """Fetch full course detail including assets."""
    url  = f'https://www.aicerts.ai/wp-json/aicerts-api/v1/course/{course_id}'
    resp = requests.get(url, timeout=15)
    resp.raise_for_status()
    return resp.json().get('data', {})


# --- Usage ---
aicerts_id = aicerts_create_user('jane.doe@partner.com', 'Jane', 'Doe')
aicerts_enroll(aicerts_id, 524, 'jane.doe@partner.com')
sso_url = aicerts_sso_url('jane.doe@partner.com', 524)
print(f"Redirect user to: {sso_url}")
```

---

## Contact & Support

For integration queries, API credentials, or issues:

**Support Team:** support@aicerts.io

Please include in your email:
- Your `partner_id`
- The endpoint you are calling
- The full request URL (redact your `wstoken` and `signature`)
- The response body received
- Screenshots where applicable

---

## Version History

| Date | Version | Author | Changes |
|---|---|---|---|
| 2025-08-14 | 1.0 | Anjali Thakkar | Initial release — Create User, Enroll, Authenticate |
| 2025-09-09 | 1.1 | Anjali Thakkar | Added Course Data API (List Courses, Get Course by ID) |
| 2026-02-20 | 2.0 | Integration Team | Combined v1.0 + v1.1; added Assets Access section, complete integration flow, multi-language code examples, full error reference |
