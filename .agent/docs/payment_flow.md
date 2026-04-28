# Payment & Enrollment Flow Architecture

This document outlines the corrected logic for the payment and enrollment process, specifically addressing the separation of successful and failed payment outcomes.

## ✅ Corrected Flowchart

```mermaid
flowchart TD
    Start[User selects enrollment pathway] --> Type{Which Pathway?}

    Type -->|1. Masterclass| MC1[Open: multi_step_enrollment_modal.dart<br>Collect: Personal info + optional company details]
    Type -->|2. Learnership| L1[Open: learnership_complete_enrollment_page.dart<br>Collect: Personal + optional company + learnership-specific fields<br>(prerequisite evidence upload option)]
    Type -->|3. Corporate/Industry Training| C1[Open: industry_training_enrollment_page.dart or corporate form<br>Collect: Company info + bulk learner list + roles]
    Type -->|4. Custom Selection| CS1[Open: custom_selection_enrollment_page.dart or catalog browser<br>Collect: Select specific courses/certifications/bundles<br>Personal + optional company info]

    MC1 --> V1[Validate all fields]
    L1 --> V2[Validate all fields]
    C1 --> V3[Validate all fields]
    CS1 --> V4[Validate selection + fields]

    V1 -->|Invalid| E1[Show errors in modal/page]
    V2 -->|Invalid| E2[Show errors in modal/page]
    V3 -->|Invalid| E3[Show errors in modal/page]
    V4 -->|Invalid| E4[Show errors in modal/page]

    V1 -->|Valid| S1[Show summary + total cost<br>Proceed to Payment]
    V2 -->|Valid| S2[Show summary + total cost<br>Proceed to Payment]
    V3 -->|Valid| S3[Show summary + bulk total cost<br>Proceed to Payment]
    V4 -->|Valid| S4[Show summary + dynamic cost (selected courses)<br>Proceed to Payment]

    S1 --> Pay
    S2 --> Pay
    S3 --> Pay
    S4 --> Pay

    subgraph "Shared Payment Flow – Adapter Pattern"
        Pay --> FE1[Call ApiClient.initiatePayment<br>POST /api/payments/initiate/<br>Send: pathwayType, programId, enrollmentType, minimal metadata, amount]
        FE1 --> BE1[Backend: PaymentService selects adapter<br>Based on ProviderCountryConfig + country]
        BE1 --> BE2[Create PaymentTransaction status=pending<br>Return payment_url/reference]
        BE2 --> FE2[Open payment_provider_selection_page.dart<br>Pass full enrollmentPayload (hidden from backend initially)]
        FE2 --> PayChoice{User selects method?}
    end

    PayChoice -->|Digital Gateway| GW[User pays on gateway<br>Redirect/STK Push/Card]
    PayChoice -->|Cash/Manual| CashFlow[Show instructions + reference code]

    GW --> WH[Gateway webhook to backend<br>Updates PaymentTransaction status]
    CashFlow --> BE3[Backend creates provisional enrollment<br>Status = pending_manual]

    GW --> FE_Verify[Frontend: User clicks 'I Have Completed Payment']
    FE_Verify --> PSuccessPage[Open PaymentSuccessPage]
    PSuccessPage --> API_Finalize[Call ApiClient.finalizeEnrollment<br>Send: reference + full enrollmentPayload]

    API_Finalize --> BE_Verify[Backend: Verify Payment Status]
    BE_Verify --> PS{Payment Success?}

    PS -->|No / Pending| Fail[Throw Exception<br>Show Error in PaymentSuccessPage]
    Fail --> END_FAIL[Enrollment FAILED<br>User CANNOT access courses]

    PS -->|Yes| BE4[Backend Creates Enrollment Record<br>Links to User & Order<br>Syncs with AICERTS]

    BE4 --> TB{Pathway Type?}

    TB -->|Masterclass| MProv[Provision access<br>Backend calls AICERTS APIs]
    TB -->|Corporate/Industry| CProv[Provision bulk access<br>Backend calls AICERTS APIs for all learners]
    TB -->|Learnership| LProv[Create provisional enrollment<br>Status = provisional<br>Expiry = +7 working days]
    TB -->|Custom Selection| CSProv[Provision selected courses]

    LProv --> VER[Admin verifies prerequisites<br>Within 7 days]

    VER --> VR{Verified?}
    VR -->|Yes| Full[Convert to full enrollment]
    VR -->|No| Refund[Trigger reimbursement<br>Update status = rejected]

    MProv --> SUCCESS
    CProv --> SUCCESS
    CSProv --> SUCCESS
    Full --> SUCCESS
    
    SUCCESS --> END_SUCCESS[Display Success Message<br>Show SSO URL / Access Link<br>User Accesses Courses]
    
    Refund --> REFUND_MSG[Show Refunded Message]
    REFUND_MSG --> END_CANCEL[Enrollment CANCELLED<br>Access Revoked]
```

## 🔑 Key Fixes & Logic

1.  **Separation of Concerns**:
    *   **Payment Initiation**: Only minimal data (amount, program ID) is sent to start the payment.
    *   **Enrollment Finalization**: Full learner data is sent *only* after the user confirms payment on the frontend.

2.  **Strict Success/Failure Branching**:
    *   **Failure Path**: If `finalizeEnrollment` detects a failed or pending payment, it throws an error. The flow ends at `END_FAIL`. The user **does not** get access.
    *   **Success Path**: Only if the backend confirms `status='success'` is the Enrollment record created and AICerts provisioning triggered. This leads to `END_SUCCESS`.

3.  **Learnership Logic**:
    *   Even with successful payment, Learnerships enter a `Provisional` state (7-day expiry).
    *   Access is **not** granted until Admin verification.
    *   If verification fails (`No`), a refund is triggered, leading to `END_CANCEL`.

This ensures that "Payment Failed" and "Update to Paid" result in distinctly different outcomes, fixing the logic error in the previous flow.
