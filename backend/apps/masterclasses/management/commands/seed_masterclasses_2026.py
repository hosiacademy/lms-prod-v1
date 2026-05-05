"""
Management command to seed the full HOSI Academy AICerts® Masterclass Calendar 2026/2027.
Zimbabwe · Kenya · Zambia | Starting 6 April 2026 → March 2027

Usage:
    python manage.py seed_masterclasses_2026
    python manage.py seed_masterclasses_2026 --clear   # delete existing and re-seed
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime

from apps.masterclasses.models import Masterclass


CALENDAR = [
    # (title, stream_type, country_name, country_code, city, start_date, end_date)
    # ── APRIL 2026 ──
    ("AI+ Finance™", "professional", "Zimbabwe", "ZW", "Harare", "2026-04-06", "2026-04-08"),
    ("AI+ Finance™", "professional", "Kenya",    "KE", "Nairobi", "2026-04-13", "2026-04-15"),
    ("AI+ Developer™", "technical", "Zimbabwe",  "ZW", "Harare", "2026-04-13", "2026-04-17"),
    ("AI+ Developer™", "technical", "Kenya",     "KE", "Nairobi", "2026-04-20", "2026-04-24"),
    ("AI+ Finance™", "professional", "Zambia",   "ZM", "Lusaka", "2026-04-20", "2026-04-22"),
    ("AI+ Developer™", "technical", "South Africa", "ZA", "Johannesburg", "2026-04-20", "2026-04-24"),
    ("AI+ Developer™", "technical", "Zambia",    "ZM", "Lusaka", "2026-04-27", "2026-05-01"),
    # ── MAY 2026 ──
    ("AI+ Human Resources™", "professional", "Zimbabwe", "ZW", "Harare", "2026-05-04", "2026-05-06"),
    ("AI+ Human Resources™", "professional", "Kenya",    "KE", "Nairobi", "2026-05-11", "2026-05-13"),
    ("AI+ Engineer™", "technical", "Zimbabwe",   "ZW", "Harare", "2026-05-11", "2026-05-15"),
    ("AI+ Engineer™", "technical", "Kenya",      "KE", "Nairobi", "2026-05-18", "2026-05-22"),
    ("AI+ Human Resources™", "professional", "Zambia", "ZM", "Lusaka", "2026-05-18", "2026-05-20"),
    ("AI+ Engineer™", "technical", "South Africa", "ZA", "Sandton", "2026-05-18", "2026-05-22"),
    ("AI+ Engineer™", "technical", "Zambia",     "ZM", "Lusaka", "2026-05-25", "2026-05-29"),
    # ── JUNE 2026 ──
    ("AI+ Supply Chain™", "professional", "Zimbabwe", "ZW", "Harare", "2026-06-01", "2026-06-03"),
    ("AI+ Supply Chain™", "professional", "Kenya",    "KE", "Nairobi", "2026-06-08", "2026-06-10"),
    ("AI+ Vibe Coder™", "technical", "Zimbabwe",  "ZW", "Harare", "2026-06-08", "2026-06-12"),
    ("AI+ Vibe Coder™", "technical", "Kenya",     "KE", "Nairobi", "2026-06-15", "2026-06-19"),
    ("AI+ Supply Chain™", "professional", "Zambia", "ZM", "Lusaka", "2026-06-15", "2026-06-17"),
    ("AI+ Vibe Coder™", "technical", "South Africa", "ZA", "Johannesburg", "2026-06-15", "2026-06-19"),
    ("AI+ Vibe Coder™", "technical", "Zambia",    "ZM", "Lusaka", "2026-06-22", "2026-06-26"),
    # ── JULY 2026 ──
    ("AI+ Project Manager™", "professional", "Zimbabwe", "ZW", "Harare", "2026-07-06", "2026-07-08"),
    ("AI+ Project Manager™", "professional", "Kenya",    "KE", "Nairobi", "2026-07-13", "2026-07-15"),
    ("AI+ Project Management Practitioner™", "professional", "Zimbabwe", "ZW", "Harare", "2026-07-13", "2026-07-15"),
    ("AI+ Project Management Practitioner™", "professional", "Kenya",    "KE", "Nairobi", "2026-07-20", "2026-07-22"),
    ("AI+ Project Manager™", "professional", "Zambia",   "ZM", "Lusaka", "2026-07-20", "2026-07-22"),
    ("AI+ Prompt Engineer Level 2™", "technical", "Zimbabwe", "ZW", "Harare", "2026-07-20", "2026-07-24"),
    ("AI+ Prompt Engineer Level 2™", "technical", "Kenya",    "KE", "Nairobi", "2026-07-27", "2026-07-31"),
    ("AI+ Project Management Practitioner™", "professional", "Zambia", "ZM", "Lusaka", "2026-07-27", "2026-07-29"),
    ("AI+ Prompt Engineer Level 2™", "technical", "South Africa", "ZA", "Sandton", "2026-07-27", "2026-07-31"),
    ("AI+ Prompt Engineer Level 2™", "technical", "Zambia",   "ZM", "Lusaka", "2026-08-03", "2026-08-07"),
    # ── AUGUST 2026 ──
    ("AI+ Agile Project Management Fundamentals™", "professional", "Zimbabwe", "ZW", "Harare", "2026-08-03", "2026-08-05"),
    ("AI+ Agile Project Management Fundamentals™", "professional", "Kenya",    "KE", "Nairobi", "2026-08-10", "2026-08-12"),
    ("AI+ Program Director – Practitioner™", "professional", "Zimbabwe", "ZW", "Harare", "2026-08-10", "2026-08-12"),
    ("AI+ Program Director – Practitioner™", "professional", "Kenya",    "KE", "Nairobi", "2026-08-17", "2026-08-19"),
    ("AI+ Agile Project Management Fundamentals™", "professional", "Zambia", "ZM", "Lusaka", "2026-08-17", "2026-08-19"),
    ("AI+ Context Engineering™", "technical", "Zimbabwe", "ZW", "Harare", "2026-08-17", "2026-08-21"),
    ("AI+ Context Engineering™", "technical", "Kenya",    "KE", "Nairobi", "2026-08-24", "2026-08-28"),
    ("AI+ Program Director – Practitioner™", "professional", "Zambia", "ZM", "Lusaka", "2026-08-24", "2026-08-26"),
    ("AI+ Context Engineering™", "technical", "South Africa", "ZA", "Johannesburg", "2026-08-24", "2026-08-28"),
    ("AI+ Context Engineering™", "technical", "Zambia",   "ZM", "Lusaka", "2026-08-31", "2026-09-04"),
    # ── SEPTEMBER 2026 ──
    ("AI+ Legal™", "professional", "Zimbabwe", "ZW", "Harare", "2026-09-07", "2026-09-09"),
    ("AI+ Legal™", "professional", "Kenya",    "KE", "Nairobi", "2026-09-14", "2026-09-16"),
    ("AI+ Real Estate™", "professional", "Zimbabwe", "ZW", "Harare", "2026-09-14", "2026-09-16"),
    ("AI+ Real Estate™", "professional", "Kenya",    "KE", "Nairobi", "2026-09-21", "2026-09-23"),
    ("AI+ Legal™", "professional", "Zambia",   "ZM", "Lusaka", "2026-09-21", "2026-09-23"),
    ("AI+ Security Level 1™", "technical", "Zimbabwe", "ZW", "Harare", "2026-09-21", "2026-09-25"),
    ("AI+ Security Level 1™", "technical", "Kenya",    "KE", "Nairobi", "2026-09-28", "2026-10-02"),
    ("AI+ Real Estate™", "professional", "Zambia",    "ZM", "Lusaka", "2026-09-28", "2026-09-30"),
    ("AI+ Security Level 1™", "technical", "Zambia",   "ZM", "Lusaka", "2026-10-05", "2026-10-09"),
    # ── OCTOBER 2026 ──
    ("AI+ Sales™", "professional", "Zimbabwe", "ZW", "Harare", "2026-10-05", "2026-10-07"),
    ("AI+ Sales™", "professional", "Kenya",    "KE", "Nairobi", "2026-10-12", "2026-10-14"),
    ("AI+ Marketing™", "professional", "Zimbabwe", "ZW", "Harare", "2026-10-12", "2026-10-14"),
    ("AI+ Marketing™", "professional", "Kenya",    "KE", "Nairobi", "2026-10-19", "2026-10-21"),
    ("AI+ Sales™", "professional", "Zambia",   "ZM", "Lusaka", "2026-10-19", "2026-10-21"),
    ("AI+ Security Level 2™", "technical", "Zimbabwe", "ZW", "Harare", "2026-10-19", "2026-10-23"),
    ("AI+ Security Level 2™", "technical", "Kenya",    "KE", "Nairobi", "2026-10-26", "2026-10-30"),
    ("AI+ Marketing™", "professional", "Zambia",   "ZM", "Lusaka", "2026-10-26", "2026-10-28"),
    ("AI+ Security Level 2™", "technical", "Zambia",   "ZM", "Lusaka", "2026-11-02", "2026-11-06"),
    # ── NOVEMBER 2026 ──
    ("AI+ Customer Service™", "professional", "Zimbabwe", "ZW", "Harare", "2026-11-02", "2026-11-04"),
    ("AI+ Customer Service™", "professional", "Kenya",    "KE", "Nairobi", "2026-11-09", "2026-11-11"),
    ("AI+ Product Manager™", "professional", "Zimbabwe", "ZW", "Harare", "2026-11-09", "2026-11-11"),
    ("AI+ Product Manager™", "professional", "Kenya",    "KE", "Nairobi", "2026-11-16", "2026-11-18"),
    ("AI+ Customer Service™", "professional", "Zambia",  "ZM", "Lusaka", "2026-11-16", "2026-11-18"),
    ("AI+ Security Level 3™", "technical", "Zimbabwe", "ZW", "Harare", "2026-11-16", "2026-11-20"),
    ("AI+ Security Level 3™", "technical", "Kenya",    "KE", "Nairobi", "2026-11-23", "2026-11-27"),
    ("AI+ Product Manager™", "professional", "Zambia",   "ZM", "Lusaka", "2026-11-23", "2026-11-25"),
    ("AI+ Security Level 3™", "technical", "Zambia",    "ZM", "Lusaka", "2026-11-30", "2026-12-04"),
    # ── DECEMBER 2026 ──
    ("AI+ Ethics™", "professional", "Zimbabwe", "ZW", "Harare", "2026-12-07", "2026-12-09"),
    ("AI+ Ethics™", "professional", "Kenya",    "KE", "Nairobi", "2026-12-14", "2026-12-16"),
    ("AI+ Writer™", "professional", "Zimbabwe", "ZW", "Harare", "2026-12-14", "2026-12-16"),
    ("AI+ Writer™", "professional", "Kenya",    "KE", "Nairobi", "2026-12-21", "2026-12-23"),
    ("AI+ Ethics™", "professional", "Zambia",   "ZM", "Lusaka", "2026-12-21", "2026-12-23"),
    ("AI+ Security Compliance™", "technical", "Zimbabwe", "ZW", "Harare", "2026-12-21", "2026-12-25"),
    ("AI+ Security Compliance™", "technical", "Kenya",    "KE", "Nairobi", "2026-12-28", "2027-01-01"),
    ("AI+ Writer™", "professional", "Zambia",   "ZM", "Lusaka", "2026-12-28", "2026-12-30"),
    ("AI+ Security Compliance™", "technical", "Zambia",   "ZM", "Lusaka", "2027-01-04", "2027-01-08"),
    # ── JANUARY 2027 ──
    ("AI+ Researcher™", "professional", "Zimbabwe", "ZW", "Harare", "2027-01-04", "2027-01-06"),
    ("AI+ Researcher™", "professional", "Kenya",    "KE", "Nairobi", "2027-01-11", "2027-01-13"),
    ("AI+ Chief AI Officer™", "professional", "Zimbabwe", "ZW", "Harare", "2027-01-11", "2027-01-13"),
    ("AI+ Chief AI Officer™", "professional", "Kenya",    "KE", "Nairobi", "2027-01-18", "2027-01-20"),
    ("AI+ Researcher™", "professional", "Zambia",   "ZM", "Lusaka", "2027-01-18", "2027-01-20"),
    ("AI+ Network™", "technical", "Zimbabwe", "ZW", "Harare", "2027-01-18", "2027-01-22"),
    ("AI+ Network™", "technical", "Kenya",    "KE", "Nairobi", "2027-01-25", "2027-01-29"),
    ("AI+ Chief AI Officer™", "professional", "Zambia", "ZM", "Lusaka", "2027-01-25", "2027-01-27"),
    ("AI+ Network™", "technical", "Zambia",    "ZM", "Lusaka", "2027-02-01", "2027-02-05"),
    # ── FEBRUARY 2027 ──
    ("AI+ Government™", "professional", "Zimbabwe", "ZW", "Harare", "2027-02-01", "2027-02-03"),
    ("AI+ Government™", "professional", "Kenya",    "KE", "Nairobi", "2027-02-08", "2027-02-10"),
    ("AI+ Policy Maker™", "professional", "Zimbabwe", "ZW", "Harare", "2027-02-08", "2027-02-10"),
    ("AI+ Policy Maker™", "professional", "Kenya",    "KE", "Nairobi", "2027-02-15", "2027-02-17"),
    ("AI+ Government™", "professional", "Zambia",   "ZM", "Lusaka", "2027-02-15", "2027-02-17"),
    ("AI+ Ethical Hacker™", "technical", "Zimbabwe", "ZW", "Harare", "2027-02-15", "2027-02-19"),
    ("AI+ Ethical Hacker™", "technical", "Kenya",    "KE", "Nairobi", "2027-02-22", "2027-02-26"),
    ("AI+ Policy Maker™", "professional", "Zambia",  "ZM", "Lusaka", "2027-02-22", "2027-02-24"),
    ("AI+ Ethical Hacker™", "technical", "Zambia",   "ZM", "Lusaka", "2027-03-01", "2027-03-05"),
    # ── MARCH 2027 ──
    ("AI+ Mining™", "professional", "Zimbabwe", "ZW", "Harare", "2027-03-01", "2027-03-03"),
    ("AI+ Mining™", "professional", "Kenya",    "KE", "Nairobi", "2027-03-08", "2027-03-10"),
    ("AI+ Telecommunications™", "professional", "Zimbabwe", "ZW", "Harare", "2027-03-08", "2027-03-10"),
    ("AI+ Telecommunications™", "professional", "Kenya",    "KE", "Nairobi", "2027-03-15", "2027-03-17"),
    ("AI+ Mining™", "professional", "Zambia",   "ZM", "Lusaka", "2027-03-15", "2027-03-17"),
    ("Executive Introduction to RSAIF", "technical", "Zimbabwe", "ZW", "Harare", "2027-03-15", "2027-03-19"),
    ("Executive Introduction to RSAIF", "technical", "Kenya",    "KE", "Nairobi", "2027-03-22", "2027-03-26"),
    ("AI+ Telecommunications™", "professional", "Zambia", "ZM", "Lusaka", "2027-03-22", "2027-03-24"),
    ("Executive Introduction to RSAIF", "technical", "Zambia",   "ZM", "Lusaka", "2027-03-29", "2027-04-02"),
]

PRICE_MAP = {
    "professional": "500.00",
    "technical": "700.00",
}

FOCUS_AREA_MAP = {
    "professional": "AI Business",
    "technical": "AI Development",
}


class Command(BaseCommand):
    help = "Seed the HOSI Academy AICerts® Masterclass Calendar 2026/2027"

    def add_arguments(self, parser):
        parser.add_argument(
            "--clear",
            action="store_true",
            help="Delete existing masterclasses before seeding",
        )

    def handle(self, *args, **options):
        if options["clear"]:
            deleted, _ = Masterclass.objects.all().delete()
            self.stdout.write(self.style.WARNING(f"Deleted {deleted} existing masterclasses."))

        created_count = 0
        updated_count = 0
        today = datetime.date.today()

        for (title, stream_type, country_name, country_code, city, start_str, end_str) in CALENDAR:
            start_date = datetime.date.fromisoformat(start_str)
            end_date = datetime.date.fromisoformat(end_str)

            # Determine status from dates
            if end_date < today:
                status = "completed"
            elif start_date <= today <= end_date:
                status = "ongoing"
            else:
                status = "scheduled"

            # Build a unique slug: title-country-startdate (truncated to 50 chars for SlugField)
            base_slug = slugify(f"{title} {country_name} {start_str}")[:50]

            obj, created = Masterclass.objects.update_or_create(
                slug=base_slug,
                defaults=dict(
                    title=title,
                    stream_type=stream_type,
                    country_name=country_name,
                    country_code=country_code,
                    city=city,
                    venue="Not Specified",
                    start_date=start_date,
                    end_date=end_date,
                    status=status,
                    price_physical=PRICE_MAP.get(stream_type, "500.00"),
                    price_online=PRICE_MAP.get(stream_type, "500.00"),
                    currency="USD",
                    focus_area=FOCUS_AREA_MAP.get(stream_type, "AI Business"),
                    description=(
                        f"{title} — {stream_type.capitalize()} masterclass in {city}, {country_name}. "
                        f"Duration: {(end_date - start_date).days + 1} days. "
                        f"AICerts® certified training programme."
                    ),
                    notes="Part of HOSI Academy 2026/2027 AICerts® Masterclass Calendar.",
                ),
            )

            if created:
                created_count += 1
            else:
                updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"[OK] Masterclass calendar seeded: {created_count} created, {updated_count} updated. "
                f"Total: {created_count + updated_count} sessions."
            )
        )
