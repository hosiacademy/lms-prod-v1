#!/usr/bin/env python3
"""Add HR Admin ↔ Instructor ↔ Student relationships to PostgreSQL database"""

import subprocess

SQL_COMMANDS = """
-- Add hr_admin_id column to instructors table
ALTER TABLE instructors ADD COLUMN IF NOT EXISTS hr_admin_id BIGINT;
ALTER TABLE instructors ADD COLUMN IF NOT EXISTS assignment_date DATE DEFAULT CURRENT_DATE;
ALTER TABLE instructors ADD COLUMN IF NOT EXISTS assignment_type VARCHAR(50) DEFAULT 'country_based';
ALTER TABLE instructors ADD COLUMN IF NOT EXISTS assignment_notes TEXT;

-- Add foreign key constraint for hr_admin_id (links to administrators.id)
ALTER TABLE instructors 
ADD CONSTRAINT fk_instructors_hr_admin 
FOREIGN KEY (hr_admin_id) 
REFERENCES administrators(id) 
ON DELETE SET NULL;

-- Create index for hr_admin lookup
CREATE INDEX IF NOT EXISTS idx_instructors_hr_admin ON instructors(hr_admin_id);
CREATE INDEX IF NOT EXISTS idx_instructors_assignment_type ON instructors(assignment_type);

-- Update existing instructors to have HR Admins based on their provider/country
-- For now, assign to the first HR Admin who can manage their country
UPDATE instructors i
SET hr_admin_id = (
    SELECT a.id 
    FROM administrators a
    JOIN admin_country_access aca ON aca.admin_role_id = (
        SELECT ar.id 
        FROM admin_roles ar 
        WHERE ar.user_id = a.user_id 
        AND ar.role_type LIKE '%hr%' 
        LIMIT 1
    )
    WHERE a.is_hr_admin = true
    LIMIT 1
)
WHERE hr_admin_id IS NULL;

-- Add country_id to instructors table for HR Admin assignment by country
ALTER TABLE instructors ADD COLUMN IF NOT EXISTS assignment_country_id BIGINT;
ALTER TABLE instructors 
ADD CONSTRAINT fk_instructors_assignment_country 
FOREIGN KEY (assignment_country_id) 
REFERENCES localization_countries(id) 
ON DELETE SET NULL;

-- Create table for HR Admin country assignments
CREATE TABLE IF NOT EXISTS hr_admin_country_assignments (
    id BIGSERIAL PRIMARY KEY,
    hr_admin_id BIGINT NOT NULL REFERENCES administrators(id) ON DELETE CASCADE,
    country_id BIGINT NOT NULL REFERENCES localization_countries(id),
    region_scope VARCHAR(50) DEFAULT 'country',
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    assigned_by_id BIGINT REFERENCES users(id),
    assignment_reason TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    deactivated_at TIMESTAMP WITH TIME ZONE,
    deactivated_by_id BIGINT REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(hr_admin_id, country_id)
);

-- Create indexes for HR Admin assignments
CREATE INDEX IF NOT EXISTS idx_hr_admin_assignments_hr_admin ON hr_admin_country_assignments(hr_admin_id);
CREATE INDEX IF NOT EXISTS idx_hr_admin_assignments_country ON hr_admin_country_assignments(country_id);
CREATE INDEX IF NOT EXISTS idx_hr_admin_assignments_active ON hr_admin_country_assignments(is_active);

-- Create view for instructor-HR Admin relationships
CREATE OR REPLACE VIEW instructor_hr_assignments AS
SELECT 
    i.id AS instructor_id,
    i.instructor_id AS instructor_code,
    i.instructor_type,
    i.user_id AS instructor_user_id,
    i.hr_admin_id,
    a.admin_id AS hr_admin_code,
    a.user_id AS hr_admin_user_id,
    i.assignment_date,
    i.assignment_type,
    i.assignment_country_id,
    c.name AS assignment_country,
    i.assignment_notes,
    i.is_available,
    i.max_courses,
    i.total_students_taught
FROM instructors i
LEFT JOIN administrators a ON i.hr_admin_id = a.id
LEFT JOIN localization_countries c ON i.assignment_country_id = c.id
WHERE i.is_active = true;

-- Function to auto-assign instructor to HR Admin by country
CREATE OR REPLACE FUNCTION assign_instructor_to_hr_admin(
    p_instructor_id BIGINT,
    p_country_id BIGINT
) RETURNS BIGINT AS $$
DECLARE
    v_hr_admin_id BIGINT;
BEGIN
    -- Find HR Admin with access to the country
    SELECT a.id INTO v_hr_admin_id
    FROM administrators a
    JOIN admin_roles ar ON ar.user_id = a.user_id
    JOIN admin_country_access aca ON aca.admin_role_id = ar.id
    WHERE a.is_hr_admin = true 
    AND aca.country_id = p_country_id
    AND aca.is_active = true
    ORDER BY ar.assigned_at DESC
    LIMIT 1;
    
    -- If found, assign to instructor
    IF v_hr_admin_id IS NOT NULL THEN
        UPDATE instructors 
        SET hr_admin_id = v_hr_admin_id,
            assignment_country_id = p_country_id,
            assignment_date = CURRENT_DATE,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_instructor_id;
    END IF;
    
    RETURN v_hr_admin_id;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_instructors_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_instructors_updated_at ON instructors;
CREATE TRIGGER update_instructors_updated_at
    BEFORE UPDATE ON instructors
    FOR EACH ROW
    EXECUTE FUNCTION update_instructors_updated_at();

-- View for HR Admin dashboard
CREATE OR REPLACE VIEW hr_admin_dashboard AS
SELECT 
    a.id AS hr_admin_id,
    a.admin_id AS hr_admin_code,
    u.email AS hr_admin_email,
    CONCAT(u.first_name, ' ', u.last_name) AS hr_admin_name,
    COUNT(DISTINCT i.id) AS assigned_instructors,
    COUNT(DISTINCT s.id) AS managed_students,
    COUNT(DISTINCT hca.country_id) AS countries_managed,
    SUM(i.total_courses_taught) AS total_courses_managed,
    SUM(i.total_students_taught) AS total_students_managed,
    AVG(i.completion_rate) AS avg_completion_rate,
    AVG(i.average_student_rating) AS avg_student_rating
FROM administrators a
JOIN users u ON a.user_id = u.id
LEFT JOIN instructors i ON a.id = i.hr_admin_id AND i.is_active = true
LEFT JOIN students s ON i.id = s.instructor_id
LEFT JOIN hr_admin_country_assignments hca ON a.id = hca.hr_admin_id AND hca.is_active = true
WHERE a.is_hr_admin = true
GROUP BY a.id, a.admin_id, u.email, u.first_name, u.last_name;
"""

def run_sql_in_docker():
    """Run SQL commands in PostgreSQL Docker container"""
    try:
        # Run SQL commands through docker exec
        cmd = [
            'docker', 'exec', 'lms_db',
            'psql', '-U', 'postgres', '-d', 'hosiacademylms', '-c', SQL_COMMANDS
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Successfully added HR Admin relationships to database")
            print(result.stdout)
        else:
            print("❌ Failed to execute SQL commands")
            print("STDOUT:", result.stdout)
            print("STDERR:", result.stderr)
            
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    print("Adding HR Admin ↔ Instructor ↔ Student relationships...")
    run_sql_in_docker()