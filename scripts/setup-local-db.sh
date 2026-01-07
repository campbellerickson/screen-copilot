#!/bin/bash

# Quick database setup script for local testing

set -e

echo "🗄️  Setting up local database..."

cd backend

# Start database
echo "📦 Starting PostgreSQL..."
docker-compose up -d

# Wait for database
echo "⏳ Waiting for database..."
sleep 3

# Set database URL
export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/screen_budget"

# Run migrations
echo "🔄 Running migrations..."
npx prisma migrate deploy || echo "⚠️  Migrations may have already run"

# Generate Prisma client
echo "🔧 Generating Prisma client..."
npx prisma generate

echo ""
echo "✅ Database setup complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Start backend: cd backend && npm run dev"
echo "   2. Open Prisma Studio: cd backend && npx prisma studio"
echo ""

