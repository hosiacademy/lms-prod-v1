# apps/learnerships/management/commands/sync_learnership_details.py
from django.core.management.base import BaseCommand
from django.utils.text import slugify
from apps.learnerships.models import LearnershipProgramme, LearnershipPhase, CertificationTrack, CertificationItem
from apps.learnerships.services.cybersecurity_pricing import CYBERSECURITY_LEARNERSHIPS
import datetime

class Command(BaseCommand):
    help = "Sync LearnershipProgramme details (cost, phases) with CertificationTrack data"

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS("Starting Learnership Details Sync..."))
        
        # Track mapping (slug in pricing file -> track name in DB)
        mapping = {
            'soc_analyst': 'SOC Analyst',
            'security_engineer': 'Security Engineer',
            'security_consultant': 'Security Consultant',
            'red_teamer': 'Red Teamer',
            'blue_teamer': 'Blue Teamer',
            'bug_hunter': 'Bug Hunter',
        }

        updated_count = 0
        phase_count = 0

        for pricing_slug, track_name in mapping.items():
            pricing_data = CYBERSECURITY_LEARNERSHIPS.get(pricing_slug)
            if not pricing_data:
                continue

            # Find matching track in DB to get the calculated sales_price
            track = CertificationTrack.objects.filter(name=track_name).first()
            if not track:
                self.stdout.write(self.style.WARNING(f"Track '{track_name}' not found in database. Skipping..."))
                continue

            # Find matching learnership programme
            # Try to match by title containing the role or track name
            programme = LearnershipProgramme.objects.filter(title__icontains=track_name).first()
            
            if not programme:
                # Try matching by role
                programme = LearnershipProgramme.objects.filter(role__icontains=pricing_data['role']).first()

            if not programme:
                self.stdout.write(self.style.WARNING(f"Programme for '{track_name}' not found. Skipping..."))
                continue

            # 1. Update Programme Details
            programme.cost_usd = track.sales_price
            programme.role = pricing_data['role']
            programme.duration_months = 12
            programme.duration_weeks = 52
            programme.currency = 'USD'
            programme.status = 'open'
            programme.active = True
            programme.is_offered = True
            
            # Update specialization if empty
            if not programme.specialization:
                programme.specialization = pricing_data['title']
            
            programme.save()
            updated_count += 1
            self.stdout.write(self.style.SUCCESS(f"Updated: {programme.title} -> ${programme.cost_usd}"))

            # 2. Sync Phases
            # Delete existing phases to avoid duplicates if re-run
            LearnershipPhase.objects.filter(programme=programme).delete()

            # Create new phases from pricing data
            for phase_key, phase_data in pricing_data['phases'].items():
                order = int(phase_key.split('_')[1])
                
                # Calculate dates (mock dates starting from June 2026)
                start_date = datetime.date(2026, 6, 1) + datetime.timedelta(weeks=(order-1)*16)
                end_date = start_date + datetime.timedelta(weeks=16) - datetime.timedelta(days=1)

                phase = LearnershipPhase.objects.create(
                    programme=programme,
                    name=phase_data['name'],
                    order=order,
                    start_date=start_date,
                    end_date=end_date,
                    duration_weeks=16,
                    description=f"Stage {order} of the {programme.title} certification track."
                )
                phase_count += 1
            
            self.stdout.write(self.style.SUCCESS(f"  - Created {len(pricing_data['phases'])} phases"))

        self.stdout.write(self.style.SUCCESS(f"\nSummary:"))
        self.stdout.write(f" - Programmes updated: {updated_count}")
        self.stdout.write(f" - Phases created: {phase_count}")
        self.stdout.write(self.style.SUCCESS("DONE: Learnership sync complete!"))
