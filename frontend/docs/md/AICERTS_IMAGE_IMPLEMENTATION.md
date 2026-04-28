# AICERTS Image Rendering Implementation

## Overview

This implementation provides a complete solution for rendering AICERTS course images in the HOSI Academy frontend. It solves CORS issues by proxying images through the backend and provides specialized widgets for different image types.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (Flutter)                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────┐    ┌──────────────────────────────┐  │
│  │ AICERTS Service  │───▶│ AICERTS Image Service        │  │
│  │ (fetches courses)│    │ (proxies URLs)               │  │
│  └──────────────────┘    └──────────────────────────────┘  │
│                                │                             │
│                                ▼                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              AICERTS Image Widgets                    │  │
│  │  - AICERTSImageWidget (base)                         │  │
│  │  - AICERTSCourseCardImage (card with badge)          │  │
│  │  - AICERTSCertificateBadge (SVG badge)               │  │
│  │  - AICERTSAIToolLogo (tool logos)                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                │                             │
└────────────────────────────────┼─────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                   Backend (Django)                           │
│                                                              │
│  /api/v1/courses/masterclasses/proxy/image/?url={encoded}   │
│                                │                             │
│                                ▼                             │
│                    Fetches from AICERTS CDN                  │
│                    Adds CORS headers                         │
│                    Returns to frontend                       │
└─────────────────────────────────────────────────────────────┘
                                 ▲
                                 │
                    ┌────────────┴───────────┐
                    │   AICERTS CDN          │
                    │   www.aicerts.ai       │
                    │   cdn.aicerts.ai       │
                    └────────────────────────┘
```

## Files Created

### 1. Core Service
**File**: `frontend/lib/src/core/services/aicerts_image_service.dart`

Handles URL processing and proxying:
- Converts AICERTS URLs to backend proxy URLs
- Detects image formats (SVG, PNG, JPEG, etc.)
- Provides placeholder paths
- Handles relative vs absolute URLs

**Key Methods**:
```dart
// Proxy any AICERTS image URL
AICERTSImageService.proxyImageUrl(url);

// Get feature image (course thumbnail)
AICERTSImageService.getFeatureImageUrl(url);

// Get certificate badge (SVG support)
AICERTSImageService.getCertificateBadgeUrl(url);

// Get AI tool logo
AICERTSImageService.getToolImageUrl(url);
```

### 2. Image Widgets
**File**: `frontend/lib/src/presentation/widgets/aicerts/aicerts_image_widget.dart`

Specialized Flutter widgets for rendering images:

#### AICERTSImageWidget (Base Widget)
```dart
AICERTSImageWidget(
  imageUrl: course.featureImageUrl,
  imageType: AICERTSImageType.course,
  width: 300,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

Features:
- Automatic proxy URL conversion
- SVG support via `flutter_svg`
- Loading indicators with progress
- Error states with fallback icons
- Custom placeholders
- Rounded corners and borders

#### AICERTSCourseCardImage
```dart
AICERTSCourseCardImage(
  featureImageUrl: course.featureImageUrl,
  certificateBadgeUrl: course.certificateBadgeUrl,
  width: 340,
  height: 200,
  showBadge: true,
)
```

Features:
- Main feature image
- Certificate badge overlay (top-right corner)
- Badge has white background and shadow

#### AICERTSCertificateBadge
```dart
AICERTSCertificateBadge(
  badgeUrl: course.certificateBadgeUrl,
  size: 64,
  showTooltip: true,
)
```

Features:
- Optimized for SVG badges
- Tooltip on hover
- Proper aspect ratio

#### AICERTSAIToolLogo
```dart
AICERTSAIToolLogo(
  toolImageUrl: tool.toolImage,
  size: 40,
  toolName: 'TensorFlow',
)
```

Features:
- Small logo display
- Tooltip with tool name

### 3. Course Detail Page
**File**: `frontend/lib/src/presentation/pages/aicerts/aicerts_course_detail_page.dart`

Full course detail page with:
- Hero image section with certificate badge
- Course information sections
- AI tools showcase
- Certificate preview
- Pricing display
- Enrollment CTA
- Bottom action bar

### 4. Updated Service
**File**: `frontend/lib/src/core/services/aicerts_service.dart`

Updated to use `AICERTSImageService`:
- Removed duplicate proxy logic
- Centralized image handling
- Cleaner code

### 5. Widget Exports
**File**: `frontend/lib/src/presentation/widgets/aicerts/widgets.dart`

Central export for easy imports.

## Usage Examples

### Example 1: Display Course Image in List
```dart
import 'package:lms_app/src/presentation/widgets/aicerts/widgets.dart';

ListView.builder(
  itemCount: courses.length,
  itemBuilder: (context, index) {
    final course = courses[index];
    return AICERTSImageWidget(
      imageUrl: course.featureImageUrl,
      imageType: AICERTSImageType.course,
      width: double.infinity,
      height: 180,
    );
  },
);
```

### Example 2: Course Card with Certificate Badge
```dart
Card(
  child: Column(
    children: [
      AICERTSCourseCardImage(
        featureImageUrl: course.featureImageUrl,
        certificateBadgeUrl: course.certificateBadgeUrl,
        width: double.infinity,
        height: 200,
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(course.title),
      ),
    ],
  ),
);
```

### Example 3: Navigate to Course Detail
```dart
import 'package:lms_app/src/presentation/pages/aicerts/aicerts_course_detail_page.dart';

GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AICERTSCourseDetailPage(
          course: course,
        ),
      ),
    );
  },
  child: CourseCard(course: course),
);
```

### Example 4: Display AI Tool Logos
```dart
Row(
  children: course.aiTools.map((tool) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AICERTSAIToolLogo(
        toolImageUrl: tool.toolImage,
        toolName: tool.name,
        size: 48,
      ),
    );
  }).toList(),
);
```

## Backend Proxy Endpoint

**URL**: `/api/v1/courses/masterclasses/proxy/image/`

**Query Parameters**:
- `url` (required): Encoded AICERTS image URL
- `format` (optional): Force format (e.g., `svg`)

**Example Request**:
```
GET /api/v1/courses/masterclasses/proxy/image/?url=https%3A%2F%2Fwww.aicerts.ai%2Fbadges%2Fai-foundations.png
```

**Response Headers**:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, OPTIONS
Cache-Control: public, max-age=86400
Content-Type: image/png (or image/svg+xml for SVGs)
```

## Image Types and Formats

| Type | Format | Use Case | Widget |
|------|--------|----------|--------|
| Course Feature | PNG/JPEG | Course card thumbnail | `AICERTSImageWidget` |
| Certificate Badge | SVG | Certification indicator | `AICERTSCertificateBadge` |
| AI Tool Logo | PNG/SVG | Tool showcase | `AICERTSAIToolLogo` |
| Thumbnail | Any | Small previews | `AICERTSImageWidget` |

## Error Handling

The widgets handle errors gracefully:

1. **Loading State**: Shows progress indicator
2. **Error State**: Shows broken image icon with fallback text
3. **Null URL**: Shows placeholder icon based on type

## Performance Optimizations

1. **Backend Caching**: Images cached for 24 hours
2. **Frontend Caching**: `cached_network_image` handles disk caching
3. **SVG Support**: Native SVG rendering for crisp badges
4. **Lazy Loading**: Images load only when visible

## Security

1. **Domain Validation**: Only allows `aicerts.ai` domains
2. **URL Encoding**: All URLs properly encoded
3. **No Direct CDN Access**: All requests go through backend proxy

## Testing Checklist

- [ ] Course images load correctly
- [ ] Certificate badges display as SVG
- [ ] Error states show appropriate fallbacks
- [ ] Loading indicators work
- [ ] Mobile responsive layout
- [ ] Web platform compatibility (CORS bypassed)
- [ ] Dark mode support
- [ ] Certificate badge overlay positioning

## Future Enhancements

1. **Image Optimization**: Add resize parameters to proxy
2. **Lazy Loading**: Implement intersection observer for lists
3. **Progressive Loading**: BlurHash or low-res placeholders
4. **Image Gallery**: Multiple images per course
5. **Zoom/Pan**: Interactive image viewing

## Troubleshooting

### Images Not Loading

1. Check backend proxy endpoint is running
2. Verify AICERTS CDN is accessible from backend
3. Check logs for CORS errors
4. Ensure URL encoding is correct

### SVG Not Rendering

1. Ensure `forceSvg: true` for badge widgets
2. Check backend adds `format=svg` parameter
3. Verify SVG is valid XML

### Performance Issues

1. Enable backend caching headers
2. Check image sizes (should be optimized)
3. Use pagination for large course lists

## Related Documentation

- [AICERTS Partner API Documentation](/docs/AICERTS_PARTNER_API_DOCUMENTATION.md)
- [Backend Proxy View](/backend/apps/masterclasses/views.py)
- [Flutter SVG Package](https://pub.dev/packages/flutter_svg)
