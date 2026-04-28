#!/usr/bin/env python3
"""
Test script to verify the enrollment modal changes are working correctly.
This checks:
1. Frontend is serving the updated code
2. Masterclass data is available with correct pricing
3. Pricing constants match the backend
"""

import requests
import json
import sys

# Colors for output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def test_frontend_serving():
    """Test if frontend is serving"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}1. Testing Frontend is Serving{Colors.ENDC}")
    try:
        response = requests.get("http://localhost:7000", timeout=5)
        if response.status_code == 200:
            print(f"{Colors.OKGREEN}✓ Frontend is responding on port 7000{Colors.ENDC}")
            return True
        else:
            print(f"{Colors.FAIL}✗ Frontend returned status {response.status_code}{Colors.ENDC}")
            return False
    except Exception as e:
        print(f"{Colors.FAIL}✗ Frontend not reachable: {e}{Colors.ENDC}")
        return False

def test_build_contains_changes():
    """Test if build contains the attendance mode selection text"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}2. Testing Build Contains Enrollment Changes{Colors.ENDC}")
    try:
        with open('/home/tk/lms-prod/frontend/prebuilt_web/main.dart.js', 'r') as f:
            content = f.read()
            
        checks = [
            ("Select Attendance Mode", "Attendance mode selection text"),
            ("Online", "Online option"),
            ("Physical", "Physical option"),
            ("Live virtual classes", "Online subtitle"),
            ("In-person at venue", "Physical subtitle"),
        ]
        
        all_found = True
        for text, description in checks:
            if text in content:
                print(f"{Colors.OKGREEN}✓ Found: {description}{Colors.ENDC}")
            else:
                print(f"{Colors.FAIL}✗ Missing: {description}{Colors.ENDC}")
                all_found = False
        
        return all_found
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error reading build file: {e}{Colors.ENDC}")
        return False

def test_pricing_constants():
    """Test if Flutter pricing constants match requirements"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}3. Testing Pricing Constants{Colors.ENDC}")
    
    pricing_file = '/home/tk/lms-prod/frontend/lib/src/core/constants/pricing_constants.dart'
    try:
        with open(pricing_file, 'r') as f:
            content = f.read()
        
        expected_prices = {
            'masterclassTechnicalPhysical': 1100.0,
            'masterclassTechnicalOnline': 700.0,
            'masterclassProfessionalPhysical': 700.0,
            'masterclassProfessionalOnline': 500.0,
        }
        
        all_correct = True
        for constant, expected_value in expected_prices.items():
            # Search for the constant definition
            import re
            pattern = rf'static const double {constant} = ([\d.]+);'
            match = re.search(pattern, content)
            
            if match:
                actual_value = float(match.group(1))
                if actual_value == expected_value:
                    print(f"{Colors.OKGREEN}✓ {constant}: ${actual_value}{Colors.ENDC}")
                else:
                    print(f"{Colors.FAIL}✗ {constant}: ${actual_value} (expected ${expected_value}){Colors.ENDC}")
                    all_correct = False
            else:
                print(f"{Colors.FAIL}✗ {constant}: Not found{Colors.ENDC}")
                all_correct = False
        
        return all_correct
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error reading pricing constants: {e}{Colors.ENDC}")
        return False

def test_backend_masterclasses():
    """Test if backend has masterclasses with correct pricing"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}4. Testing Backend Masterclass Data{Colors.ENDC}")
    
    try:
        import os
        import django
        os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
        django.setup()
        
        from apps.masterclasses.models import Masterclass
        
        masterclasses = Masterclass.objects.all()[:3]
        
        if not masterclasses:
            print(f"{Colors.WARNING}⚠ No masterclasses found in database{Colors.ENDC}")
            return False
        
        for mc in masterclasses:
            stream_type = mc.stream_type
            online_price = mc.price_online
            physical_price = mc.price_physical
            
            expected_online = 700.0 if stream_type == 'technical' else 500.0
            expected_physical = 1100.0 if stream_type == 'technical' else 700.0
            
            online_ok = abs(online_price - expected_online) < 0.01
            physical_ok = abs(physical_price - expected_physical) < 0.01
            
            status_online = f"{Colors.OKGREEN}✓{Colors.ENDC}" if online_ok else f"{Colors.FAIL}✗{Colors.ENDC}"
            status_physical = f"{Colors.OKGREEN}✓{Colors.ENDC}" if physical_ok else f"{Colors.FAIL}✗{Colors.ENDC}"
            
            print(f"  {Colors.BOLD}{mc.title[:40]}{Colors.ENDC} ({stream_type})")
            print(f"    Online: ${online_price} {status_online}")
            print(f"    Physical: ${physical_price} {status_physical}")
        
        return True
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error querying backend: {e}{Colors.ENDC}")
        return False

def test_container_status():
    """Test if Docker containers are running"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}5. Testing Container Status{Colors.ENDC}")
    
    import subprocess
    try:
        result = subprocess.run(
            ['docker', 'compose', 'ps', '--format', 'table', '{{.Name}}\t{{.Status}}\t{{.Ports}}'],
            cwd='/home/tk/lms-prod',
            capture_output=True,
            text=True
        )
        
        if 'lms-prod-frontend-1' in result.stdout and 'running' in result.stdout.lower():
            print(f"{Colors.OKGREEN}✓ Frontend container is running{Colors.ENDC}")
        else:
            print(f"{Colors.WARNING}⚠ Frontend container status unclear{Colors.ENDC}")
            print(result.stdout)
            
        if 'lms-prod-backend-1' in result.stdout and 'running' in result.stdout.lower():
            print(f"{Colors.OKGREEN}✓ Backend container is running{Colors.ENDC}")
        else:
            print(f"{Colors.WARNING}⚠ Backend container status unclear{Colors.ENDC}")
            
        return True
    except Exception as e:
        print(f"{Colors.FAIL}✗ Error checking containers: {e}{Colors.ENDC}")
        return False

def main():
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}   ENROLLMENT MODAL DEPLOYMENT TEST{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    
    results = []
    
    results.append(("Frontend Serving", test_frontend_serving()))
    results.append(("Build Contains Changes", test_build_contains_changes()))
    results.append(("Pricing Constants", test_pricing_constants()))
    results.append(("Backend Masterclass Data", test_backend_masterclasses()))
    results.append(("Container Status", test_container_status()))
    
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}   TEST SUMMARY{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = f"{Colors.OKGREEN}✓ PASS{Colors.ENDC}" if result else f"{Colors.FAIL}✗ FAIL{Colors.ENDC}"
        print(f"  {status} - {test_name}")
    
    print(f"\n  Total: {passed}/{total} tests passed")
    
    if passed == total:
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}🎉 ALL TESTS PASSED! Deployment successful.{Colors.ENDC}\n")
        return 0
    else:
        print(f"\n{Colors.WARNING}⚠ Some tests failed. Please review the output above.{Colors.ENDC}\n")
        return 1

if __name__ == '__main__':
    sys.exit(main())
