from django.db import migrations


class Migration(migrations.Migration):
    # This migration is a duplicate of 0002_chat_system.
    # All models/operations are already applied by 0002_chat_system.
    # Kept as empty no-op so 0003_merge_0002 dependency chain is satisfied.

    dependencies = [
        ('communication', '0002_chat_system'),
    ]

    operations = []
