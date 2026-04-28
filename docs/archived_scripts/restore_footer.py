#!/usr/bin/env python3
"""Restore the full multi-column footer to onboarding page"""

# Read the backup file to get helper functions and footer
with open('/home/tk/lms-prod/frontend/lib/src/presentation/pages/onboarding/onboarding_page.dart.bak', 'r') as f:
    backup_lines = f.readlines()

# Read current file
with open('/home/tk/lms-prod/frontend/lib/src/presentation/pages/onboarding/onboarding_page.dart', 'r') as f:
    current_lines = f.readlines()

# Find where to insert helper functions (after _FooterLink class)
insert_helpers_at = -1
for i, line in enumerate(current_lines):
    if 'class _FooterLink' in line:
        # Find end of class
        depth = 0
        for j in range(i, len(current_lines)):
            if '{' in current_lines[j]:
                depth += current_lines[j].count('{')
            if '}' in current_lines[j]:
                depth -= current_lines[j].count('}')
            if depth <= 0:
                insert_helpers_at = j + 1
                break
        break

# Find where old footer starts and ends
footer_start = -1
footer_end = -1
for i, line in enumerate(current_lines):
    if 'PaymentMethodsMarquee()' in line and 'const' in line:
        footer_start = i - 3  # Include comment
        # Find end
        depth = 0
        started = False
        for j in range(i, len(current_lines)):
            if '(' in current_lines[j]:
                depth += current_lines[j].count('(')
                started = True
            if ')' in current_lines[j]:
                depth -= current_lines[j].count(')')
            if started and depth <= 0:
                footer_end = j + 1
                break
        break

print(f"Helper insert at: {insert_helpers_at}")
print(f"Footer: {footer_start} to {footer_end}")

if insert_helpers_at == -1 or footer_start == -1:
    print("Could not find insertion points!")
    exit(1)

# Extract helper functions from backup (lines 391-433, 0-indexed: 390-432)
helper_functions = backup_lines[390:433]

# Build new file
new_lines = current_lines[:insert_helpers_at] + helper_functions + current_lines[footer_end:]

# Write
with open('/home/tk/lms-prod/frontend/lib/src/presentation/pages/onboarding/onboarding_page.dart', 'w') as f:
    f.writelines(new_lines)

print("Footer restored successfully!")
