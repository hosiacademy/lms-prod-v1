# Cybersecurity Learnerships Implementation

## Overview

Implemented separate **Cybersecurity Learnerships** page that runs parallel to the **AI & Blockchain Learnerships** page. Both pages:
- Share the same backend models and database tables
- Use the same enrollment flow and payment flow
- Have identical business logic and principles
- Are filtered by category at the API/frontend level

## Changes Made

### 1. Backend Changes

#### Database Updates
Updated learnership records with proper categories and visibility flags:

```python
# Cybersecurity (6 programmes - is_offered=True)
- SOC Analyst Learnership 2026
- Security Engineer Learnership 2026
- Security Consultant Learnership 2026
- Red Teamer Learnership 2026
- Blue Teamer Learnership 2026
- Bug Hunter Learnership 2026

# AI & Blockchain (2 programmes - is_offered=True)
- AI Developer / Machine Learning Engineer Learnership
- Data Scientist / AI Data Engineer Learnership

# Hidden (is_offered=False)
- AI Engineer / Deep Learning Specialist (not offered yet)
- Cloud AI Engineer / MLOps Specialist (not offered yet)
- Occupational Health & Safety (not offered yet)
- All test learnerships (8 total)
```

#### API Enhancement (`backend/apps/learnerships/views.py`)
Added `category` filter parameter to the learnerships API:

```python
def get_queryset(self):
    queryset = LearnershipProgramme.objects.filter(active=True, is_offered=True)
    
    category = self.request.query_params.get('category')
    if category:
        queryset = queryset.filter(category=category)
    # ... other filters
```

### 2. Frontend Changes

#### New Cybersecurity Page
Created: `frontend/lib/src/presentation/pages/cybersecurity_learnerships/cybersecurity_learnerships_page.dart`

Key features:
- Filters by `category='Cybersecurity'`
- Identical structure to AI & Blockchain learnerships page
- Same enrollment modal and payment flow
- Custom branding (security icon, different color scheme)
- Pathway diagram specific to cybersecurity careers

#### Data Provider Enhancement
Updated: `frontend/lib/src/presentation/pages/learnerships/providers/learnership_data_provider.dart`

Added category filter support:
```dart
LearnershipDataProvider({
  String? initialSpecialization, 
  String? categoryFilter  // New parameter
})
```

#### API Client Enhancement
Updated: `frontend/lib/src/core/api/api_client.dart`

Added category parameter to `getLearnerships()`:
```dart
static Future<List<Learnership>> getLearnerships({
  String? category,  // New parameter
  // ... other params
})
```

#### Navigation Updates
Updated: `frontend/lib/src/presentation/pages/onboarding/onboarding_page.dart`

1. Added import for Cybersecurity page
2. Added route handling:
   - `/enroll/cybersecurity` → `CybersecurityLearnershipsPage()`
3. Updated footer links

#### Learning Pathways Component
Updated: `frontend/lib/src/presentation/pages/onboarding/widgets/sections/learning_pathways_compact.dart`

Changed from 4 to 5 pathway cards:
1. Corporate Training
2. **AI & Blockchain Learnerships** (renamed from "Learnerships")
3. **Cybersecurity Learnerships** (NEW)
4. Industry & Role Based Training
5. Custom Selection

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Onboarding Page                        │
│  ┌─────────────────────────────────────────────────┐    │
│  │        Learning Pathways (5 cards)              │    │
│  │  [Corporate] [AI&Blockchain] [Cybersecurity]    │    │
│  │  [Industry]  [Custom]                           │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
         │                        │
         │ /enroll/learnerships   │ /enroll/cybersecurity
         ▼                        ▼
┌─────────────────────┐  ┌─────────────────────────────┐
│ AI & Blockchain     │  │ Cybersecurity               │
│ Learnerships Page   │  │ Learnerships Page           │
│                     │  │                             │
│ category='AI &      │  │ category='Cybersecurity'    │
│ Blockchain'         │  │                             │
└─────────────────────┘  └─────────────────────────────┘
         │                        │
         └────────┬───────────────┘
                  │
         ┌────────▼────────┐
         │  Same Backend   │
         │  Same Models    │
         │  Same API       │
         │  Same Payments  │
         └─────────────────┘
```

## User Experience

### Onboarding Page
Users see 5 distinct pathway cards:
- **AI & Blockchain Learnerships** (green) → AI/ML programmes
- **Cybersecurity Learnerships** (peach) → Security programmes

### Separate Pages
Each page shows only its category:
- AI & Blockchain page: 2 programmes (AI Developer, Data Scientist)
- Cybersecurity page: 6 programmes (SOC, Security Engineer, etc.)

### Same Enrollment Flow
Both pages use:
- Same multi-step enrollment modal
- Same payment options (Full, Debit Order, Cash at Office)
- Same prerequisite evidence upload
- Same admin review process

## Testing

### Backend Verification
```bash
cd /home/tk/lms-prod/backend
source ../venv_new/bin/activate
python manage.py shell

# Test filtering
from apps.learnerships.models import LearnershipProgramme
LearnershipProgramme.objects.filter(category='Cybersecurity', active=True, is_offered=True).count()  # 6
LearnershipProgramme.objects.filter(category='AI & Blockchain', active=True, is_offered=True).count()  # 2
```

### Frontend Testing
1. Navigate to onboarding page
2. Click "AI & Blockchain Learnerships" → Should show 2 programmes
3. Click "Cybersecurity Learnerships" → Should show 6 programmes
4. Test enrollment flow on both → Should be identical

## Future Considerations

1. **Adding New Programmes**: Simply create a new `LearnershipProgramme` with the appropriate `category` field
2. **Hiding Programmes**: Set `is_offered=False` to hide from frontend while keeping in backend
3. **Additional Categories**: Can easily add more categories (e.g., "Business", "Health & Safety")

## Files Modified

### Backend
- `backend/apps/learnerships/views.py` - Added category filter
- Database: Updated 19 learnership records with categories and is_offered flags

### Frontend
- `frontend/lib/src/presentation/pages/cybersecurity_learnerships/cybersecurity_learnerships_page.dart` (NEW)
- `frontend/lib/src/presentation/pages/learnerships/providers/learnership_data_provider.dart`
- `frontend/lib/src/core/api/api_client.dart`
- `frontend/lib/src/presentation/pages/onboarding/onboarding_page.dart`
- `frontend/lib/src/presentation/pages/onboarding/widgets/sections/learning_pathways_compact.dart`
