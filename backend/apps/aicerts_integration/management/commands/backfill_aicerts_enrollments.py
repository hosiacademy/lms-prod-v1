# apps/aicerts_integration/management/commands/backfill_aicerts_enrollments.py
"""
Management command to backfill AICERTS enrollments for students who paid for
an AICERTS course before the automatic sync was wired into FinalizeEnrollmentView.

Usage:
    python manage.py backfill_aicerts_enrollments
    python manage.py backfill_aicerts_enrollments --dry-run
    python manage.py backfill_aicerts_enrollments --email richard@example.com
"""

from django.core.management.base import BaseCommand
from django.contrib.contenttypes.models import ContentType


class Command(BaseCommand):
    help = (
        "Backfill AICertsEnrollment records and AICERTS-side enrollment for "
        "students who have a paid Enrollment for an AICERTS course but no "
        "matching AICertsEnrollment record."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be done without making any changes.',
        )
        parser.add_argument(
            '--email',
            type=str,
            default=None,
            help='Only process enrollments for this specific user email.',
        )

    def handle(self, *args, **options):
        from apps.payments.models import Enrollment, EnrollmentStatus
        from apps.aicerts_courses.models import AiCertsCourse
        from apps.aicerts_integration.models import AICertsEnrollment
        from apps.aicerts_integration.services import EnrollmentSyncService

        dry_run = options['dry_run']
        target_email = options['email']

        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN — no changes will be made.\n"))

        # Find all paid Enrollment rows that point at an AiCertsCourse
        aicerts_ct = ContentType.objects.get_for_model(AiCertsCourse)
        qs = Enrollment.objects.filter(
            content_type=aicerts_ct,
            status=EnrollmentStatus.ENROLLED,
        ).select_related('user')

        if target_email:
            qs = qs.filter(user__email__iexact=target_email)

        total = qs.count()
        self.stdout.write(
            f"Found {total} paid AICERTS enrollment(s) to inspect"
            f"{f' for {target_email}' if target_email else ''}.\n"
        )

        counts = {'skipped': 0, 'synced': 0, 'pending': 0, 'failed': 0}

        for enrollment in qs:
            user = enrollment.user
            course = AiCertsCourse.objects.filter(id=enrollment.object_id).first()

            if not course:
                self.stdout.write(
                    self.style.WARNING(
                        f"  SKIP  enrollment {enrollment.id} ({user.email}): "
                        f"AiCertsCourse id={enrollment.object_id} not found."
                    )
                )
                counts['skipped'] += 1
                continue

            already_exists = AICertsEnrollment.objects.filter(
                user=user, course=course
            ).exists()

            if already_exists:
                existing = AICertsEnrollment.objects.get(user=user, course=course)
                self.stdout.write(
                    f"  OK    enrollment {enrollment.id} ({user.email} → {course.title}): "
                    f"AICertsEnrollment already exists "
                    f"(status={existing.aicerts_enrollment_status})."
                )
                counts['skipped'] += 1
                continue

            self.stdout.write(
                f"  SYNC  enrollment {enrollment.id} ({user.email} → {course.title}) ..."
            )

            if dry_run:
                self.stdout.write(self.style.SUCCESS("        [DRY RUN] would call EnrollmentSyncService"))
                counts['synced'] += 1
                continue

            try:
                EnrollmentSyncService.enroll_user_in_course(user=user, course=course)
                self.stdout.write(self.style.SUCCESS("        SUCCESS"))
                counts['synced'] += 1
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"        FAILED: {e}"))
                # Create a pending record so the daily retry task picks it up
                try:
                    AICertsEnrollment.objects.get_or_create(
                        user=user,
                        course=course,
                        defaults={
                            'aicerts_enrollment_status': 'pending',
                            'sync_error': str(e)[:500],
                        }
                    )
                    self.stdout.write(
                        self.style.WARNING(
                            "        Created pending AICertsEnrollment — "
                            "will be retried by the daily Celery task."
                        )
                    )
                    counts['pending'] += 1
                except Exception as inner_e:
                    self.stdout.write(
                        self.style.ERROR(f"        Could not create pending record: {inner_e}")
                    )
                    counts['failed'] += 1

        self.stdout.write("\n" + "=" * 60)
        self.stdout.write(
            f"Done.  "
            f"Synced: {counts['synced']}  |  "
            f"Already existed (skipped): {counts['skipped']}  |  "
            f"Pending (retry queued): {counts['pending']}  |  "
            f"Hard failed: {counts['failed']}"
        )
        if dry_run:
            self.stdout.write(self.style.WARNING("(DRY RUN — no changes were made)"))
