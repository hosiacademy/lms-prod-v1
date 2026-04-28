# apps/appearance/admin.py

"""
Temporary placeholder for Appearance admin.

The Theme model has not been created yet in apps/appearance/models.py.
This file is intentionally empty/minimal to prevent ImportError
and allow the Django development server to start successfully.

When you create the Theme model, replace this file with the full,
beautiful Afro-centric ThemeAdmin code.
"""

# No models are registered — safe and clean
# This avoids "cannot import name 'Theme'" errors during startup

# Helpful comment for future development
# ------------------------------------------------------------------
# When ready, add the Theme model to models.py and enable this admin:
#
# from django.contrib import admin
# from django.utils.html import format_html
# from django.utils.safestring import mark_safe
# from .models import Theme
#
# @admin.register(Theme)
# class ThemeAdmin(admin.ModelAdmin):
#     # ... full beautiful Afro-centric theme admin code ...
# ------------------------------------------------------------------