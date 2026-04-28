#!/bin/bash
# Test script to verify Masterclasses and Learnerships API endpoints

echo "=========================================="
echo "Testing LMS API Endpoints"
echo "=========================================="
echo ""

# Test 1: Masterclasses API
echo "📚 Test 1: Masterclasses API"
echo "------------------------------------------"
MASTERCLASS_RESPONSE=$(docker exec lms-prod-backend-1 python manage.py shell -c "
import requests
r = requests.get('http://localhost:8000/api/v1/courses/masterclasses/', params={'page': 1, 'page_size': 1})
print(f'Status: {r.status_code}')
if r.status_code == 200:
    data = r.json()
    print(f'Count: {data.get(\"count\", 0)}')
    print(f'Page: {data.get(\"page\", 0)}')
    if data.get('results'):
        print(f'First result: {data[\"results\"][0].get(\"title\", \"N/A\")}')
    else:
        print('No results found')
else:
    print(f'Error: {r.text[:200]}')
" 2>&1 | grep -E "Status:|Count:|Page:|First result:|No results|Error:")

echo "$MASTERCLASS_RESPONSE"
echo ""

# Test 2: Learnerships API
echo "🎓 Test 2: Learnerships API"
echo "------------------------------------------"
LEARNERSHIP_RESPONSE=$(docker exec lms-prod-backend-1 python manage.py shell -c "
import requests
r = requests.get('http://localhost:8000/api/v1/learnerships/programmes/', params={'page': 1, 'page_size': 1})
print(f'Status: {r.status_code}')
if r.status_code == 200:
    data = r.json()
    print(f'Count: {data.get(\"count\", 0)}')
    print(f'Page: {data.get(\"page\", \"N/A\")}')
    if data.get('results'):
        print(f'First result: {data[\"results\"][0].get(\"title\", \"N/A\")}')
    else:
        print('No results found')
else:
    print(f'Error: {r.text[:200]}')
" 2>&1 | grep -E "Status:|Count:|Page:|First result:|No results|Error:")

echo "$LEARNERSHIP_RESPONSE"
echo ""

# Test 3: Nginx proxy test for Masterclasses
echo "🌐 Test 3: Nginx Proxy (Masterclasses)"
echo "------------------------------------------"
NGINX_TEST=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost:7004/api/v1/courses/masterclasses/?page=1&page_size=1)
echo "$NGINX_TEST"
echo ""

# Test 4: Nginx proxy test for Learnerships
echo "🌐 Test 4: Nginx Proxy (Learnerships)"
echo "------------------------------------------"
NGINX_LEARNERSHIP=$(curl -s -o /dev/null -w "HTTP Status: %{http_code}" http://localhost:7004/api/v1/learnerships/programmes/?page=1&page_size=1)
echo "$NGINX_LEARNERSHIP"
echo ""

echo "=========================================="
echo "✅ API Tests Complete"
echo "=========================================="
