import os
import django
import sys
from django.utils.text import slugify

# Force Supabase environment variables for this script
os.environ['DB_ENGINE'] = 'django.db.backends.postgresql'
os.environ['DB_NAME'] = 'postgres'
os.environ['DB_USER'] = 'postgres.zdfdazvblpblhafnkwrm'
os.environ['DB_PASSWORD'] = 'lms_prodHOSI1278'
os.environ['DB_HOST'] = 'aws-1-eu-central-1.pooler.supabase.com'
os.environ['DB_PORT'] = '5432'
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

# Add backend to path
sys.path.append('/home/takawira/lms-prod/backend')

try:
    django.setup()
    from apps.learnerships.models import LearnershipProgramme
except Exception as e:
    print(f'Setup failed: {e}')
    sys.exit(1)

def seed_learnerships():
    ai_category = 'AI & Blockchain'
    cyber_category = 'Cybersecurity'
    
    learnerships = [
        # AI & Blockchain
        {'title': 'AI Developer / Machine Learning Engineer Learnership', 'role': 'AI Developer / ML Engineer', 'nqf': '6', 'months': 9, 'status': 'open', 'category': ai_category},
        {'title': 'AI Engineer / Deep Learning Specialist Learnership', 'role': 'AI Engineer / DL Specialist', 'nqf': '7', 'months': 9, 'status': 'open', 'category': ai_category},
        {'title': 'Cloud AI Engineer / MLOps Specialist Learnership', 'role': 'Cloud AI Engineer / MLOps', 'nqf': '6', 'months': 9, 'status': 'closed', 'category': ai_category},
        {'title': 'Data Scientist / AI Data Engineer Learnership', 'role': 'Data Scientist / AI Data Engineer', 'nqf': '6', 'months': 9, 'status': 'open', 'category': ai_category},
        {'title': 'AI Security Engineer / Ethical Hacker Learnership', 'role': 'AI Security Engineer', 'nqf': '7', 'months': 9, 'status': 'closed', 'category': ai_category},
        {'title': 'Robotics AI Engineer Learnership', 'role': 'Robotics AI Engineer', 'nqf': '7', 'months': 9, 'status': 'closed', 'category': ai_category},
        {'title': 'Computer Vision Engineer Learnership', 'role': 'Computer Vision Engineer', 'nqf': '6', 'months': 9, 'status': 'open', 'category': ai_category},
        {'title': 'Natural Language Processing Engineer Learnership', 'role': 'NLP Engineer', 'nqf': '7', 'months': 9, 'status': 'closed', 'category': ai_category},
        {'title': 'Blockchain AI Developer Learnership', 'role': 'Blockchain AI Developer', 'nqf': '7', 'months': 9, 'status': 'open', 'category': ai_category},
        {'title': 'AI Quality Assurance / Testing Engineer Learnership', 'role': 'AI QA / Testing Engineer', 'nqf': '6', 'months': 9, 'status': 'open', 'category': ai_category},
        
        # Cybersecurity
        {'title': 'SOC Analyst Learnership 2026', 'role': 'SOC Analyst', 'nqf': '5', 'months': 12, 'status': 'open', 'category': cyber_category},
        {'title': 'Security Engineer Learnership 2026', 'role': 'Security Engineer', 'nqf': '5', 'months': 12, 'status': 'open', 'category': cyber_category},
        {'title': 'Security Consultant Learnership 2026', 'role': 'Security Consultant', 'nqf': '5', 'months': 12, 'status': 'open', 'category': cyber_category},
        {'title': 'Red Teamer Learnership 2026', 'role': 'Penetration Tester', 'nqf': '5', 'months': 12, 'status': 'open', 'category': cyber_category},
        {'title': 'Blue Teamer Learnership 2026', 'role': 'Cyber Defense Analyst', 'nqf': '5', 'months': 12, 'status': 'open', 'category': cyber_category},
        {'title': 'Bug Hunter Learnership 2026', 'role': 'Bug Bounty Hunter', 'nqf': '5', 'months': 12, 'status': 'closed', 'category': cyber_category},
    ]

    count = 0
    for data in learnerships:
        slug = slugify(data['title'])
        obj, created = LearnershipProgramme.objects.update_or_create(
            title=data['title'],
            defaults={
                'role': data['role'],
                'nqf_level': data['nqf'],
                'duration_months': data['months'],
                'status': data['status'],
                'category': data['category'],
                'active': True,
                'specialization': data['role'],
                'focus': data['role'],
                'country': 'South Africa',
                'city': 'Johannesburg',
                'cost_usd': 1500.0,
                'currency': 'USD',
                'slug': slug,
                'is_offered': True,
            }
        )
        count += 1
        
    print(f'Successfully seeded {count} learnerships into Supabase.')

if __name__ == '__main__':
    seed_learnerships()
