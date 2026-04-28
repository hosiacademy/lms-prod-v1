#!/bin/bash

# Script to rename "learner" to "student" throughout the frontend
# Preserves "learnership" and "learnerships" unchanged

echo "========================================="
echo "Renaming 'learner' to 'student' in frontend"
echo "========================================="

# Navigate to frontend directory
cd "$(dirname "$0")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Renaming directories...${NC}"
# Rename directories from learner_portal to student_portal
if [ -d "lib/src/presentation/blocs/learner_portal" ]; then
    mv lib/src/presentation/blocs/learner_portal lib/src/presentation/blocs/student_portal
    echo "✓ Renamed blocs/learner_portal to blocs/student_portal"
fi

if [ -d "lib/src/presentation/pages/learner_portal" ]; then
    mv lib/src/presentation/pages/learner_portal lib/src/presentation/pages/student_portal
    echo "✓ Renamed pages/learner_portal to pages/student_portal"
fi

if [ -d "lib/src/presentation/widgets/learner_portal" ]; then
    mv lib/src/presentation/widgets/learner_portal lib/src/presentation/widgets/student_portal
    echo "✓ Renamed widgets/learner_portal to widgets/student_portal"
fi

echo -e "${YELLOW}Step 2: Renaming files...${NC}"
# Rename files containing learner in their names (excluding learnership files)
find lib -type f -name "*learner_profile*" | while read file; do
    newfile=$(echo "$file" | sed 's/learner_profile/student_profile/g')
    if [ "$file" != "$newfile" ]; then
        mv "$file" "$newfile"
        echo "✓ Renamed $(basename $file) to $(basename $newfile)"
    fi
done

find lib -type f -name "*learner_portal*" | while read file; do
    newfile=$(echo "$file" | sed 's/learner_portal/student_portal/g')
    if [ "$file" != "$newfile" ]; then
        mv "$file" "$newfile"
        echo "✓ Renamed $(basename $file) to $(basename $newfile)"
    fi
done

find lib -type f -name "*learner_dashboard*" | while read file; do
    newfile=$(echo "$file" | sed 's/learner_dashboard/student_dashboard/g')
    if [ "$file" != "$newfile" ]; then
        mv "$file" "$newfile"
        echo "✓ Renamed $(basename $file) to $(basename $newfile)"
    fi
done

# Rename documentation file
if [ -f "LEARNER_PORTAL_INTEGRATION.md" ]; then
    mv LEARNER_PORTAL_INTEGRATION.md STUDENT_PORTAL_INTEGRATION.md
    echo "✓ Renamed LEARNER_PORTAL_INTEGRATION.md"
fi

echo -e "${YELLOW}Step 3: Updating Dart class names...${NC}"
# Replace LearnerProfile with StudentProfile (not LearnershipProfile)
find lib -type f -name "*.dart" -exec sed -i 's/\bLearnerProfile\b/StudentProfile/g' {} +

# Replace LearnerDashboard with StudentDashboard
find lib -type f -name "*.dart" -exec sed -i 's/\bLearnerDashboard\b/StudentDashboard/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/\bEnhancedLearnerDashboard\b/EnhancedStudentDashboard/g' {} +

echo -e "${YELLOW}Step 4: Updating API endpoint URLs...${NC}"
# Replace API endpoint paths
find lib -type f -name "*.dart" -exec sed -i 's|/api/v1/learner-portal|/api/v1/student-portal|g' {} +
find lib -type f -name "*.dart" -exec sed -i "s|'learner-portal'|'student-portal'|g" {} +
find lib -type f -name "*.dart" -exec sed -i 's|"learner-portal"|"student-portal"|g' {} +

# Update base URL constants
find lib -type f -name "*api_service.dart" -exec sed -i 's|learner-portal|student-portal|g' {} +

echo -e "${YELLOW}Step 5: Updating route names...${NC}"
# Update route paths
find lib -type f -name "*.dart" -exec sed -i "s|'/learner/dashboard'|'/student/dashboard'|g" {} +
find lib -type f -name "*.dart" -exec sed -i "s|'/learners'|'/students'|g" {} +

# Update route names (GoRouter)
find lib -type f -name "*.dart" -exec sed -i "s|'learner-dashboard'|'student-dashboard'|g" {} +
find lib -type f -name "*.dart" -exec sed -i 's|"learner-dashboard"|"student-dashboard"|g' {} +
find lib -type f -name "*.dart" -exec sed -i "s|name: 'learners'|name: 'students'|g" {} +

echo -e "${YELLOW}Step 6: Updating UserRole enum...${NC}"
# Update UserRole enum (but preserve the enum value for backward compatibility)
find lib -type f -name "*.dart" -exec sed -i 's/enum UserRole { learner,/enum UserRole { student,/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/UserRole\.learner/UserRole.student/g' {} +

echo -e "${YELLOW}Step 7: Updating UI text and labels...${NC}"
# Update UI strings from "Learner" to "Student" (but not "Learnership")
find lib -type f -name "*.dart" -exec sed -i 's/"Learner Portal"/"Student Portal"/g' {} +
find lib -type f -name "*.dart" -exec sed -i "s/'Learner Portal'/'Student Portal'/g" {} +
find lib -type f -name "*.dart" -exec sed -i 's/"Learner management"/"Student management"/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/"My Learners"/"My Students"/g' {} +
find lib -type f -name "*.dart" -exec sed -i "s/'My Learners'/'My Students'/g" {} +
find lib -type f -name "*.dart" -exec sed -i 's/"Active Learners"/"Active Students"/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/"At-Risk Learners"/"At-Risk Students"/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/"Add Learner"/"Add Student"/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/"Help learners succeed"/"Help students succeed"/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/"Review learner feedback"/"Review student feedback"/g' {} +

# Update role designation strings
find lib -type f -name "*.dart" -exec sed -i 's/designation: "Learner"/designation: "Student"/g' {} +
find lib -type f -name "*.dart" -exec sed -i "s/designation: 'Learner'/designation: 'Student'/g" {} +
find lib -type f -name "*.dart" -exec sed -i 's/role == "learner"/role == "student"/g' {} +
find lib -type f -name "*.dart" -exec sed -i "s/role == 'learner'/role == 'student'/g" {} +

echo -e "${YELLOW}Step 8: Updating import statements...${NC}"
# Update import paths
find lib -type f -name "*.dart" -exec sed -i 's|learner_portal/|student_portal/|g' {} +
find lib -type f -name "*.dart" -exec sed -i 's|learner_profile\.dart|student_profile.dart|g' {} +
find lib -type f -name "*.dart" -exec sed -i 's|learner_dashboard\.dart|student_dashboard.dart|g' {} +
find lib -type f -name "*.dart" -exec sed -i 's|learner_portal_api_service|student_portal_api_service|g' {} +

echo -e "${YELLOW}Step 9: Updating comments and documentation...${NC}"
# Update comments (but not learnership-related)
find lib -type f -name "*.dart" -exec sed -i 's|// Learner Portal|// Student Portal|g' {} +
find lib -type f -name "*.dart" -exec sed -i 's|/// Learner Portal|/// Student Portal|g' {} +
find lib -type f -name "*.dart" -exec sed -i 's|// Learner|// Student|g' {} +
find lib -type f -name "*.dart" -exec sed -i 's|/// Learner profile|/// Student profile|g' {} +

# Update markdown documentation
find . -type f -name "*.md" -exec sed -i 's/Learner Portal/Student Portal/g' {} +
find . -type f -name "*.md" -exec sed -i 's/learner portal/student portal/g' {} +
find . -type f -name "*.md" -exec sed -i 's/learner-portal/student-portal/g' {} +
find . -type f -name "*.md" -exec sed -i 's/\`learner\`/\`student\`/g' {} +

echo -e "${YELLOW}Step 10: Updating variable names...${NC}"
# Update variable names (be careful with these)
find lib -type f -name "*.dart" -exec sed -i 's/\blearnerProfile\b/studentProfile/g' {} +
find lib -type f -name "*.dart" -exec sed -i 's/\blearnerDashboard\b/studentDashboard/g' {} +

echo -e "${YELLOW}Step 11: Updating RESPONSIVE_DESIGN.md and THEME_INTEGRATION.md...${NC}"
# Update the responsive design and theme integration documentation
if [ -f "RESPONSIVE_DESIGN.md" ]; then
    sed -i 's/Learner Portal/Student Portal/g' RESPONSIVE_DESIGN.md
    sed -i 's/learner portal/student portal/g' RESPONSIVE_DESIGN.md
    sed -i 's/learner_portal/student_portal/g' RESPONSIVE_DESIGN.md
    echo "✓ Updated RESPONSIVE_DESIGN.md"
fi

if [ -f "THEME_INTEGRATION.md" ]; then
    sed -i 's/Learner Portal/Student Portal/g' THEME_INTEGRATION.md
    sed -i 's/learner portal/student portal/g' THEME_INTEGRATION.md
    sed -i 's/learner_portal/student_portal/g' THEME_INTEGRATION.md
    echo "✓ Updated THEME_INTEGRATION.md"
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Frontend renaming complete!${NC}"
echo -e "${GREEN}=========================================${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Run: flutter pub get"
echo "2. Fix any import errors: flutter analyze"
echo "3. Run tests: flutter test"
echo "4. Run app: flutter run"

echo -e "\n${YELLOW}Important notes:${NC}"
echo "- Directory names changed: learner_portal → student_portal"
echo "- File names changed: *learner* → *student*"
echo "- API endpoints changed: /api/v1/learner-portal/ → /api/v1/student-portal/"
echo "- Route names changed: /learner/dashboard → /student/dashboard"
echo "- 'Learnership' terminology has been preserved"
echo "- Update backend API URLs to match"

echo -e "\n${YELLOW}Files to manually review:${NC}"
echo "- lib/src/core/navigation/app_router.dart (route definitions)"
echo "- lib/src/core/api/api_client.dart (base URL)"
echo "- Any hardcoded 'learner' strings in configuration"
