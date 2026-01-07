#!/bin/bash

# Screen Budget API Deployment Script
# This script runs tests, builds the project, and deploys to Vercel

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Screen Budget API Deployment Script          ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    echo -e "${RED}❌ Error: package.json not found. Are you in the project root?${NC}"
    exit 1
fi

# Parse command line arguments
DEPLOY_ENV="production"
SKIP_TESTS=false
SKIP_BUILD=false
VERCEL_FLAGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --preview)
            DEPLOY_ENV="preview"
            shift
            ;;
        --help)
            echo "Usage: ./scripts/deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-tests    Skip running tests before deployment"
            echo "  --skip-build    Skip building the project"
            echo "  --preview       Deploy to preview environment (not production)"
            echo "  --help          Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Step 1: Check prerequisites
echo -e "${BLUE}📋 Step 1: Checking prerequisites...${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm is not installed. Please install npm first.${NC}"
    exit 1
fi

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vercel CLI not found. Installing...${NC}"
    npm install -g vercel
fi

# Check if we're logged into Vercel
if ! vercel whoami &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged into Vercel. Please login:${NC}"
    vercel login
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# Step 2: Install dependencies
echo -e "${BLUE}📦 Step 2: Installing dependencies...${NC}"
cd "$BACKEND_DIR"
npm install
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 3: Generate Prisma client
echo -e "${BLUE}🔧 Step 3: Generating Prisma client...${NC}"
npx prisma generate
echo -e "${GREEN}✅ Prisma client generated${NC}"
echo ""

# Step 4: Run tests
if [ "$SKIP_TESTS" = false ]; then
    echo -e "${BLUE}🧪 Step 4: Running tests...${NC}"
    
    # Check if DATABASE_URL is set
    if [ -z "$DATABASE_URL" ]; then
        echo -e "${YELLOW}⚠️  DATABASE_URL not set. Tests may fail.${NC}"
        echo -e "${YELLOW}   Set DATABASE_URL environment variable or use --skip-tests${NC}"
    fi
    
    if npm test; then
        echo -e "${GREEN}✅ All tests passed${NC}"
    else
        echo -e "${RED}❌ Tests failed. Deployment aborted.${NC}"
        echo -e "${YELLOW}   Use --skip-tests to deploy anyway (not recommended)${NC}"
        exit 1
    fi
    echo ""
else
    echo -e "${YELLOW}⏭️  Step 4: Skipping tests (--skip-tests flag)${NC}"
    echo ""
fi

# Step 5: Build project
if [ "$SKIP_BUILD" = false ]; then
    echo -e "${BLUE}🔨 Step 5: Building project...${NC}"
    cd "$BACKEND_DIR"
    npm run build
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build successful${NC}"
    else
        echo -e "${RED}❌ Build failed. Deployment aborted.${NC}"
        exit 1
    fi
    echo ""
else
    echo -e "${YELLOW}⏭️  Step 5: Skipping build (--skip-build flag)${NC}"
    echo ""
fi

# Step 6: Deploy to Vercel
echo -e "${BLUE}🚀 Step 6: Deploying to Vercel...${NC}"
cd "$PROJECT_ROOT"

if [ "$DEPLOY_ENV" = "production" ]; then
    echo -e "${YELLOW}Deploying to PRODUCTION environment...${NC}"
    vercel --prod
else
    echo -e "${YELLOW}Deploying to PREVIEW environment...${NC}"
    vercel
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi
echo ""

# Step 7: Verify deployment
echo -e "${BLUE}🔍 Step 7: Verifying deployment...${NC}"

# Get deployment URL from Vercel
DEPLOYMENT_URL=$(vercel ls --json | jq -r '.[0].url' 2>/dev/null || echo "")

if [ -n "$DEPLOYMENT_URL" ]; then
    echo -e "${GREEN}Deployment URL: https://$DEPLOYMENT_URL${NC}"
    
    # Test health endpoint
    echo -e "${BLUE}Testing health endpoint...${NC}"
    if curl -f -s "https://$DEPLOYMENT_URL/health" > /dev/null; then
        echo -e "${GREEN}✅ Health check passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Health check failed (deployment may still be processing)${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Could not determine deployment URL${NC}"
    echo -e "${YELLOW}   Check Vercel dashboard for deployment status${NC}"
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Deployment Complete! 🎉                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"

