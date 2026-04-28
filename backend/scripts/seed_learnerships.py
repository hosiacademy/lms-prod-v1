import os
import django

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.learnerships.models import LearnershipProgramme

def seed_learnerships():
    ai_category = 'AI & Blockchain'
    cyber_category = 'Cybersecurity'
    
    learnerships = [
        # AI & Blockchain
        {'title': 'AI Developer / Machine Learning Engineer Learnership', 'role': 'AI Developer / ML Engineer', 'nqf_level': '6', 'duration': '9 months', 'status': 'Active', 'category': ai_category},
        {'title': 'AI Engineer / Deep Learning Specialist Learnership', 'role': 'AI Engineer / DL Specialist', 'nqf_level': '7', 'duration': '9 months', 'status': 'Active', 'category': ai_category},
        {'title': 'Cloud AI Engineer / MLOps Specialist Learnership', 'role': 'Cloud AI Engineer / MLOps', 'nqf_level': '6', 'duration': '9 months', 'status': 'Inactive', 'category': ai_category},
        {'title': 'Data Scientist / AI Data Engineer Learnership', 'role': 'Data Scientist / AI Data Engineer', 'nqf_level': '6', 'duration': '9 months', 'status': 'Active', 'category': ai_category},
        {'title': 'AI Security Engineer / Ethical Hacker Learnership', 'role': 'AI Security Engineer', 'nqf_level': '7', 'duration': '9 months', 'status': 'Inactive', 'category': ai_category},
        {'title': 'Robotics AI Engineer Learnership', 'role': 'Robotics AI Engineer', 'nqf_level': '7', 'duration': '9 months', 'status': 'Inactive', 'category': ai_category},
        {'title': 'Computer Vision Engineer Learnership', 'role': 'Computer Vision Engineer', 'nqf_level': '6', 'duration': '9 months', 'status': 'Active', 'category': ai_category},
        {'title': 'Natural Language Processing Engineer Learnership', 'role': 'NLP Engineer', 'nqf_level': '7', 'duration': '9 months', 'status': 'Inactive', 'category': ai_category},
        {'title': 'Blockchain AI Developer Learnership', 'role': 'Blockchain AI Developer', 'nqf_level': '7', 'duration': '9 months', 'status': 'Active', 'category': ai_category},
        {'title': 'AI Quality Assurance / Testing Engineer Learnership', 'role': 'AI QA / Testing Engineer', 'nqf_level': '6', 'duration': '9 months', 'status': 'Active', 'category': ai_category},
        
        # Cybersecurity
        {'title': 'SOC Analyst Learnership 2026', 'role': 'SOC Analyst', 'nqf_level': '5', 'duration': '12 months', 'status': 'Active', 'category': cyber_category},
        {'title': 'Security Engineer Learnership 2026', 'role': 'Security Engineer', 'nqf_level': '5', 'duration': '12 months', 'status': 'Active', 'category': cyber_category},
        {'title': 'Security Consultant Learnership 2026', 'role': 'Security Consultant', 'nqf_level': '5', 'duration': '12 months', 'status': 'Active', 'category': cyber_category},
        {'title': 'Red Teamer Learnership 2026', 'role': 'Penetration Tester', 'nqf_level': '5', 'duration': '12 months', 'status': 'Active', 'category': cyber_category},
        {'title': 'Blue Teamer Learnership 2026', 'role': 'Cyber Defense Analyst', 'nqf_level': '5', 'duration': '12 months', 'status': 'Active', 'category': cyber_category},
        {'title': 'Bug Hunter Learnership 2026', 'role': 'Bug Bounty Hunter', 'nqf_level': '5', 'duration': '12 months', 'status': 'Inactive', 'category': cyber_category},
    ]

    for data in learnerships:
        LearnershipProgramme.objects.update_or_create(
            title=data['title'],
            defaults={
                'role': data['role'],
                'nqf_level': data['nqf_level'],
                'duration': data['duration'],
                'status': data['status'],
                'category': data['category'],
                'active': data['status'] == 'Active',
                'specialization': data['role'],
                'focus': data['role'],
                'country': 'South Africa',
                'city': 'Johannesburg',
                'price': 1500.0,
                'currency': 'USD',
            }
        )
    print(f'Successfully seeded {len(learnerships)} learnerships.')

if __name__ == '__main__':
    seed_learnerships()
