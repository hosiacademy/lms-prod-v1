#!/bin/bash
# Create Takawira as default instructor directly in database

set -e

echo "Creating default instructor: Takawira..."

# Create user and instructor in one transaction
docker-compose exec -T db psql -U postgres -d hosiacademylms << 'EOF'
-- Start transaction
BEGIN;

-- Create user if not exists
INSERT INTO users (username, email, first_name, last_name, role_id, is_active, is_staff, is_superuser, date_joined)
SELECT 
    'takawira',
    'takawira@hosiacademy.africa',
    'Takawira',
    'Instructor',
    2,  -- Instructor role
    true,
    false,
    false,
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM users WHERE email = 'takawira@hosiacademy.africa'
);

-- Get the user ID
DO $$
DECLARE
    user_id BIGINT;
    instructor_id BIGINT;
BEGIN
    SELECT id INTO user_id FROM users WHERE email = 'takawira@hosiacademy.africa';
    
    -- Create instructor record
    INSERT INTO instructors (
        instructor_id,
        instructor_type,
        department,
        years_experience,
        is_available,
        max_courses,
        overall_rating,
        total_courses_taught,
        total_students_taught,
        average_student_rating,
        completion_rate,
        is_active,
        created_at,
        updated_at,
        user_id,
        instructor_user_id
    )
    SELECT
        'INST-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-001',
        'internal',
        'General',
        5,
        true,
        10,
        0.0,
        0,
        0,
        0.0,
        0.0,
        true,
        NOW(),
        NOW(),
        user_id,
        user_id
    WHERE NOT EXISTS (
        SELECT 1 FROM instructors WHERE user_id = user_id
    );
    
    RAISE NOTICE 'Default instructor Takawira created successfully!';
    RAISE NOTICE 'Email: takawira@hosiacademy.africa';
    RAISE NOTICE 'Note: Password is unset - set via admin panel';
END $$;

COMMIT;
EOF

echo ""
echo "✅ Default instructor created!"
echo ""
echo "To set password:"
echo "  1. Login to admin panel at http://localhost:7001/admin/"
echo "  2. Go to Users → takawira@hosiacademy.africa"
echo "  3. Click 'Change password' and set a password"
