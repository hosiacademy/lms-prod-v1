# AICERTS Images - Display Locations

## Summary

AICERTS course images are now rendered using the new `AICERTSImageWidget` system which proxies images through the backend to bypass CORS restrictions.

## Where Images Are Displayed

### 1. Onboarding Page - AICERTS Courses Section (Marquee)
**File**: `frontend/lib/src/presentation/pages/onboarding/widgets/sections/aicerts_courses.dart`

**Widget**: `AICERTSCoursesSection`

**Description**: Scrolling marquee display showing all AICERTS courses in two rows (right-to-left and left-to-right)

**Image Component**: `AICERTSCourseCardImage`
- Shows feature image with certificate badge overlay
- Size: 340x200
- Certificate badge shown in top-right corner

**Location in App**: 
- Onboarding/welcome page
- Shows featured AICERTS courses

---

### 2. Course Cards - Enhanced Course Card
**File**: `frontend/lib/src/presentation/widgets/cards/enhanced_course_card.dart`

**Widget**: `EnhancedCourseCard`

**Description**: Standard course card used throughout the app

**Image Component**: `AICERTSImageWidget`
- Aspect ratio: 16:9 (responsive height 150-200px)
- Includes wishlist button overlay
- Includes price badge overlay

**Location in App**:
- Course listing pages
- Search results
- Category pages

---

### 3. Custom Selection Page
**File**: `frontend/lib/src/presentation/pages/custom_selection/custom_selection_page.dart`

**Widget**: `_CourseCard` (internal)

**Description**: Course cards in the custom selection/catalog page

**Image Component**: `AICERTSImageWidget`
- Height: 208px
- Full width
- Contain fit

**Location in App**:
- Custom course selection page
- Industry-based training catalog

---

### 4. AICERTS Course Detail Page
**File**: `frontend/lib/src/presentation/pages/aicerts/aicerts_course_detail_page.dart`

**Widget**: `AICERTSCourseDetailPage`

**Description**: Full course detail page with comprehensive information

**Image Components**:
- `AICERTSCourseCardImage` - Hero image (280px height)
- `AICERTSCertificateBadge` - Certificate preview in details section
- `AICERTSAIToolLogo` - AI tool logos (if available)

**Location in App**:
- When viewing individual AICERTS course details
- Accessed from course cards

---

### 5. Other Locations (Using Course Model)

The following widgets/panels also display course images (via `course.featureImageUrl`):

| File | Widget/Panel | Usage |
|------|-------------|-------|
| `enhanced_enrollment_panel.dart` | `EnhancedEnrollmentPanel` | Enrollment form course preview |
| `wishlist_panel.dart` | `WishlistPanel` | Wishlisted courses list |
| `course_details_panel.dart` | `CourseDetailsPanel` | Course detail sidebar |
| `offerings_browser_panel.dart` | `OfferingsBrowserPanel` | Course offerings browser |
| `bulk_enrollment_panel.dart` | `BulkEnrollmentPanel` | Bulk enrollment course list |
| `cart_panel.dart` | `CartPanel` | Shopping cart items |
| `masterclass_data_provider.dart` | Various | Masterclass data display |

---

## Image Flow

```
AICERTS CDN (www.aicerts.ai)
         │
         ▼
Backend Proxy (/api/v1/courses/masterclasses/proxy/image/)
         │  - Adds CORS headers
         │  - Caches for 24 hours
         │  - Validates domain
         ▼
AICERTSImageService (Dart)
         │  - Converts URLs to proxy URLs
         │  - Detects image format
         │  - Handles SVG specially
         ▼
AICERTSImageWidget (Flutter)
         │  - Renders image
         │  - Shows loading state
         │  - Handles errors gracefully
         ▼
User's Screen
```

---

## Image Types Displayed

| Type | Source Field | Widget | Format |
|------|-------------|--------|--------|
| Course Feature Image | `course.featureImageUrl` | `AICERTSImageWidget` | PNG/JPEG |
| Certificate Badge | `course.certificateBadgeUrl` | `AICERTSCertificateBadge` | SVG |
| AI Tool Logo | `tool.toolImage` | `AICERTSAIToolLogo` | PNG/SVG |
| Bundle Image | `bundle.image_url` | `AICERTSImageWidget` | PNG/JPEG |

---

## Key Features

### 1. CORS Bypass
All images route through Django backend proxy:
```
https://hosi.africa/api/v1/courses/masterclasses/proxy/image/?url={encoded_aicerts_url}
```

### 2. SVG Support
Certificate badges render as SVG for crisp display:
```dart
AICERTSCertificateBadge(
  badgeUrl: course.certificateBadgeUrl,
  size: 64,
)
```

### 3. Certificate Badge Overlay
Course cards show badge in top-right corner:
```dart
AICERTSCourseCardImage(
  featureImageUrl: course.featureImageUrl,
  certificateBadgeUrl: course.certificateBadgeUrl,
  showBadge: true,
)
```

### 4. Responsive Sizing
Images adapt to screen size:
```dart
height: (MediaQuery.of(context).size.width * 9 / 16).clamp(150, 200)
```

### 5. Error Handling
Graceful fallbacks for failed images:
- Loading indicator
- Broken image icon
- Placeholder icon based on type

---

## Testing Locations

To see AICERTS images in action:

1. **Onboarding Page** (Primary Display)
   - Run app
   - Navigate to home/onboarding
   - Scroll to "Featured AICERTS Courses" section
   - See scrolling marquee with course cards

2. **Custom Selection Page**
   - Navigate to custom selection/catalog
   - View course cards with images

3. **Course Detail**
   - Tap any AICERTS course card
   - See full detail page with hero image

4. **Cart/Wishlist**
   - Add course to cart/wishlist
   - Open cart/wishlist panel
   - See course thumbnails

---

## Files Modified

| File | Change |
|------|--------|
| `aicerts_courses.dart` | Replaced `SafeNetworkImage` with `AICERTSCourseCardImage` |
| `enhanced_course_card.dart` | Replaced `SafeNetworkImage` with `AICERTSImageWidget` |
| `custom_selection_page.dart` | Replaced `SafeNetworkImage` with `AICERTSImageWidget` |
| `aicerts_service.dart` | Uses `AICERTSImageService` for URL proxying |

---

## Files Created

| File | Purpose |
|------|---------|
| `aicerts_image_service.dart` | URL proxying service |
| `aicerts_image_widget.dart` | Image rendering widgets |
| `aicerts_course_detail_page.dart` | Course detail page |
| `widgets.dart` | Widget exports |

---

## Troubleshooting

### Images Not Showing

1. **Check Backend**: Ensure proxy endpoint is running
   ```bash
   curl "http://localhost:8000/api/v1/courses/masterclasses/proxy/image/?url=https://www.aicerts.ai/badges/test.png"
   ```

2. **Check Logs**: Look for CORS or network errors in console

3. **Check URLs**: Verify `course.featureImageUrl` contains valid AICERTS URLs

### SVG Badges Not Rendering

1. Ensure `forceSvg: true` or use `AICERTSCertificateBadge` widget
2. Check backend adds `&format=svg` parameter
3. Verify SVG is valid XML format

### Performance Issues

1. Images are cached by backend for 24 hours
2. Frontend uses standard image caching
3. Consider lazy loading for long lists

---

## Related Documentation

- [AICERTS Image Implementation](/frontend/AICERTS_IMAGE_IMPLEMENTATION.md)
- [AICERTS Partner API](/docs/AICERTS_PARTNER_API_DOCUMENTATION.md)
- [Backend Proxy View](/backend/apps/masterclasses/views.py)
