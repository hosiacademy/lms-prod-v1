# apps/learnerships/management/commands/sync_locations.py
from django.core.management.base import BaseCommand
from django.db import connection, transaction
from django.utils import timezone

class Command(BaseCommand):
    help = 'Sync African Countries and Cities from legacy public tables to Django models with ID mapping'

    def handle(self, *args, **kwargs):
        with transaction.atomic():  # Ensure all or nothing
            with connection.cursor() as cursor:
                # Step 1: Clear existing data
                cursor.execute("DELETE FROM learnerships_africancity")
                cursor.execute("DELETE FROM learnerships_africancountry")

                # Step 2: Copy countries and map legacy ID → new Django ID
                cursor.execute("""
                    INSERT INTO learnerships_africancountry (code, name, created_at, updated_at)
                    SELECT code, name, NOW(), NOW() 
                    FROM african_countries
                    ON CONFLICT (code) DO UPDATE 
                    SET name = EXCLUDED.name, updated_at = NOW()
                    RETURNING id, code
                """)

                # Fetch the mapping: legacy code → new Django ID
                cursor.execute("SELECT id, code FROM learnerships_africancountry")
                country_map = {row[1]: row[0] for row in cursor.fetchall()}  # code → new ID

                self.stdout.write(self.style.SUCCESS(f'Synced {len(country_map)} African Countries'))

                # Step 3: Copy cities, remapping legacy country_id to new Django country ID
                cursor.execute("""
                    SELECT id, country_id, name 
                    FROM african_cities
                """)
                cities = cursor.fetchall()

                inserted = 0
                for legacy_id, legacy_country_id, name in cities:
                    # Find legacy country code from legacy country_id
                    cursor.execute("""
                        SELECT code FROM african_countries WHERE id = %s
                    """, [legacy_country_id])
                    legacy_code = cursor.fetchone()
                    if not legacy_code:
                        continue  # Skip invalid

                    legacy_code = legacy_code[0]
                    new_country_id = country_map.get(legacy_code)
                    if not new_country_id:
                        continue  # Skip if country not synced

                    # Insert city with new country ID
                    cursor.execute("""
                        INSERT INTO learnerships_africancity (country_id, name, created_at, updated_at)
                        VALUES (%s, %s, NOW(), NOW())
                        ON CONFLICT (country_id, name) DO UPDATE 
                        SET updated_at = NOW()
                    """, [new_country_id, name])
                    inserted += 1

                self.stdout.write(self.style.SUCCESS(f'Synced {inserted} African Cities'))

        self.stdout.write(self.style.SUCCESS('Location sync completed successfully!'))