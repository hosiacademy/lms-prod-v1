"""
Add stream_type field to AICERTS Courses and set pricing

Technical courses: $420 (self-paced, online)
Professional courses: $250 (self-paced, online)

No discounts - prices are stored directly in the database.
Currency conversion happens automatically based on user's IP location.
"""
from django.db import migrations, models
from decimal import Decimal


def add_stream_type_and_pricing(apps, schema_editor):
    """
    Add stream_type field and set pricing based on course classification.
    """
    AiCertsCourse = apps.get_model('aicerts_courses', 'AiCertsCourse')

    # Import the classification function - use absolute import
    from apps.aicerts_courses.services import classify_course_stream_type
    
    # Update all courses
    for course in AiCertsCourse.objects.all():
        stream_type = classify_course_stream_type(course.title, course.category_name)
        
        # Set pricing based on stream type
        if stream_type == 'technical':
            price = Decimal('420.00')
        else:  # professional
            price = Decimal('250.00')
        
        course.stream_type = stream_type
        course.price_individual = price
        course.save()
    
    technical_count = AiCertsCourse.objects.filter(stream_type='technical').count()
    professional_count = AiCertsCourse.objects.filter(stream_type='professional').count()
    
    print(f"Updated {technical_count} Technical courses to $420.00")
    print(f"Updated {professional_count} Professional courses to $250.00")
    print("\nPricing Structure (Self-Paced, Online Only):")
    print("-" * 60)
    print("Technical Courses:")
    print("  • Price: $420.00")
    print("\nProfessional Courses:")
    print("  • Price: $250.00")
    print("-" * 60)
    print("\nNote: All AICERTS courses are self-paced and online.")
    print("Prices stored directly in database - no discount calculations.")
    print("Currency conversion happens automatically based on user's IP location.")


def revert_stream_type_and_pricing(apps, schema_editor):
    """Revert to previous state"""
    AiCertsCourse = apps.get_model('aicerts_courses', 'AiCertsCourse')
    AiCertsCourse.objects.all().update(
        stream_type='professional',
        price_individual=Decimal('500.00'),
    )


class Migration(migrations.Migration):

    dependencies = [
        ('aicerts_courses', '0004_add_jpg_urls_and_ai_tools'),
    ]

    operations = [
        # Add stream_type field
        migrations.AddField(
            model_name='aicertscourse',
            name='stream_type',
            field=models.CharField(
                max_length=20,
                choices=[('technical', 'Technical'), ('professional', 'Professional')],
                default='professional',
                db_index=True,
                help_text="Stream type for pricing: Technical ($420) or Professional ($250)"
            ),
        ),
        # Run data update - set pricing based on stream type
        migrations.RunPython(
            add_stream_type_and_pricing,
            reverse_code=revert_stream_type_and_pricing
        ),
    ]
