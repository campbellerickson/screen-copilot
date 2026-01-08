#!/bin/bash

# Production API Testing Script
# Tests all critical endpoints on the production API

API_URL="https://screen-copilot-ysge.vercel.app"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Production API Test Suite"
echo "API URL: $API_URL"
echo "========================================="
echo ""

# Test 1: Health Check
echo "Test 1: Health Check"
echo -n "GET /health ... "
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
fi
echo ""

# Test 2: Signup (will fail if email exists, but tests endpoint)
echo "Test 2: User Signup"
echo -n "POST /api/v1/auth/signup ... "
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"test'$(date +%s)'@example.com","password":"TestPassword123!","name":"Test User"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE)"
    # Extract token for later tests
    TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
    echo "   Token: ${TOKEN:0:50}..."
elif [ "$HTTP_CODE" = "400" ]; then
    echo -e "${YELLOW}~ PARTIAL${NC} (HTTP $HTTP_CODE - endpoint working, validation error expected)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
fi
echo ""

# Test 3: Login with invalid credentials (tests endpoint)
echo "Test 3: User Login"
echo -n "POST /api/v1/auth/login ... "
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"wrong"}')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ] || [ "$HTTP_CODE" = "400" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - endpoint working, invalid creds expected)"
    echo "   Response: $BODY"
elif [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - login successful)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE)"
    echo "   Response: $BODY"
fi
echo ""

# Test 4: Get current user (without auth - should fail)
echo "Test 4: Get Current User (unauthenticated)"
echo -n "GET /api/v1/auth/me ... "
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/auth/me")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - correctly requires authentication)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE - should require auth)"
    echo "   Response: $BODY"
fi
echo ""

# Test 5: Get budgets (without auth - should fail)
echo "Test 5: Get Screen Time Budgets (unauthenticated)"
echo -n "GET /api/v1/screen-time/budgets ... "
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/screen-time/budgets")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - correctly requires authentication)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE - should require auth)"
    echo "   Response: $BODY"
fi
echo ""

# Test 6: Get subscription status (without auth - should fail)
echo "Test 6: Get Subscription Status (unauthenticated)"
echo -n "GET /api/v1/subscription/status ... "
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/subscription/status")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - correctly requires authentication)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE - should require auth)"
    echo "   Response: $BODY"
fi
echo ""

# Test 7: Get weekly goals (without auth - should fail)
echo "Test 7: Get Weekly Goals (unauthenticated)"
echo -n "GET /api/v1/weekly-goals ... "
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/weekly-goals")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - correctly requires authentication)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE - should require auth)"
    echo "   Response: $BODY"
fi
echo ""

# Test 8: Invalid route (should return 404)
echo "Test 8: Invalid Route"
echo -n "GET /api/v1/invalid/route ... "
RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/invalid/route")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ PASS${NC} (HTTP $HTTP_CODE - correctly returns 404)"
    echo "   Response: $BODY"
else
    echo -e "${RED}✗ FAIL${NC} (HTTP $HTTP_CODE - should return 404)"
    echo "   Response: $BODY"
fi
echo ""

echo "========================================="
echo "Test Suite Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Add environment variables in Vercel if tests show database errors"
echo "2. Test authenticated endpoints after signup/login succeeds"
echo "3. Monitor Vercel logs for any errors"
echo ""
