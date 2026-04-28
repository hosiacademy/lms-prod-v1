"""
Re-classify AICERTS courses based on "Technical" and "Professional" keywords.

Technical courses: $420 (self-paced, online)
Professional courses: $250 (self-paced, online)

Classification priority:
1. Check for "Technical" or "Professional" in title/categories
2. Check for technical role keywords
3. Default to professional
"""
from django.db import migrations
from decimal import Decimal
import sys


def reclassify_courses(apps, schema_editor):
    """
    Re-classify all courses based on updated logic.
    """
    AiCertsCourse = apps.get_model('aicerts_courses', 'AiCertsCourse')
    
    updated_count = 0
    technical_count = 0
    professional_count = 0
    
    for course in AiCertsCourse.objects.all():
        lower_title = course.title.lower()
        lower_categories = course.category_name.lower() if course.category_name else ''
        combined = f"{lower_title} {lower_categories}"
        
        # PRIORITY 1: Check for explicit stream type keywords
        if 'technical' in lower_categories or 'technical' in lower_title:
            stream_type = 'technical'
        elif 'professional' in lower_categories or 'professional' in lower_title:
            stream_type = 'professional'
        else:
            # PRIORITY 2: Check for technical role keywords
            technical_keywords = [
                'developer', 'development', 'engineer', 'engineering', 'programming',
                'coding', 'implementation', 'devops', 'cloud architect',
                'security analyst', 'data scientist', 'machine learning engineer',
                'blockchain developer', 'ai developer', 'software', 'programmer',
                'full stack', 'backend', 'frontend', 'mobile developer',
                'cybersecurity', 'network security', 'penetration testing',
                'data analytics', 'business intelligence', 'data engineer',
                'robotics', 'automation engineer', 'ai implementation',
                'vibe coder', 'ai+ developer', 'blockchain', 'smart contracts',
                'quantum', 'system engineer', 'ai technical',
            ]
            
            stream_type = 'technical' if any(kw in combined for kw in technical_keywords) else 'professional'
        
        # Set pricing based on stream type
        if stream_type == 'technical':
            price = Decimal('420.00')
        else:
            price = Decimal('250.00')
        
        # Update if changed
        if course.stream_type != stream_type or course.price_individual != price:
            course.stream_type = stream_type
            course.price_individual = price
            course.save()
            updated_count += 1
        
        if stream_type == 'technical':
            technical_count += 1
        else:
            professional_count += 1
    
    print(f"Updated {updated_count} courses")
    print(f"Technical courses: {technical_count} @ $420.00")
    print(f"Professional courses: {professional_count} @ $250.00")
    print("\nPricing Structure (Self-Paced, Online Only):")
    print("-" * 60)
    print("Technical Courses:")
    print("  • Price: $420.00")
    print("\nProfessional Courses:")
    print("  • Price: $250.00")
    print("-" * 60)
    print("\nClassification Logic:")
    print("  1. Check for 'Technical'/'Professional' in title/categories")
    print("  2. Check for technical role keywords (developer, engineer, etc.)")
    print("  3. Default to professional")
    print("\nNote: All AICERTS courses are self-paced and online.")
    print("Prices stored directly in database - no discount calculations.")


def revert_classification(apps, schema_editor):
    """Revert to previous classification"""
    AiCertsCourse = apps.get_model('aicerts_courses', 'AiCertsCourse')
    AiCertsCourse.objects.all().update(
        stream_type='professional',
        price_individual=Decimal('250.00'),
    )


class Migration(migrations.Migration):

    dependencies = [
        ('aicerts_courses', '0005_add_stream_type_and_pricing'),
    ]

    operations = [
        migrations.RunPython(
            reclassify_courses,
            reverse_code=revert_classification
        ),
    ]
