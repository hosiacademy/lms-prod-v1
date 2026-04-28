#!/usr/bin/env python
"""
BBB Sessions Diagnostic Test
Tests the complete flow of BBB session retrieval for instructors
"""

import os
import sys
from pathlib import Path

# Add backend to path
backend_path = Path(__file__).parent / 'backend'
sys.path.insert(0, str(backend_path))

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

# Initialize Django
import django
django.setup()

from django.contrib.auth import get_user_model
from apps.bbb_integration.models import LiveSession, BBBServer
from apps.instructors.models import Instructor
from rest_framework.test import APIRequestFactory
from apps.bbb_integration.views import LiveSessionViewSet
from rest_framework.request import Request

User = get_user_model()

print("="*80)
print("BBB SESSIONS DIAGNOSTIC TEST")
print("="*80)

# ============================================================================
# TEST 1: Check BBB Server Configuration
# ============================================================================
print("\n" + "="*80)
print("TEST 1: BBB Server Configuration")
print("="*80)

try:
    bbb_servers = BBBServer.objects.all()
    print(f"✓ Found {bbb_servers.count()} BBB server(s)")
    
    for server in bbb_servers:
        print(f"\n  Server: {server.name}")
        print(f"    - URL: {server.api_url}")
        print(f"    - Active: {server.is_active}")
        print(f"    - Current Load: {server.current_load}/{server.max_load}")
        print(f"    - Load %: {server.load_percentage:.1f}%")
        
    if bbb_servers.count() == 0:
        print("⚠ WARNING: No BBB servers configured!")
    else:
        active_servers = bbb_servers.filter(is_active=True)
        if active_servers.count() == 0:
            print("⚠ WARNING: No active BBB servers!")
        else:
            print("✓ At least one active BBB server found")
            
except Exception as e:
    print(f"✗ ERROR: {e}")
    import traceback
    traceback.print_exc()

# ============================================================================
# TEST 2: Check Instructor User Configuration
# ============================================================================
print("\n" + "="*80)
print("TEST 2: Instructor User Configuration")
print("="*80)

# Try to find the test instructor
test_emails = [
    'takawira.mazando@hosiacademy.co.za',
    'takawira@test.com',
]

instructor = None
for email in test_emails:
    user = User.objects.filter(email=email).first()
    if user:
        instructor = user
        print(f"✓ Found instructor: {email}")
        break

if not instructor:
    # Get any instructor
    instructor = User.objects.filter(role_id=2).first()
    if instructor:
        print(f"✓ Using alternative instructor: {instructor.email}")
    else:
        print("✗ ERROR: No instructor found in database!")
        sys.exit(1)

print(f"\n  User Details:")
print(f"    - ID: {instructor.id}")
print(f"    - Email: {instructor.email}")
print(f"    - Name: {instructor.first_name} {instructor.last_name}")
print(f"    - Role ID: {instructor.role_id}")

# Check for instructor_id attribute
instructor_id_attr = getattr(instructor, 'instructor_id', None)
print(f"    - instructor_id attribute: {instructor_id_attr}")

# Check if instructor profile exists
try:
    instructor_profile = Instructor.objects.filter(user=instructor).first()
    if instructor_profile:
        print(f"    - Has Instructor Profile: ✓")
        print(f"    - Facilitator ID: {instructor_profile.facilitator_id}")
    else:
        print(f"    - Has Instructor Profile: ✗ (No profile found)")
except Exception as e:
    print(f"    - Instructor Profile Check Error: {e}")

# Check role
role_name = "Unknown"
if instructor.role_id == 1:
    role_name = "Admin"
elif instructor.role_id == 2:
    role_name = "Instructor"
elif instructor.role_id == 3:
    role_name = "Student"
print(f"    - Role Name: {role_name}")

# ============================================================================
# TEST 3: Check Live Sessions
# ============================================================================
print("\n" + "="*80)
print("TEST 3: Live Sessions for Instructor")
print("="*80)

sessions = LiveSession.objects.filter(instructor=instructor)
print(f"Total sessions for {instructor.email}: {sessions.count()}")

if sessions.count() > 0:
    print(f"\n  Sessions:")
    for session in sessions[:10]:  # Show first 10
        print(f"\n    Session ID: {session.id}")
        print(f"      - Title: {session.title}")
        print(f"      - Meeting ID: {session.meeting_id}")
        print(f"      - Status: {session.status}")
        print(f"      - Scheduled Start: {session.scheduled_start}")
        print(f"      - Scheduled End: {session.scheduled_end}")
        print(f"      - BBB Server: {session.bbb_server.name if session.bbb_server else 'None'}")
        print(f"      - Is Upcoming: {session.is_upcoming}")
        print(f"      - Is Live Now: {session.is_live_now}")
        
    # Count by status
    from django.utils import timezone
    upcoming = sessions.filter(status='scheduled', scheduled_start__gte=timezone.now()).count()
    live = sessions.filter(status='live').count()
    past = sessions.filter(status='ended').count()
    scheduled_past = sessions.filter(status='scheduled', scheduled_start__lt=timezone.now()).count()
    
    print(f"\n  Session Status Breakdown:")
    print(f"    - Upcoming: {upcoming}")
    print(f"    - Live Now: {live}")
    print(f"    - Ended: {past}")
    print(f"    - Scheduled (Past Date): {scheduled_past} ⚠")
else:
    print("⚠ WARNING: No sessions found for this instructor!")

# ============================================================================
# TEST 4: Test my_sessions Endpoint Directly
# ============================================================================
print("\n" + "="*80)
print("TEST 4: Testing my_sessions Endpoint")
print("="*80)

try:
    # Create a fake request
    factory = APIRequestFactory()
    request = factory.get('/api/v1/bbb/sessions/my_sessions/')
    request.user = instructor
    
    # Create DRF request
    drf_request = Request(request)
    
    # Create viewset instance
    viewset = LiveSessionViewSet()
    viewset.request = drf_request
    viewset.format_kwarg = None
    
    # Call my_sessions
    print("  Calling my_sessions endpoint...")
    response = viewset.my_sessions(drf_request)
    
    print(f"\n  Response Status: {response.status_code}")
    print(f"  Response Data Type: {type(response.data)}")
    
    if response.status_code == 200:
        print(f"\n  ✓ SUCCESS! Endpoint returned data:")
        data = response.data
        print(f"    - Upcoming sessions: {len(data.get('upcoming', []))}")
        print(f"    - Live sessions: {len(data.get('live', []))}")
        print(f"    - Past sessions: {len(data.get('past', []))}")
        
        if data.get('upcoming'):
            print(f"\n    Upcoming Session Titles:")
            for s in data['upcoming'][:5]:
                print(f"      - {s.get('title', 'Unknown')}")
    else:
        print(f"\n  ✗ FAILED! Status: {response.status_code}")
        print(f"  Error Data: {response.data}")
        
except Exception as e:
    print(f"\n  ✗ ERROR calling endpoint: {e}")
    import traceback
    traceback.print_exc()

# ============================================================================
# TEST 5: Test Permission Check Logic
# ============================================================================
print("\n" + "="*80)
print("TEST 5: Permission Check Logic")
print("="*80)

# Replicate the permission check from my_sessions
instructor_id = getattr(instructor, 'instructor_id', None)
has_sessions = LiveSession.objects.filter(instructor=instructor).exists()

print(f"  instructor_id attribute: {instructor_id}")
print(f"  Has sessions in DB: {has_sessions}")
print(f"  Permission check result: {'PASS' if (instructor_id or has_sessions) else 'FAIL'}")

if not instructor_id and not has_sessions:
    print(f"\n  ⚠ WARNING: User would fail permission check!")
    print(f"     - No instructor_id attribute")
    print(f"     - No sessions in database")
elif not instructor_id:
    print(f"\n  ℹ Note: User has no instructor_id but has sessions (check passes)")
elif not has_sessions:
    print(f"\n  ℹ Note: User has instructor_id but no sessions (check passes)")
else:
    print(f"\n  ✓ User passes permission check (has both instructor_id and sessions)")

# ============================================================================
# TEST 6: Check get_queryset Logic
# ============================================================================
print("\n" + "="*80)
print("TEST 6: get_queryset Logic Test")
print("="*80)

try:
    factory = APIRequestFactory()
    request = factory.get('/api/v1/bbb/sessions/')
    request.user = instructor
    
    drf_request = Request(request)
    
    viewset = LiveSessionViewSet()
    viewset.request = drf_request
    viewset.format_kwarg = None
    
    queryset = viewset.get_queryset()
    print(f"  Queryset count: {queryset.count()}")
    print(f"  ✓ get_queryset works correctly")
    
except Exception as e:
    print(f"  ✗ ERROR in get_queryset: {e}")
    import traceback
    traceback.print_exc()

# ============================================================================
# TEST 7: Check User Model Fields
# ============================================================================
print("\n" + "="*80)
print("TEST 7: User Model Field Analysis")
print("="*80)

user_fields = [f.name for f in User._meta.get_fields()]
print(f"  User model fields ({len(user_fields)}):")

relevant_fields = ['id', 'email', 'first_name', 'last_name', 'role', 'role_id', 
                   'instructor', 'instructor_id', 'instructor_profile']
                   
for field in relevant_fields:
    if field in user_fields:
        value = getattr(instructor, field, 'NOT_FOUND')
        if field == 'instructor' or field == 'instructor_profile':
            # It's a related field
            try:
                related = getattr(instructor, field, None)
                if hasattr(related, 'all'):
                    value = f"Related (QuerySet: {related.count()})"
                else:
                    value = f"Related ({type(related).__name__})"
            except:
                value = "Related (Error accessing)"
        print(f"    - {field}: {value}")
    else:
        print(f"    - {field}: [FIELD NOT FOUND]")

# ============================================================================
# SUMMARY
# ============================================================================
print("\n" + "="*80)
print("DIAGNOSTIC SUMMARY")
print("="*80)

issues = []
warnings = []

# Check BBB servers
if bbb_servers.count() == 0:
    issues.append("No BBB servers configured")
elif bbb_servers.filter(is_active=True).count() == 0:
    issues.append("No active BBB servers")

# Check instructor
if instructor.role_id != 2:
    warnings.append(f"Instructor has role_id={instructor.role_id} (expected 2)")

instructor_id = getattr(instructor, 'instructor_id', None)
if not instructor_id:
    warnings.append("User missing instructor_id attribute")

# Check sessions
if sessions.count() == 0:
    warnings.append("Instructor has no sessions in database")

# Check endpoint
if response.status_code != 200:
    issues.append(f"my_sessions endpoint returned status {response.status_code}")

if issues:
    print(f"\n🔴 CRITICAL ISSUES ({len(issues)}):")
    for issue in issues:
        print(f"   • {issue}")
else:
    print(f"\n✓ No critical issues found")

if warnings:
    print(f"\n🟡 WARNINGS ({len(warnings)}):")
    for warning in warnings:
        print(f"   • {warning}")
else:
    print(f"\n✓ No warnings")

print("\n" + "="*80)
print("DIAGNOSTIC COMPLETE")
print("="*80)
