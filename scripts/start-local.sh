#!/bin/bash

# Local Development Startup Script
# This script sets up and starts the local development environment

set -e

echo "🚀 Starting Local Development Environment"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop."
    exit 1
fi

echo -e "${BLUE}📦 Starting PostgreSQL database...${NC}"
cd backend
docker-compose up -d

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 3

# Check if database is ready
until docker exec screen_budget_db pg_isready -U postgres > /dev/null 2>&1; do
    echo "⏳ Database is starting..."
    sleep 2
done

echo -e "${GREEN}✅ Database is ready!${NC}"

# Set database URL
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"

# Run migrations
echo -e "${BLUE}🗄️  Running database migrations...${NC}"
npx prisma migrate deploy || {
    echo "⚠️  Migrations may have already run. Continuing..."
}

# Generate Prisma client
echo -e "${BLUE}🔧 Generating Prisma client...${NC}"
npx prisma generate

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📥 Installing dependencies...${NC}"
    npm install
fi

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "🚀 Starting backend server..."
echo "   Backend will run at: http://localhost:3000"
echo "   API endpoints: http://localhost:3000/api/v1"
echo ""
echo "📱 iOS App Configuration:"
echo "   For Simulator: http://localhost:3000/api/v1"
echo "   For Device: http://[YOUR-MAC-IP]:3000/api/v1"
echo ""
echo "💡 To find your Mac's IP: ifconfig | grep 'inet ' | grep -v 127.0.0.1"
echo ""

# Start the server
npm run dev

