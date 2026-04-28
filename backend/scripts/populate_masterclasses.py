import os
import django
from datetime import datetime, date

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.masterclasses.models import Masterclass
from apps.aicerts_courses.models import AiCertsCourse
from django.utils.text import slugify

# Data from HOSI ACADEMY — AiCerts® Masterclass Calendar 2026 / 2027
# Month, Country, Stream, Category, Course Name, Start, End, Duration (Days)
MASTERCLASS_DATA = [
    # MAY 2026
    ("May", "ZW", "professional", "AI Business", "AI+ Finance™", "2026-05-18", "2026-05-20", 3),
    ("May", "KE", "professional", "AI Business", "AI+ Finance™", "2026-05-11", "2026-05-13", 3),
    ("May", "ZW", "technical", "AI Development", "AI+ Developer™", "2026-05-25", "2026-05-29", 5),
    ("May", "KE", "technical", "AI Development", "AI+ Developer™", "2026-05-18", "2026-05-22", 5),
    ("May", "ZM", "professional", "AI Business", "AI+ Finance™", "2026-05-25", "2026-05-27", 3),
    
    # JUNE 2026
    ("June", "ZW", "professional", "AI Business", "AI+ Human Resources™", "2026-06-01", "2026-06-03", 3),
    ("June", "KE", "technical", "AI Development", "AI+ Engineer™", "2026-06-15", "2026-06-19", 5),
    ("June", "ZW", "technical", "AI Development", "AI+ Engineer™", "2026-06-08", "2026-06-12", 5),
    ("June", "ZM", "professional", "AI Business", "AI+ Human Resources™", "2026-06-08", "2026-06-10", 3),
    ("June", "ZM", "technical", "AI Development", "AI+ Engineer™", "2026-06-22", "2026-06-26", 5),
    
    # JULY 2026
    ("July", "ZW", "professional", "AI Business", "AI+ Supply Chain™", "2026-07-06", "2026-07-08", 3),
    ("July", "KE", "professional", "AI Business", "AI+ Supply Chain™", "2026-07-13", "2026-07-15", 3),
    ("July", "ZW", "technical", "AI Development", "AI+ Vibe Coder™", "2026-07-20", "2026-07-24", 5),
    ("July", "KE", "technical", "AI Development", "AI+ Vibe Coder™", "2026-07-13", "2026-07-17", 5),
    ("July", "ZM", "professional", "AI Business", "AI+ Supply Chain™", "2026-07-20", "2026-07-22", 3),
    ("July", "ZM", "technical", "AI Development", "AI+ Vibe Coder™", "2026-07-27", "2026-07-31", 5),

    # AUGUST 2026
    ("August", "ZW", "professional", "AI Business", "AI+ Project Management Office Practitioner™", "2026-08-10", "2026-08-12", 3),
    ("August", "KE", "professional", "AI Business", "AI+ Project Management Office Practitioner™", "2026-08-03", "2026-08-05", 3),
    ("August", "ZW", "professional", "AI Business", "AI+ Project Management Practitioner™", "2026-08-17", "2026-08-19", 3),
    ("August", "KE", "professional", "AI Business", "AI+ Project Management Practitioner™", "2026-08-10", "2026-08-12", 3),
    ("August", "ZM", "professional", "AI Business", "AI+ Project Management Office Practitioner™", "2026-08-17", "2026-08-19", 3),
    ("August", "ZW", "technical", "AI Development", "AI+ Prompt Engineer Level 2™", "2026-08-24", "2026-08-28", 5),
    ("August", "KE", "technical", "AI Development", "AI+ Prompt Engineer Level 2™", "2026-08-17", "2026-08-21", 5),
    ("August", "ZM", "professional", "AI Business", "AI+ Project Management Practitioner™", "2026-08-24", "2026-08-26", 3),
    ("August", "ZM", "technical", "AI Development", "AI+ Prompt Engineer Level 2™", "2026-08-31", "2026-09-04", 5),
    
    # SEPTEMBER 2026
    ("September", "ZW", "professional", "AI Business", "AI+ Agile Project Management Fundamentals™", "2026-09-07", "2026-09-09", 3),
    ("September", "KE", "professional", "AI Business", "AI+ Agile Project Management Fundamentals™", "2026-08-31", "2026-09-02", 3),
    ("September", "ZW", "professional", "AI Business", "AI+ Program Director – Practitioner™", "2026-09-14", "2026-09-16", 3),
    ("September", "KE", "professional", "AI Business", "AI+ Program Director – Practitioner™", "2026-09-07", "2026-09-09", 3),
    ("September", "ZM", "professional", "AI Business", "AI+ Agile Project Management Fundamentals™", "2026-09-14", "2026-09-16", 3),
    ("September", "ZW", "technical", "AI Development", "AI+ Context Engineering™", "2026-09-21", "2026-09-25", 5),
    ("September", "KE", "technical", "AI Development", "AI+ Context Engineering™", "2026-09-14", "2026-09-18", 5),
    ("September", "ZM", "professional", "AI Business", "AI+ Program Director – Practitioner™", "2026-09-21", "2026-09-23", 3),
    ("September", "ZM", "technical", "AI Development", "AI+ Context Engineering™", "2026-09-28", "2026-10-02", 5),

    # OCTOBER 2026
    ("October", "ZW", "professional", "AI Business", "AI+ Legal Agent™", "2026-10-10", "2026-10-12", 3),
    ("October", "KE", "professional", "AI Business", "AI+ Legal Agent™", "2026-10-05", "2026-10-07", 3),
    ("October", "ZW", "professional", "AI Business", "AI+ Real Estate™", "2026-10-19", "2026-10-21", 3),
    ("October", "KE", "professional", "AI Business", "AI+ Real Estate™", "2026-10-12", "2026-10-14", 3),
    ("October", "ZM", "professional", "AI Business", "AI+ Legal Agent™", "2026-10-19", "2026-10-21", 3),
    ("October", "ZW", "technical", "AI Security", "AI+ Security Level 2™", "2026-10-26", "2026-10-30", 5),
    ("October", "KE", "technical", "AI Security", "AI+ Security Level 2™", "2026-10-19", "2026-10-23", 5),
    ("October", "ZM", "professional", "AI Business", "AI+ Real Estate™", "2026-10-26", "2026-10-28", 3),
    ("October", "ZM", "technical", "AI Security", "AI+ Security Level 2™", "2026-11-02", "2026-11-06", 5),

    # NOVEMBER 2026
    ("November", "ZW", "professional", "AI Business", "AI+ Sales Agent™", "2026-11-09", "2026-11-11", 3),
    ("November", "KE", "professional", "AI Business", "AI+ Sales Agent™", "2026-11-02", "2026-11-04", 3),
    ("November", "ZW", "professional", "AI Business", "AI+ Marketing Agent™", "2026-11-16", "2026-11-18", 3),
    ("November", "KE", "professional", "AI Business", "AI+ Marketing Agent™", "2026-11-09", "2026-11-11", 3),
    ("November", "ZM", "professional", "AI Business", "AI+ Sales Agent™", "2026-11-16", "2026-11-18", 3),
    ("November", "ZW", "technical", "AI Security", "AI+ Security Level 3™", "2026-11-23", "2026-11-27", 5),
    ("November", "KE", "technical", "AI Security", "AI+ Security Level 3™", "2026-11-16", "2026-11-20", 5),
    ("November", "ZM", "professional", "AI Business", "AI+ Marketing Agent™", "2026-11-23", "2026-11-25", 3),
    ("November", "ZM", "technical", "AI Security", "AI+ Security Level 3™", "2026-11-30", "2026-12-04", 5),

    # DECEMBER 2026
    ("December", "ZW", "professional", "AI Business", "AI+ Customer Service Agent™", "2026-12-01", "2026-12-03", 3),
    ("December", "KE", "professional", "AI Business", "AI+ Customer Service Agent™", "2026-11-24", "2026-11-26", 3),
    ("December", "ZW", "professional", "AI Business", "AI+ Product Manager™", "2026-12-08", "2026-12-10", 3),
    ("December", "KE", "professional", "AI Business", "AI+ Product Manager™", "2026-12-01", "2026-12-03", 3),
    ("December", "ZM", "professional", "AI Business", "AI+ Customer Service Agent™", "2026-12-08", "2026-12-10", 3),
    ("December", "ZW", "technical", "AI Security", "AI+ Security Level 3™", "2026-12-15", "2026-12-19", 5),
    ("December", "KE", "technical", "AI Security", "AI+ Security Level 3™", "2026-12-08", "2026-12-12", 5),
    ("December", "ZM", "professional", "AI Business", "AI+ Product Manager™", "2026-12-15", "2026-12-17", 3),
    ("December", "ZM", "technical", "AI Security", "AI+ Security Level 3™", "2026-12-22", "2026-12-26", 5),
    
    # JANUARY 2027
    ("January", "ZW", "professional", "AI Business", "AI+ Ethics™", "2027-01-11", "2027-01-13", 3),
    ("January", "KE", "professional", "AI Business", "AI+ Ethics™", "2027-01-04", "2027-01-06", 3),
    ("January", "ZW", "professional", "AI Business", "AI+ Writer™", "2027-01-18", "2027-01-20", 3),
    ("January", "KE", "professional", "AI Business", "AI+ Writer™", "2027-01-11", "2027-01-13", 3),
    ("January", "ZM", "professional", "AI Business", "AI+ Ethics™", "2027-01-18", "2027-01-20", 3),
    ("January", "ZW", "technical", "AI Security", "AI+ Security Compliance™", "2027-01-25", "2027-01-29", 5),
    ("January", "KE", "technical", "AI Security", "AI+ Security Compliance™", "2027-01-18", "2027-01-22", 5),
    ("January", "ZM", "professional", "AI Business", "AI+ Writer™", "2027-01-25", "2027-01-27", 3),
    ("January", "ZM", "technical", "AI Security", "AI+ Security Compliance™", "2027-02-01", "2027-02-05", 5),
    
    # FEBRUARY 2027
    ("February", "ZW", "professional", "AI Business", "AI+ Researcher™", "2027-02-08", "2027-02-10", 3),
    ("February", "KE", "professional", "AI Business", "AI+ Researcher™", "2027-02-01", "2027-02-03", 3),
    ("February", "ZW", "professional", "AI Business", "AI+ Chief AI Officer™", "2027-02-15", "2027-02-17", 3),
    ("February", "KE", "professional", "AI Business", "AI+ Chief AI Officer™", "2027-02-08", "2027-02-10", 3),
    ("February", "ZM", "professional", "AI Business", "AI+ Researcher™", "2027-02-15", "2027-02-17", 3),
    ("February", "ZW", "technical", "AI Security", "AI+ Network™", "2027-02-22", "2027-02-26", 5),
    ("February", "KE", "technical", "AI Security", "AI+ Network™", "2027-02-15", "2027-02-19", 5),
    ("February", "ZM", "professional", "AI Business", "AI+ Chief AI Officer™", "2027-02-22", "2027-02-24", 3),
    ("February", "ZM", "technical", "AI Security", "AI+ Network™", "2027-03-01", "2027-03-05", 5),

    # MARCH 2027
    ("March", "ZW", "professional", "AI Specialisation", "AI+ Government™", "2027-03-08", "2027-03-10", 3),
    ("March", "KE", "professional", "AI Specialisation", "AI+ Government™", "2027-03-01", "2027-03-03", 3),
    ("March", "ZW", "professional", "AI Specialisation", "AI+ Policy Maker™", "2027-03-15", "2027-03-17", 3),
    ("March", "KE", "professional", "AI Specialisation", "AI+ Policy Maker™", "2027-03-08", "2027-03-10", 3),
    ("March", "ZM", "professional", "AI Specialisation", "AI+ Government™", "2027-03-15", "2027-03-17", 3),
    ("March", "ZW", "technical", "AI Security", "AI+ Ethical Hacker™", "2027-03-22", "2027-03-26", 5),
    ("March", "KE", "technical", "AI Security", "AI+ Ethical Hacker™", "2027-03-15", "2027-03-19", 5),
    ("March", "ZM", "professional", "AI Specialisation", "AI+ Policy Maker™", "2027-03-22", "2027-03-24", 3),
    ("March", "ZM", "technical", "AI Security", "AI+ Ethical Hacker™", "2027-03-29", "2027-04-02", 5),

    # APRIL 2027
    ("April", "ZW", "professional", "AI Specialisation", "AI+ Mining™", "2027-04-05", "2027-04-07", 3),
    ("April", "KE", "professional", "AI Specialisation", "AI+ Mining™", "2027-03-29", "2027-03-31", 3),
    ("April", "ZW", "professional", "AI Specialisation", "AI+ Telecommunications™", "2027-04-12", "2027-04-14", 3),
    ("April", "KE", "professional", "AI Specialisation", "AI+ Telecommunications™", "2027-04-05", "2027-04-07", 3),
    ("April", "ZM", "professional", "AI Specialisation", "AI+ Mining™", "2027-04-12", "2027-04-14", 3),
    ("April", "ZW", "technical", "AI Security", "Executive introduction to BSAF", "2027-04-19", "2027-04-21", 3),
    ("April", "KE", "technical", "AI Security", "Executive introduction to BSAF", "2027-04-12", "2027-04-14", 3),
    ("April", "ZM", "professional", "AI Specialisation", "AI+ Telecommunications™", "2027-04-19", "2027-04-21", 3),
    ("April", "ZM", "technical", "AI Security", "Executive introduction to BSAF", "2027-04-26", "2027-04-28", 3),
]

def run():
    print(f"Starting population of {len(MASTERCLASS_DATA)} masterclasses...")
    
    count = 0
    for month, country, stream, category, course_name, start_str, end_str, duration in MASTERCLASS_DATA:
        start_date = datetime.strptime(start_str, '%Y-%m-%d').date()
        end_date = datetime.strptime(end_str, '%Y-%m-%d').date()
        
        # Create title
        title = f"{course_name} Masterclass ({country})"
        
        # Create slug
        slug = slugify(f"{title} {start_str} {country}")
        
        # Check if already exists
        if Masterclass.objects.filter(slug=slug).exists():
            print(f"Skipping {title} - already exists")
            continue
            
        # Try to find matching AICERTS course
        course = AiCertsCourse.objects.filter(title__icontains=course_name.replace('™', '')).first()
        
        # Create Masterclass
        m = Masterclass.objects.create(
            title=title,
            slug=slug,
            description=f"Hosi Academy {stream.capitalize()} Masterclass: {course_name} in {country}. Category: {category}.",
            stream_type=stream,
            country_code=country,
            city="Regional Hub", # Default city
            start_date=start_date,
            end_date=end_date,
            price_physical=1000.00,
            price_online=500.00,
            status='scheduled',
            notes=f"Automatically populated from 2026/2027 Calendar. Duration: {duration} days."
        )
        
        if course:
            m.provider_courses.add(course)
            m.save() # Trigger category auto-population
            
        count += 1
        
    print(f"Successfully populated {count} masterclasses!")

if __name__ == "__main__":
    run()
