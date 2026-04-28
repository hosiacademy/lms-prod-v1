# AICERTS Enrollment Cart Functionality Implementation

## Summary

This document summarizes the implementation of cart functionality for AICERTS courses enrollment on the onboarding page and industry-specific training pathways.

## Requirements Addressed

### 1. ✅ Separate Name and Surname Fields
**Status:** Already implemented in `AicertsLearnerFormData`

The AICERTS enrollment form already has separate fields for first name and last name:
- `firstNameController` - captures the learner's first name
- `lastNameController` - captures the learner's last name

These fields are part of the `AicertsLearnerFormData` class located at:
```
frontend/lib/src/presentation/widgets/modals/aicerts/shared/aicerts_form_data.dart
```

When the form is submitted, these are combined into:
```dart
'first_name': firstNameController.text.trim(),
'last_name': lastNameController.text.trim(),
'full_name': '${firstNameController.text.trim()} ${lastNameController.text.trim()}',
```

### 2. ✅ Price Persistence
**Status:** Already implemented

The course price is persisted from the API and displayed consistently:
- Uses `course.price` from the backend API (reads `price_usd` field)
- Falls back to `course.localPrice` for localized pricing
- Default fallback: `250.0` USD if no price is available

Code reference in enrollment handlers:
```dart
Text(
  course.localPrice ??
      CurrencyService.instance.formatUSDAmount(course.price ?? 250),
  style: const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 24,
    color: Color(0xFF2E7D32),
  ),
)
```

### 3. ✅ Cart Functionality for AICERTS Courses Section
**Status:** Implemented

**File Modified:** `frontend/lib/src/presentation/pages/onboarding/widgets/sections/aicerts_courses.dart`

**Changes:**
1. Changed "Enroll Now" button to "Add to Cart" on course cards
2. Added enrollment options dialog with two choices:
   - **Add to Cart** - adds course to shopping cart
   - **Enroll Now** - direct enrollment via form
3. Added cart service integration to check if course is already in cart
4. Added snackbar notifications for:
   - Successfully added to cart
   - Already in cart warning
   - Error messages

**New Methods:**
- `_showEnrollmentDialog()` - shows enrollment options
- `_showDirectEnrollmentForm()` - shows direct enrollment form
- `_showAddedToCartSnackbar()` - success notification
- `_showAlreadyInCartSnackbar()` - warning notification
- `_showErrorSnackbar()` - error notification

### 4. ✅ Cart Functionality for Industry Training Pathway
**Status:** Implemented

**File Modified:** `frontend/lib/src/presentation/pages/industry_training/industry_training_enrollment_page.dart`

**Changes:**
1. Changed "Enroll" button to "Add to Cart" on course cards
2. Added enrollment options dialog (same as AICERTS courses section)
3. Added cart service integration
4. Added snackbar notifications

**New Methods:**
- `_showEnrollmentOptionsDialog()` - shows enrollment options
- `_showDirectEnrollmentForm()` - shows multi-step industry training modal
- `_showAddedToCartSnackbar()` - success notification
- `_showAlreadyInCartSnackbar()` - warning notification
- `_showErrorSnackbar()` - error notification

## Cart Service Integration

Both pathways now use the `CartService` singleton for cart operations:

```dart
// Check if course is in cart
if (cartService.hasCourse(course.id)) {
  _showAlreadyInCartSnackbar(context, course);
  return;
}

// Add course to cart
final success = await cartService.addCourse(course);
if (success) {
  _showAddedToCartSnackbar(context, course);
}
```

The cart service:
- Syncs with backend when user is authenticated
- Stores locally for guest users
- Handles both regular courses and AICERTS courses
- Provides stream updates for cart count

## User Flow

### AICERTS Courses Section (Onboarding Page)

1. User clicks "Add to Cart" on a course card
2. Dialog appears with two options:
   - **Add to Cart** - adds to cart and shows success snackbar
   - **Enroll Now** - opens direct enrollment form
3. User can continue browsing or proceed to checkout

### Industry Training Pathway

1. User clicks "Add to Cart" on a course card
2. Dialog appears with two options:
   - **Add to Cart** - adds to cart and shows success snackbar
   - **Enroll Now** - opens multi-step AICERTS industry training modal
3. Multi-step modal includes:
   - Quantity selection
   - Experience level selection
   - Corporate vs Individual enrollment
   - Learner details form (with separate first/last name)
   - Review and payment

## AICERTS Membership Trigger

The enrollment process triggers AICERTS membership through:

1. **Direct Enrollment:** When user completes the enrollment form, the backend creates an AICERTS enrollment record
2. **Cart Checkout:** When user checks out from cart, the payment flow creates AICERTS enrollments

The enrollment payload includes:
```dart
{
  'industry': industry,
  'course_type': 'aicerts_course',
  'is_industry_course': isIndustryCourse,
  // ... learner details
}
```

This triggers the AICERTS integration to:
- Create learner account on AICERTS platform
- Enroll in specified courses
- Enable AI-powered learning tools
- Track progress and issue certificates

## Price Display

Prices are displayed consistently across all touchpoints:

1. **Course Card:** Shows `course.localPrice` or formatted `course.price`
2. **Enrollment Dialog:** Shows same price with prominent display
3. **Enrollment Form:** Pre-fills `enrollmentFee` with `course.price`
4. **Payment:** Uses `course.price` for payment amount

All prices are in USD by default, with localization support via `CurrencyService`.

## Testing Recommendations

1. **Cart Addition:**
   - Add single course to cart
   - Try adding same course again (should show "already in cart")
   - Add multiple different courses

2. **Direct Enrollment:**
   - Click "Enroll Now"
   - Fill form with separate first/last name
   - Complete payment flow
   - Verify AICERTS enrollment created

3. **Price Persistence:**
   - Verify price on course card matches enrollment dialog
   - Verify price matches payment amount
   - Test with courses that have no price set (should use default)

4. **Mobile Responsiveness:**
   - Test on mobile devices
   - Verify dialogs are readable
   - Verify buttons are tappable

## Files Modified

1. `frontend/lib/src/presentation/pages/onboarding/widgets/sections/aicerts_courses.dart`
   - Added cart functionality
   - Changed button text to "Add to Cart"
   - Added enrollment options dialog

2. `frontend/lib/src/presentation/pages/industry_training/industry_training_enrollment_page.dart`
   - Added cart functionality
   - Changed button text to "Add to Cart"
   - Added enrollment options dialog

## Files Referenced (No Changes Required)

1. `frontend/lib/src/presentation/widgets/modals/aicerts/shared/aicerts_form_data.dart`
   - Already has separate first/last name fields

2. `frontend/lib/src/core/services/cart_service.dart`
   - Already provides cart functionality

3. `frontend/lib/src/core/providers/cart_provider.dart`
   - Already provides cart state management

## Next Steps

1. Test the implementation in development environment
2. Verify cart sync works for authenticated and guest users
3. Test AICERTS enrollment creation after payment
4. Verify price persistence across all screens
5. Test on multiple devices and screen sizes
