from django.core.management.base import BaseCommand
from django.db import connection, transaction
from apps.localization.models import Country, State, City

class Command(BaseCommand):
    help = 'Sync legacy African Countries and Cities to hierarchical localization models'

    def handle(self, *args, **kwargs):
        self.stdout.write("Syncing legacy data to hierarchical models...")
        
        with transaction.atomic():
            with connection.cursor() as cursor:
                # 1. Sync Countries
                cursor.execute("SELECT code, name FROM african_countries")
                legacy_countries = cursor.fetchall()
                
                country_map = {} # legacy_code -> Django Country ID
                for code, name in legacy_countries:
                    country, created = Country.objects.get_or_create(
                        code=code,
                        defaults={'name': name, 'is_active': True}
                    )
                    country_map[code] = country.id
                
                self.stdout.write(self.style.SUCCESS(f"Synced {len(country_map)} Countries"))

                # 2. Sync Cities
                cursor.execute("""
                    SELECT c.code, ct.name 
                    FROM african_cities ct
                    JOIN african_countries c ON ct.country_id = c.id
                """)
                legacy_cities = cursor.fetchall()
                
                created_count = 0
                for country_code, city_name in legacy_cities:
                    country_id = country_map.get(country_code)
                    if not country_id:
                        continue
                        
                    # Find or create a default state for this country if no specific state mapping exists
                    # For now, we'll create a "Main" state for countries without states
                    country = Country.objects.get(id=country_id)
                    state = country.states.first()
                    if not state:
                        state, _ = State.objects.get_or_create(
                            country=country,
                            name=f"Main Region",
                            defaults={'code': 'MAIN'}
                        )
                    
                    # Create City
                    _, created = City.objects.get_or_create(
                        state=state,
                        name=city_name,
                        defaults={'is_active': True}
                    )
                    if created:
                        created_count += 1
                
                self.stdout.write(self.style.SUCCESS(f"Synced {created_count} new Cities from legacy data"))
        
        self.stdout.write(self.style.SUCCESS("Legacy sync completed successfully!"))
