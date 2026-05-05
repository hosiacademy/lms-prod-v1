import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.masterclasses.models import Masterclass

total = Masterclass.objects.count()
za_count = Masterclass.objects.filter(country_code='ZA').count()

print(f"Total Masterclasses: {total}")
print(f"South Africa Masterclasses: {za_count}")

for mc in Masterclass.objects.filter(country_code='ZA'):
    print(f" - {mc.title} in {mc.city} ({mc.start_date})")
