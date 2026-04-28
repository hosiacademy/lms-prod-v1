# Drag-and-Drop Shopping Cart & Wishlist Implementation

## Overview
Implemented intuitive drag-and-drop functionality allowing students to add courses, learnerships, masterclasses, and industry training to their shopping cart or wishlist by simply dragging items from the catalog to the header icons.

## Features Implemented

### 1. **Draggable Course Cards**
All course items in the `UnifiedCatalogPage` are draggable:
- **Courses** (Industry Training, AICERTS)
- **Learnerships**
- **Masterclasses**

#### Visual Feedback
- **Long-press to drag** - User holds down on a course card
- **Drag feedback** - Semi-transparent card follows cursor (0.8 opacity)
- **Original card fades** - Source card becomes 30% opacity while dragging
- **Drag indicator icon** - Shows drag_indicator icon on cards

### 2. **Drop Targets in Header**

#### Shopping Cart Icon
- **Accepts:** Courses, Learnerships, Masterclasses
- **Visual feedback when hovering:**
  - Background color changes to primary color (20% opacity)
  - 2px border appears in primary color
  - Icon changes from outlined to filled
- **On drop:**
  - Item is added to cart via `CartService`
  - Success snackbar shows: "Item name added to cart" (green)
  - If already in cart: "Item name is already in cart"
  - Cart count badge updates automatically

#### Wishlist Icon
- **Accepts:** Courses, Learnerships, Masterclasses
- **Visual feedback when hovering:**
  - Background color changes to gold/orange (30% opacity)
  - 2px border appears in gold color (#F79150)
  - Icon changes from outlined to filled bookmark
- **On drop:**
  - Item is added to wishlist via `WishlistService`
  - Success snackbar shows: "Item name added to wishlist" (gold)
  - If already in wishlist: "Item name is already in wishlist"
  - Wishlist count badge updates automatically

### 3. **Smart Type Conversion**

The system automatically converts different item types to the `Course` model:

```dart
// Learnership → Course
Course(
  id: learnership.id.toString(),
  title: learnership.title,
  description: learnership.description,
  price: learnership.priceUsd,
  featureImageUrl: learnership.imageUrl,
)

// Masterclass → Course
Course(
  id: masterclass.id.toString(),
  title: masterclass.title,
  description: masterclass.description,
  price: masterclass.priceUsd,
  featureImageUrl: masterclass.imageUrl,
)
```

## User Experience Flow

### Adding to Cart via Drag-and-Drop

1. **Student browses catalog** - Views courses in UnifiedCatalogPage
2. **Long-press on course card** - Card becomes draggable
3. **Drag towards header** - Semi-transparent card follows cursor
4. **Hover over cart icon** - Icon highlights with blue border and fills in
5. **Release to drop** - Course is added to cart
6. **Confirmation** - Green snackbar appears: "Course Name added to cart"
7. **Badge updates** - Cart count increases automatically

### Adding to Wishlist via Drag-and-Drop

1. **Student browses catalog** - Views courses in UnifiedCatalogPage
2. **Long-press on course card** - Card becomes draggable
3. **Drag towards header** - Semi-transparent card follows cursor
4. **Hover over wishlist icon** - Icon highlights with gold border and fills in
5. **Release to drop** - Course is added to wishlist
6. **Confirmation** - Gold snackbar appears: "Course Name added to wishlist"
7. **Badge updates** - Wishlist count increases automatically

## Technical Implementation

### Files Modified

1. **`dashboard_header.dart`**
   - Added imports for Course, Learnership, Masterclass models
   - Wrapped cart icon with `DragTarget<Object>`
   - Wrapped wishlist icon with `DragTarget<Object>`
   - Added `_handleCartDrop()` method
   - Added `_handleWishlistDrop()` method
   - Implemented visual feedback with `AnimatedContainer`

2. **`unified_catalog_page.dart`** (Already existed)
   - `_DraggableMasterclassCard` - Makes masterclass cards draggable
   - `_DraggableCourseCard` - Makes course cards draggable
   - Uses `LongPressDraggable<T>` widget

### Key Components

#### DragTarget Configuration
```dart
DragTarget<Object>(
  onWillAcceptWithDetails: (details) {
    // Accept Course, Learnership, or Masterclass
    return details.data is Course ||
        details.data is Learnership ||
        details.data is Masterclass;
  },
  onAcceptWithDetails: (details) {
    _handleCartDrop(details.data, context);
  },
  builder: (context, candidateData, rejectedData) {
    final isHovering = candidateData.isNotEmpty;
    // Build animated icon with visual feedback
  },
)
```

#### Handler Methods
```dart
void _handleCartDrop(dynamic item, BuildContext context) {
  // 1. Identify item type
  // 2. Convert to Course if needed
  // 3. Add to CartService
  // 4. Show confirmation snackbar
}

void _handleWishlistDrop(dynamic item, BuildContext context) {
  // 1. Identify item type
  // 2. Convert to Course if needed
  // 3. Add to WishlistService
  // 4. Show confirmation snackbar
}
```

## Visual Design

### Drag Feedback
- **Opacity:** 0.8 (slightly transparent)
- **Elevation:** 8 (floating effect)
- **Size:** 300px width (consistent)
- **Border radius:** 16px (rounded corners)

### Drop Target Feedback

#### Cart (Hovering)
- **Background:** Primary color at 20% opacity
- **Border:** 2px solid primary color
- **Icon:** Filled shopping cart
- **Animation:** 200ms smooth transition

#### Wishlist (Hovering)
- **Background:** Gold (#F79150) at 30% opacity
- **Border:** 2px solid gold
- **Icon:** Filled bookmark
- **Animation:** 200ms smooth transition

### Success Notifications

#### Cart Success
```dart
SnackBar(
  content: Text('"Course Name" added to cart'),
  backgroundColor: Colors.green,
  duration: Duration(seconds: 2),
)
```

#### Wishlist Success
```dart
SnackBar(
  content: Text('"Course Name" added to wishlist'),
  backgroundColor: Color(0xFFF79150), // Gold
  duration: Duration(seconds: 2),
)
```

## Benefits

### User Experience
- ✅ **Intuitive interaction** - Natural drag-and-drop gesture
- ✅ **Visual feedback** - Clear indication of drag state and drop targets
- ✅ **Instant confirmation** - Immediate snackbar feedback
- ✅ **Real-time updates** - Badge counts update automatically
- ✅ **Error prevention** - Duplicate detection prevents adding same item twice

### Developer Experience
- ✅ **Type-safe** - Uses proper type checking (Course, Learnership, Masterclass)
- ✅ **Reusable** - Handler methods work for all item types
- ✅ **Maintainable** - Clear separation of concerns
- ✅ **Extensible** - Easy to add new item types

### Performance
- ✅ **Smooth animations** - Hardware-accelerated transitions
- ✅ **Efficient** - Only updates affected widgets
- ✅ **Responsive** - 200ms animation duration for snappy feel

## Alternative Interaction Methods

Students can still add items using traditional methods:
1. **Click "Add to Cart" button** on course cards
2. **Click bookmark icon** on course cards
3. **Use course details panel** buttons

The drag-and-drop is an **additional convenience feature**, not a replacement.

## Accessibility Considerations

### Current Implementation
- Drag-and-drop works with mouse/touch input
- Visual feedback is clear and prominent
- Tooltips explain functionality

### Future Enhancements
- Add keyboard shortcuts (e.g., Ctrl+C for cart, Ctrl+W for wishlist)
- Screen reader announcements for drag/drop actions
- High contrast mode support

## Testing Checklist

### Functional Testing
- [ ] Drag course to cart icon
- [ ] Drag learnership to cart icon
- [ ] Drag masterclass to cart icon
- [ ] Drag course to wishlist icon
- [ ] Drag learnership to wishlist icon
- [ ] Drag masterclass to wishlist icon
- [ ] Verify duplicate prevention
- [ ] Verify badge count updates
- [ ] Verify snackbar messages
- [ ] Test on mobile (touch)
- [ ] Test on desktop (mouse)

### Visual Testing
- [ ] Drag feedback appears correctly
- [ ] Drop target highlights on hover
- [ ] Icons change from outlined to filled
- [ ] Borders appear with correct colors
- [ ] Animations are smooth (200ms)
- [ ] Original card fades to 30% opacity
- [ ] Snackbars have correct colors

### Edge Cases
- [ ] Drag item already in cart
- [ ] Drag item already in wishlist
- [ ] Drag multiple items rapidly
- [ ] Cancel drag (release outside targets)
- [ ] Drag while cart/wishlist panel is open

## Known Limitations

1. **No keyboard support** - Currently mouse/touch only
2. **No multi-select** - Can only drag one item at a time
3. **No drag preview customization** - Uses default card appearance
4. **No undo** - Must manually remove from cart/wishlist

## Future Enhancements

### Short-term
1. **Drag to remove** - Drag from cart/wishlist panels to trash icon
2. **Drag between cart and wishlist** - Move items between the two
3. **Batch drag** - Select multiple items and drag together

### Long-term
1. **Drag to compare** - Drag courses to comparison panel
2. **Drag to schedule** - Drag to calendar for enrollment planning
3. **Drag to share** - Drag to share with friends/colleagues
4. **Custom drag previews** - Show price, rating during drag

## Enrollment Flow (No Input Required)

### Current Implementation
When a student proceeds to checkout from the cart, the system should:

1. **Use existing student data** from the authenticated session
2. **No additional forms** - Student details already in database
3. **Direct to payment** - Skip enrollment forms entirely

### Required Updates (TODO)

The checkout flow needs to be updated to:

```dart
// In CartPanel, when "Proceed to Checkout" is clicked:
void _proceedToCheckout() {
  // Get current user from auth
  final user = authService.currentUser;
  
  // Get cart items
  final cartItems = cartService.getAllItems();
  
  // Navigate directly to payment
  context.go('/payment', extra: {
    'user': user,
    'items': cartItems,
    'skipEnrollmentForm': true, // Use existing data
  });
}
```

### Student Data Already Available
- ✅ Name
- ✅ Email
- ✅ Phone number
- ✅ Country
- ✅ City
- ✅ Profile information

**No need to ask for this information again!**

## Summary

The drag-and-drop implementation provides a **modern, intuitive way** for students to add courses to their cart and wishlist. The visual feedback is clear, the interaction is smooth, and the system intelligently handles different item types. Combined with the existing click-to-add functionality, students now have **multiple convenient ways** to manage their course selections.

The next step is to **streamline the checkout process** to use existing student data without requiring additional form inputs.
