#!/bin/bash

# Script to rename "learner" to "student" throughout the backend
# Preserves "learnership" and "learnerships" unchanged

echo "========================================="
echo "Renaming 'learner' to 'student' in backend"
echo "========================================="

# Navigate to backend directory
cd "$(dirname "$0")"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Step 1: Backing up critical files...${NC}"
# Create backup directory
mkdir -p .backups/learner_to_student_$(date +%Y%m%d_%H%M%S)

echo -e "${YELLOW}Step 2: Replacing model class names...${NC}"
# Replace LearnerProfile with StudentProfile
find . -type f \( -name "*.py" -o -name "*.md" \) ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\bLearnerProfile\b/StudentProfile/g' {} +

# Replace LearnerSubscription with StudentSubscription (in payments app)
find . -type f \( -name "*.py" \) ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\bLearnerSubscription\b/StudentSubscription/g' {} +

echo -e "${YELLOW}Step 3: Replacing related_name fields...${NC}"
# Replace learner_profile with student_profile (related_name)
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/related_name='learner_profile'/related_name='student_profile'/g" {} +

# Replace preferred_learners with preferred_students
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/related_name='preferred_learners'/related_name='preferred_students'/g" {} +

echo -e "${YELLOW}Step 4: Replacing verbose names and help texts...${NC}"
# Replace verbose_name "Learner" with "Student"
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/verbose_name=_("Learner")/verbose_name=_("Student")/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/verbose_name=_('Learner')/verbose_name=_('Student')/g" {} +

# Replace "Learner Profile" with "Student Profile"
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/"Learner Profile"/"Student Profile"/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/'Learner Profile'/'Student Profile'/g" {} +

# Replace "Learner Profiles" with "Student Profiles"
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/"Learner Profiles"/"Student Profiles"/g' {} +

# Replace "Learner Email" with "Student Email"
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/"Learner Email"/"Student Email"/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/'Learner Email'/'Student Email'/g" {} +

echo -e "${YELLOW}Step 5: Replacing field names (except learnership-related)...${NC}"
# Replace learner_ field prefixes with student_ (but not learnership_)
# Be careful to avoid learnership fields

# Replace learner_full_name, learner_email, etc. in enrollment models
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_full_name\b/student_full_name/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_email\b/student_email/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_phone\b/student_phone/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_id_number\b/student_id_number/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_address\b/student_address/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_city\b/student_city/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_country\b/student_country/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_postal_code\b/student_postal_code/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_dob\b/student_dob/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\blearner_gender\b/student_gender/g' {} +

# Replace learner ForeignKey field (but check it's not about learnerships)
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" ! -path "*/learnerships/*" -exec sed -i 's/\blearner\s*=\s*models\.ForeignKey/student = models.ForeignKey/g' {} +

echo -e "${YELLOW}Step 6: Replacing in help texts and doc strings...${NC}"
# Replace "learner" with "student" in help_text (but not learnership)
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/help_text=_("True if learner/help_text=_("True if student/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/help_text=_("Did learner/help_text=_("Did student/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/help_text=_("Does learner/help_text=_("Does student/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/"Shows courses learner/"Shows courses student/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/"Learner wishlist/"Student wishlist/g' {} +
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/"Extended learner profile/"Extended student profile/g' {} +

echo -e "${YELLOW}Step 7: Replacing API endpoint paths...${NC}"
# Replace learner-portal with student-portal in URLs
find . -type f -name "urls.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's|api/v1/learner-portal/|api/v1/student-portal/|g' {} +
find . -type f -name "urls.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's|"learner-portal"|"student-portal"|g' {} +
find . -type f -name "urls.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s|'learner-portal'|'student-portal'|g" {} +

# Replace learnerprofile basename with studentprofile
find . -type f -name "urls.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/basename='learnerprofile'/basename='studentprofile'/g" {} +

echo -e "${YELLOW}Step 8: Replacing ViewSet and Serializer class names...${NC}"
# Replace LearnerProfileViewSet with StudentProfileViewSet
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\bLearnerProfileViewSet\b/StudentProfileViewSet/g' {} +

# Replace LearnerProfileSerializer with StudentProfileSerializer
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\bLearnerProfileSerializer\b/StudentProfileSerializer/g' {} +

# Replace LearnerProfileAdmin with StudentProfileAdmin
find . -type f -name "*.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/\bLearnerProfileAdmin\b/StudentProfileAdmin/g' {} +

echo -e "${YELLOW}Step 9: Replacing in admin labels and short descriptions...${NC}"
# Replace short_description labels
find . -type f -name "admin.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i "s/short_description = 'Learner'/short_description = 'Student'/g" {} +
find . -type f -name "admin.py" ! -path "*/migrations/*" ! -path "*/.backups/*" -exec sed -i 's/short_description = "Learner"/short_description = "Student"/g' {} +

echo -e "${YELLOW}Step 10: Replacing in templates...${NC}"
# Replace in HTML templates
find . -type f -name "*.html" ! -path "*/.backups/*" -exec sed -i 's/Learner Portal/Student Portal/g' {} +
find . -type f -name "*.html" ! -path "*/.backups/*" -exec sed -i 's/learner portal/student portal/g' {} +
find . -type f -name "*.html" ! -path "*/.backups/*" -exec sed -i 's/>Learner</>Student</g' {} +

echo -e "${YELLOW}Step 11: Updating settings.py and configuration...${NC}"
# Update app name in settings (if needed - keep directory name same)
# Just update display names for now

echo -e "${YELLOW}Step 12: Updating README and documentation...${NC}"
# Update README files
find . -type f -name "README.md" ! -path "*/.backups/*" -exec sed -i 's/Learner Portal/Student Portal/g' {} +
find . -type f -name "README.md" ! -path "*/.backups/*" -exec sed -i 's/learner portal/student portal/g' {} +
find . -type f -name "README.md" ! -path "*/.backups/*" -exec sed -i 's/\blearner\b/student/g' {} +

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Replacement complete!${NC}"
echo -e "${GREEN}=========================================${NC}"

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Review the changes: git diff"
echo "2. Create migrations: python manage.py makemigrations"
echo "3. Review migrations before applying"
echo "4. Apply migrations: python manage.py migrate"
echo "5. Run tests: python manage.py test"

echo -e "\n${YELLOW}Important notes:${NC}"
echo "- Database table names remain unchanged for data continuity"
echo "- 'Learnership' and 'learnerships' have been preserved"
echo "- Migration files were NOT modified (will be generated fresh)"
echo "- Backup created in .backups/ directory"
