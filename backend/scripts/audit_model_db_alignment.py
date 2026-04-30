import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
sys.stdout.reconfigure(encoding='utf-8')
django.setup()

from django.db import connection

def get_db_columns(table_name):
    cursor = connection.cursor()
    cursor.execute(
        "SELECT column_name FROM information_schema.columns WHERE table_name = %s AND table_schema = 'public'",
        [table_name]
    )
    return {row[0] for row in cursor.fetchall()}


def check_model(model_class):
    meta = model_class._meta
    table = meta.db_table
    db_cols = get_db_columns(table)
    if not db_cols:
        return table, [], []

    missing_in_db = []
    extra_in_db   = []

    model_db_columns = set()
    for field in meta.concrete_fields:
        col = field.column
        model_db_columns.add(col)
        if col not in db_cols:
            missing_in_db.append((field.name, col))

    for col in db_cols:
        if col not in model_db_columns:
            extra_in_db.append(col)

    return table, missing_in_db, extra_in_db


models_to_check = []
errors = []

for label, mod_path, cls_name in [
    ('payments.Order',              'apps.payments.models',  'Order'),
    ('payments.Enrollment',         'apps.payments.models',  'Enrollment'),
    ('payments.PaymentTransaction', 'apps.payments.models',  'PaymentTransaction'),
    ('masterclasses.Masterclass',   'apps.masterclasses.models', 'Masterclass'),
]:
    try:
        import importlib
        mod = importlib.import_module(mod_path)
        cls = getattr(mod, cls_name)
        models_to_check.append((label, cls))
    except Exception as e:
        errors.append(f"  Could not load {label}: {e}")


lines = []
lines.append("")
lines.append("=" * 70)
lines.append("  MODEL vs DATABASE COLUMN AUDIT")
lines.append("=" * 70)

if errors:
    lines.append("\nLOAD ERRORS:")
    lines.extend(errors)

for label, model_cls in models_to_check:
    table, missing, extra = check_model(model_cls)
    lines.append(f"\n[MODEL] {label}  (table: {table})")
    if not missing and not extra:
        lines.append("  [OK] Fully aligned -- no mismatches")
    if missing:
        lines.append(f"  [MISSING FROM DB] {len(missing)} field(s) in model but NOT in database:")
        for name, col in missing:
            lines.append(f"    - field '{name}'  =>  db_column '{col}'")
    if extra:
        lines.append(f"  [EXTRA IN DB] {len(extra)} column(s) in database but NOT in model:")
        for col in sorted(extra):
            lines.append(f"    + '{col}'")

lines.append("")
lines.append("=" * 70)
lines.append("END OF AUDIT")
lines.append("=" * 70)

report = "\n".join(lines)
print(report)

# Also save to file for easy reference
with open('scripts/audit_report.txt', 'w', encoding='utf-8') as f:
    f.write(report)
print("\n[Saved to scripts/audit_report.txt]")
