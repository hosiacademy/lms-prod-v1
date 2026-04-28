#!/bin/bash
# Test script to verify OTP removal from payment phase in enrollment pathway

echo "========================================="
echo "LMS Enrollment OTP Removal Test"
echo "========================================="
echo ""

# Test 1: Verify PaymentOTPVerification widget is NOT imported in multi_step_enrollment_modal.dart
echo "Test 1: Checking if PaymentOTPVerification is imported in enrollment modal..."
if grep -q "import.*payment_otp_verification" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart; then
    echo "❌ FAIL: PaymentOTPVerification is still imported"
    exit 1
else
    echo "✅ PASS: PaymentOTPVerification is NOT imported (removed)"
fi
echo ""

# Test 2: Verify ContactOtpField exists in Step 2 (Learner Info)
echo "Test 2: Checking if ContactOtpField exists in Step 2..."
if grep -q "ContactOtpField" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart; then
    echo "✅ PASS: ContactOtpField found in enrollment modal"
else
    echo "❌ FAIL: ContactOtpField not found"
    exit 1
fi
echo ""

# Test 3: Verify NO OTP at payment stage comment exists
echo "Test 3: Checking for OTP removal confirmation comment..."
if grep -q "NO OTP at payment stage" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart; then
    echo "✅ PASS: OTP removal comment found"
else
    echo "❌ FAIL: OTP removal comment not found"
    exit 1
fi
echo ""

# Test 4: Verify _buildReviewStep (Step 3) has NO OTP references
echo "Test 4: Checking Step 3 (Review & Payment) for OTP..."
STEP3_START=$(grep -n "_buildReviewStep" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart | tail -1 | cut -d: -f1)
if [ -z "$STEP3_START" ]; then
    echo "❌ FAIL: Could not find _buildReviewStep function"
    exit 1
fi

# Extract next 100 lines from _buildReviewStep and check for OTP
STEP3_CONTENT=$(sed -n "${STEP3_START},$((STEP3_START+100))p" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart)
if echo "$STEP3_CONTENT" | grep -qi "OTP\|otp\|verify.*email"; then
    echo "❌ FAIL: OTP found in Step 3 (Review & Payment)"
    exit 1
else
    echo "✅ PASS: No OTP in Step 3 (Review & Payment)"
fi
echo ""

# Test 5: Verify _proceedToPayment has no OTP verification
echo "Test 5: Checking _proceedToPayment function..."
PROCEED_START=$(grep -n "_proceedToPayment" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart | head -1 | cut -d: -f1)
if [ -z "$PROCEED_START" ]; then
    echo "❌ FAIL: Could not find _proceedToPayment function"
    exit 1
fi

PROCEED_CONTENT=$(sed -n "${PROCEED_START},$((PROCEED_START+100))p" /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/multi_step_enrollment_modal.dart)
if echo "$PROCEED_CONTENT" | grep -qi "PaymentOTPVerification\|verifyOTP\|sendOTP"; then
    echo "❌ FAIL: OTP verification found in _proceedToPayment"
    exit 1
else
    echo "✅ PASS: No OTP verification in _proceedToPayment"
fi
echo ""

# Test 6: Verify backend FinalizeEnrollmentView doesn't require OTP
echo "Test 6: Checking backend FinalizeEnrollmentView..."
if grep -q "otp\|OTP" /home/tk/lms-prod/backend/apps/payments/enrollment_views.py; then
    echo "❌ FAIL: OTP requirement found in backend FinalizeEnrollmentView"
    exit 1
else
    echo "✅ PASS: Backend FinalizeEnrollmentView has no OTP requirement"
fi
echo ""

# Test 7: Verify PaymentProviderSelectionPage has no OTP
echo "Test 7: Checking PaymentProviderSelectionPage..."
if grep -qi "OTP\|otp\|verify.*email" /home/tk/lms-prod/frontend/lib/src/presentation/pages/payment/payment_provider_selection_page.dart; then
    echo "❌ FAIL: OTP found in PaymentProviderSelectionPage"
    exit 1
else
    echo "✅ PASS: No OTP in PaymentProviderSelectionPage"
fi
echo ""

echo "========================================="
echo "All Tests Passed! ✅"
echo "========================================="
echo ""
echo "Summary:"
echo "- OTP verification ONLY exists in Step 2 (Personal Data Collection)"
echo "- OTP verification REMOVED from Step 3 (Review & Payment)"
echo "- PaymentOTPVerification widget exists but is NOT USED"
echo "- Backend does not require OTP at payment finalization"
echo "- PaymentProviderSelectionPage has no OTP logic"
echo ""
