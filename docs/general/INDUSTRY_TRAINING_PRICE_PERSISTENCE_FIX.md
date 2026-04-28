# Industry Training & Custom Selection - Price Persistence & Cart Functionality Fix

## 🔍 Problem Analysis

### Current Issues

1. **Price Not Visible in Enrollment Form** ❌
   - Course price shows on course cards ✓
   - Price disappears once user clicks "Enroll Now" ❌
   - No total amount displayed during enrollment form filling ❌
   - User doesn't know what they're committing to pay ❌

2. **Payment Initiation Using Temporary Reference** ❌
   ```dart
   // CURRENT (WRONG):
   reference: 'AICERTS-IT-${DateTime.now().millisecondsSinceEpoch}',
   reference: 'AICERTS-CS-${DateTime.now().millisecondsSinceEpoch}',
   ```
   - Should call `/api/v1/payments/initiate/` first
   - Should get real payment reference from backend
   - Current approach bypasses order creation

3. **Cart Functionality Missing in Industry Training** ❌
   - Custom Selection has cart ✓
   - Industry Training has NO cart ✗
   - Users can't select multiple courses in Industry Training
   - Each course requires separate enrollment

---

## ✅ Solution Architecture

### 1. Price Persistence Flow

```
┌─────────────────────────────────────────────────────────────┐
│ Course Card                                                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Course Title                                            │ │
│ │ Description...                                          │ │
│ │                                                         │ │
│ │ Price: $250 / R 4,750  ← Visible ✓                     │ │
│ │ [Enroll Now]                                            │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ Click "Enroll Now"
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Enrollment Modal - Step 0: Course Selection                 │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Selected Courses:                                       │ │
│ │ ☑ Course 1 - $250                                       │ │
│ │ ☑ Course 2 - $250                                       │ │
│ │                                                         │ │
│ │ ─────────────────────────────────                       │ │
│ │ Total: $500 / R 9,500  ← PERSISTED ✓                   │ │
│ │                                                         │ │
│ │ [Continue to Personal Info]                             │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ Continue
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Enrollment Modal - Step 1: Personal Information             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Personal Details Form...                                │ │
│ │                                                         │ │
│ │ ─────────────────────────────────                       │ │
│ │ Course Total: $500 / R 9,500  ← STILL VISIBLE ✓        │ │
│ │                                                         │ │
│ │ [Back] [Continue to Payment]                            │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ Continue
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Enrollment Modal - Step 2: Payment Option                   │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Payment Method Selection                                │ │
│ │ ○ Card Payment                                          │ │
│ │ ○ EFT Transfer                                          │ │
│ │ ○ Mobile Money                                          │ │
│ │                                                         │ │
│ │ ─────────────────────────────────                       │ │
│ │ Amount to Pay: $500 / R 9,500  ← COMMITTED ✓           │ │
│ │                                                         │ │
│ │ [Back] [Pay Now]                                        │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ Pay Now
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Payment Initiation API Call                                 │
│ POST /api/v1/payments/initiate/                             │
│ {                                                           │
│   "program_id": "course_id",                                │
│   "type": "industry_training",                              │
│   "amount": 500.00,                                         │
│   "metadata": { ... }                                       │
│ }                                                           │
└─────────────────────────────────────────────────────────────┘
                        │
                        │ Response: { "reference": "PAY-XXX" }
                        ▼
┌─────────────────────────────────────────────────────────────┐
│ Payment Provider Selection                                  │
│ Uses REAL reference from API ✓                              │
│ Amount locked: $500 / R 9,500 ✓                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Implementation Plan

### Phase 1: Add Price Display in Enrollment Forms

#### A. Industry Training Modal (`multi_step_aicerts_industry_training_modal.dart`)

**Step 0 - Add Course Selection with Price Display:**

```dart
Widget _buildCourseSelectionStep(ThemeData theme, ColorScheme colors) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Select Courses',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Choose the industry-specific courses you want to enroll in',
        style: theme.textTheme.bodyMedium,
      ),
      const SizedBox(height: 24),
      
      // Course list with checkboxes
      ...widget.courses.asMap().entries.map((entry) {
        final index = entry.key;
        final course = entry.value;
        return Card(
          child: CheckboxListTile(
            value: _selectedCourses[index],
            onChanged: (val) {
              setState(() => _selectedCourses[index] = val!);
            },
            title: Text(course.title),
            subtitle: Text(course.description ?? ''),
            secondary: ListenableBuilder(
              listenable: CurrencyService.instance,
              builder: (context, _) => Text(
                CurrencyService.instance.formatPrice(course.price ?? 250),
                style: TextStyle(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
      
      const SizedBox(height: 24),
      
      // PRICE PERSISTENCE BANNER
      _buildPriceSummaryBanner(theme, colors),
    ],
  );
}

Widget _buildPriceSummaryBanner(ThemeData theme, ColorScheme colors) {
  final totalCourses = _selectedCourses.where((s) => s).length;
  final totalPrice = _calculateTotalPrice();
  
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          colors.primaryContainer,
          colors.primaryContainer.withValues(alpha: 0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.primary, width: 2),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Course Total',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                ListenableBuilder(
                  listenable: CurrencyService.instance,
                  builder: (context, _) => Text(
                    CurrencyService.instance.formatPrice(totalPrice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalCourses Course${totalCourses != 1 ? 's' : ''}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Icons.shopping_cart, color: colors.primary, size: 32),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: totalCourses / widget.courses.length,
          backgroundColor: colors.surface,
          color: colors.primary,
        ),
        const SizedBox(height: 8),
        Text(
          'This amount will be committed for payment',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
      ],
    ),
  );
}
```

**Step 3 (Payment) - Add Price Display:**

```dart
Widget _buildPaymentSelectionStep(ThemeData theme, ColorScheme colors) {
  return Column(
    children: [
      // ... existing payment options ...
      
      const SizedBox(height: 24),
      
      // PRICE COMMITMENT BANNER
      _buildPaymentPriceBanner(theme, colors),
    ],
  );
}

Widget _buildPaymentPriceBanner(ThemeData theme, ColorScheme colors) {
  final totalPrice = _calculateTotalPrice();
  
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.successContainer ?? colors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.successGreen, width: 2),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Icon(Icons.lock, color: AppTheme.successGreen, size: 24),
            const SizedBox(width: 12),
            Text(
              'Amount Committed',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: CurrencyService.instance,
          builder: (context, _) => Text(
            CurrencyService.instance.formatPrice(totalPrice),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.successGreen,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Includes ${_selectedCourses.where((s) => s).length} courses × $_quantity learner(s)',
          style: theme.textTheme.bodySmall,
        ),
      ],
    ),
  );
}
```

#### B. Custom Selection Modal (`multi_step_aicerts_custom_selection_modal.dart`)

Apply the same price banner components as Industry Training above.

---

### Phase 2: Fix Payment Initiation

**Replace temporary reference with proper API call:**

```dart
Future<void> _proceedToPayment() async {
  if (_isProcessing || _isSubmitting) return;

  setState(() => _isSubmitting = true);

  try {
    // 1. Calculate total price
    final totalPrice = _calculateTotalPrice();
    
    // 2. Prepare enrollment payload
    final enrollmentPayload = {
      'courses': widget.courses.map((c) => c.id).toList(),
      'is_corporate': _isCorporate,
      'quantity': _quantity,
      'total_price_usd': totalPrice,
      'industry': widget.industry,
      'role': widget.role,
      'stream_type': _getStreamTypeForIndustry(),
      'enrollment_type': 'industry_training',
      'experience_level': _selectedExperienceLevel,
      
      if (_isCorporate) ..._buildCompanyData(),
      
      'learners': _learners.map((learner) => learner.toJson()).toList(),
    };

    // 3. INITIATE PAYMENT VIA API (NEW)
    final paymentResponse = await ApiClient.initiatePayment(
      programId: widget.courses.first.id,
      type: widget.courses.length > 1 ? 'role_training' : 'industry_training',
      amount: totalPrice,
      metadata: {
        'course_count': widget.courses.length,
        'learner_count': _quantity,
        'is_corporate': _isCorporate,
        'course_ids': widget.courses.map((c) => c.id).toList(),
        'industry': widget.industry,
        'role': widget.role,
      },
    );
    
    final paymentReference = paymentResponse['reference'] as String;

    // 4. Show payment modal with REAL reference
    await PaymentProviderSelectionPage.show(
      context,
      reference: paymentReference,  // ← REAL reference from API
      amount: totalPrice,
      currency: CurrencyService.instance.userCurrency,
      country: _learners.first.selectedCountryName ?? 'ZA',
      programId: widget.courses.first.id,
      programType: widget.courses.length > 1 ? 'role_training' : 'industry_training',
      paymentMetadata: {
        'enrollment_type': widget.courses.length > 1 ? 'role_training' : 'industry_training',
        'industry': widget.industry,
        'role': widget.role,
        'course_count': widget.courses.length,
        'learner_count': _quantity,
        'is_corporate': _isCorporate,
        'course_ids': widget.courses.map((c) => c.id).toList(),
        'individual_details': _learners.isNotEmpty ? _learners[0].toJson() : {},
        'terms_accepted': _learners.isNotEmpty 
            ? (_learners[0].termsAccepted && _learners[0].aicertsPlatformAgreement) 
            : false,
        if (_isCorporate) 'company_data': _buildCompanyData(),
      },
      enrollmentPayload: enrollmentPayload,
    );
    
    // 5. Handle completion
    if (widget.onEnrollmentComplete != null) {
      widget.onEnrollmentComplete!();
    }
    
  } catch (e) {
    _showError('Error proceeding to payment: $e');
  } finally {
    if (mounted) setState(() => _isSubmitting = false);
  }
}
```

---

### Phase 3: Implement Cart for Industry Training

#### A. Update Industry Training Page

**Add cart functionality similar to Custom Selection:**

```dart
class IndustryTrainingEnrollmentPage extends StatefulWidget {
  final bool embedMode;
  const IndustryTrainingEnrollmentPage({super.key, this.embedMode = false});

  @override
  State<IndustryTrainingEnrollmentPage> createState() =>
      _IndustryTrainingEnrollmentPageState();
}

class _IndustryTrainingEnrollmentPageState
    extends State<IndustryTrainingEnrollmentPage> {
  List<Course> _courses = [];
  Set<String> _selectedCourseIds = {}; // NEW: Track selected courses
  
  // ... existing code ...
  
  void _addToCart(Course course) {
    setState(() {
      _selectedCourseIds.add(course.id);
    });
    cartService.addCourse(course);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.title} added to cart'),
        backgroundColor: AppTheme.successGreen,
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () {
            // Show cart panel or navigate to cart
          },
        ),
      ),
    );
  }
  
  void _removeFromCart(Course course) {
    setState(() {
      _selectedCourseIds.remove(course.id);
    });
    cartService.removeCourse(course.id);
  }
  
  void _proceedToEnrollment() {
    final selectedCourses = _courses
        .where((c) => _selectedCourseIds.contains(c.id))
        .toList();
    
    if (selectedCourses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one course'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Show multi-step modal with selected courses
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MultiStepAICERTSIndustryTrainingModal(
          courses: selectedCourses,
          industry: _selectedIndustry,
          role: _selectedRole,
          onEnrollmentComplete: () {
            // Clear cart after successful enrollment
            cartService.clearCart();
            setState(() {
              _selectedCourseIds.clear();
            });
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enrollment completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          allowPrefill: true,
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // ... existing build code ...
    
    // Add cart summary bar at bottom
    return Column(
      children: [
        // ... existing content ...
        
        // NEW: Cart Summary Bar (only if courses selected)
        if (_selectedCourseIds.isNotEmpty)
          _buildCartSummaryBar(theme, colors),
      ],
    );
  }
  
  Widget _buildCartSummaryBar(ThemeData theme, ColorScheme colors) {
    final selectedCount = _selectedCourseIds.length;
    final selectedCourses = _courses
        .where((c) => _selectedCourseIds.contains(c.id))
        .toList();
    final totalPrice = selectedCourses.fold<double>(
      0,
      (sum, course) => sum + (course.price ?? 250),
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$selectedCount Course${selectedCount > 1 ? 's' : ''} Selected',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ListenableBuilder(
                    listenable: CurrencyService.instance,
                    builder: (context, _) => Text(
                      'Total: ${CurrencyService.instance.formatPrice(totalPrice)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.successGreen,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton(
              onPressed: _proceedToEnrollment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline),
                  SizedBox(width: 8),
                  Text(
                    'Enroll Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### B. Update Course Card with Add to Cart

```dart
class _CourseCard extends StatelessWidget {
  final Course course;
  final bool isInCart;
  final VoidCallback onAddToCart;
  final VoidCallback onRemoveFromCart;
  final VoidCallback onEnrollNow;
  
  const _CourseCard({
    required this.course,
    required this.isInCart,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    required this.onEnrollNow,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ... course image and details ...
          
          // Action buttons
          Row(
            children: [
              // Add to Cart button
              Expanded(
                child: IconButton(
                  icon: Icon(
                    isInCart ? Icons.remove_shopping_cart : Icons.add_shopping_cart,
                  ),
                  onPressed: isInCart ? onRemoveFromCart : onAddToCart,
                  color: isInCart ? Colors.red : colors.primary,
                  tooltip: isInCart ? 'Remove from cart' : 'Add to cart',
                ),
              ),
              // Enroll Now button
              ElevatedButton(
                onPressed: onEnrollNow,
                child: const Text('Enroll'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 📋 Files to Modify

### 1. Industry Training
- `frontend/lib/src/presentation/pages/industry_training/industry_training_enrollment_page.dart`
  - Add cart selection state
  - Add cart summary bar
  - Update course cards with add/remove cart buttons
  
- `frontend/lib/src/presentation/widgets/modals/aicerts/multi_step_aicerts_industry_training_modal.dart`
  - Add course selection step with price display
  - Add price summary banner in all steps
  - Fix payment initiation to use API

### 2. Custom Selection
- `frontend/lib/src/presentation/widgets/modals/aicerts/multi_step_aicerts_custom_selection_modal.dart`
  - Add price summary banner in all steps
  - Fix payment initiation to use API

---

## 🎯 Expected Behavior After Fix

### Industry Training Flow

1. **Browse Courses** → User sees courses with prices ✓
2. **Add to Cart** → User can add multiple courses to cart ✓
3. **Cart Summary** → Bottom bar shows total courses + total price ✓
4. **Click "Enroll Now"** → Modal opens with selected courses ✓
5. **Step 0: Course Selection** → Shows selected courses with individual prices + total ✓
6. **Step 1: Personal Info** → Price banner visible at bottom ✓
7. **Step 2: Payment** → Shows committed amount ✓
8. **Click "Pay Now"** → Calls payment initiation API ✓
9. **Payment Modal** → Uses real reference, amount locked ✓
10. **Payment Success** → Cart cleared, enrollment created ✓

### Custom Selection Flow

1. **Browse Courses** → User sees courses with prices ✓
2. **Add to Cart** → User adds courses to cart ✓
3. **Cart Summary** → Bottom bar shows total ✓
4. **Click "Enroll Now"** → Modal opens ✓
5. **All Steps** → Price banner visible throughout ✓
6. **Payment** → Real API reference, amount locked ✓

---

## 🧪 Testing Checklist

- [ ] Price visible on course cards
- [ ] Price persists in enrollment modal Step 0
- [ ] Price persists in enrollment modal Step 1 (Personal Info)
- [ ] Price persists in enrollment modal Step 2 (Payment)
- [ ] Total calculated correctly for multiple courses
- [ ] Currency conversion displays correctly (USD/ZAR/etc)
- [ ] Payment initiation API called before payment modal
- [ ] Real payment reference used (not temporary)
- [ ] Cart functionality works in Industry Training
- [ ] Can add/remove multiple courses in Industry Training
- [ ] Cart cleared after successful enrollment
- [ ] Payment amount matches displayed total
- [ ] Enrollment payload includes correct price

---

## 📊 Database Schema Alignment

Ensure backend can handle:

```python
# Industry Training Enrollment
{
  "courses": ["course_id_1", "course_id_2"],
  "total_price_usd": 500.00,
  "industry": "healthcare",
  "role": "analyst",
  "learners": [...],
  "company_data": {...}  # if corporate
}

# Order Creation
{
  "reference": "PAY-IND-123456",
  "amount": 500.00,
  "currency": "USD",
  "type": "industry_training",
  "metadata": {
    "course_count": 2,
    "course_ids": ["course_id_1", "course_id_2"],
    "industry": "healthcare"
  }
}
```

---

## 🔗 Related Documentation

- [Learnership Enrollment Flow Render](./LEARNERSHIP_ENROLLMENT_FLOW_RENDER.md)
- [Enrollment Flow Payment Sandbox Alignment](./ENROLLMENT_FLOW_PAYMENT_SANDBOX_ALIGNMENT.md)

---

**Generated:** 2026-03-18  
**Author:** Qwen Code  
**Priority:** HIGH - Critical for payment flow integrity
