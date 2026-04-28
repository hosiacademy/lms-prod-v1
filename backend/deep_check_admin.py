import os
import sys
import django
import ast

# Setup Django
sys.path.append(r'C:\Users\HosiTech\lms-monorepo\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

try:
    django.setup()
except Exception as e:
    print(f"Django setup failed: {e}")
    sys.exit(1)

from django.contrib import admin

print("Deep check of admin registration...")
print("=" * 60)

# Check all registered admins
for model, model_admin in admin.site._registry.items():
    admin_class = model_admin.__class__
    
    print(f"\nChecking: {admin_class.__name__} for {model.__name__}")
    print(f"  Module: {admin_class.__module__}")
    
    # Get actions attribute through MRO
    actions_found = False
    for cls in admin_class.__mro__:
        if 'actions' in cls.__dict__:
            actions_attr = cls.__dict__['actions']
            print(f"  Found actions in {cls.__name__}")
            print(f"    Type: {type(actions_attr)}")
            print(f"    Callable: {callable(actions_attr)}")
            
            if callable(actions_attr) and not isinstance(actions_attr, (list, tuple, dict)):
                print(f"    ⚠️  PROBLEM: actions is a method in {cls.__name__}")
                actions_found = True
            break
    
    if not actions_found:
        print("  ✓ No problematic actions found")

print("=" * 60)

# Also check if there's an issue with how actions is being accessed
print("\nTrying to simulate Django's check...")
print("=" * 60)

for model, model_admin in admin.site._registry.items():
    admin_class = model_admin.__class__
    
    try:
        # This is what Django does internally
        actions = admin_class.actions
        print(f"✓ {admin_class.__name__}: actions accessed successfully")
        print(f"  Type: {type(actions)}")
        
        # Try to iterate (this is where the error happens)
        if actions is not None:
            try:
                list(actions)  # This will fail if actions is a method
                print(f"  ✓ Can iterate over actions")
            except TypeError as e:
                print(f"  ⚠️  Cannot iterate: {e}")
                
    except Exception as e:
        print(f"✗ {admin_class.__name__}: Error accessing actions: {e}")

print("=" * 60)
