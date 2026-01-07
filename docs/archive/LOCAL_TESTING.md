# 🧪 Local Testing Guide

This guide will help you set up and test the app on your local machine with a local PostgreSQL database.

## Quick Start

### 1. Start Local PostgreSQL Database

The project includes a Docker Compose file for easy database setup:

```bash
cd backend
docker-compose up -d
```

This will:
- Start a PostgreSQL 15 container
- Create a database named `copilot_screentime`
- Expose it on port `5432`
- Use credentials: `postgres` / `postgres`

**Verify it's running:**
```bash
docker ps | grep postgres
```

### 2. Create Environment File

Create a `.env` file in the `backend` directory:

```bash
cd backend
cat > .env << 'EOF'
# Database Connection (Local PostgreSQL)
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/copilot_screentime?schema=public"

# Server Configuration
PORT=3000
NODE_ENV=development

# JWT Secret (for authentication)
JWT_SECRET=local-dev-secret-key-change-in-production

# CORS (allow all origins in development)
CORS_ORIGIN=*
EOF
```

Or manually create `backend/.env` with the content above.

### 3. Install Dependencies

```bash
cd backend
npm install
```

### 4. Run Database Migrations

This will create all the necessary tables in your local database:

```bash
cd backend

# Generate Prisma Client
npm run prisma:generate

# Run migrations
npm run prisma:migrate
```

**Note:** If you see a prompt asking to create a new migration, type `y` and press Enter.

### 5. Start the Backend Server

```bash
cd backend
npm run dev
```

You should see:
```
╔═══════════════════════════════════════════════╗
║  Screen Time Copilot API Server                ║
║  Port: 3000                                    ║
║  Environment: development                      ║
╚═══════════════════════════════════════════════╝
```

### 6. Test the API

Open a new terminal and test the health endpoint:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2025-01-15T10:00:00.000Z",
  "environment": "development"
}
```

## Testing API Endpoints

### Create a Test User

```bash
curl -X POST http://localhost:3000/api/v1/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test1234",
    "name": "Test User"
  }'
```

Save the `token` from the response for authenticated requests.

### Create a Budget

```bash
# Replace YOUR_TOKEN with the token from signup
curl -X POST http://localhost:3000/api/v1/screen-time/budgets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "monthYear": "2025-01-01",
    "categories": [
      {
        "categoryType": "social_media",
        "categoryName": "Social Media",
        "monthlyHours": 30,
        "isExcluded": false
      }
    ]
  }'
```

### Get Current Budget

```bash
curl -X GET http://localhost:3000/api/v1/screen-time/budgets/current \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Viewing Your Database

You can use Prisma Studio to view and edit your database:

```bash
cd backend
npm run prisma:studio
```

This will open a web interface at `http://localhost:5555` where you can browse all tables and data.

## Stopping the Database

When you're done testing:

```bash
cd backend
docker-compose down
```

To also remove the data volume (fresh start):
```bash
docker-compose down -v
```

## Troubleshooting

### Database Connection Issues

**Problem:** Cannot connect to database
```bash
# Check if PostgreSQL container is running
docker ps | grep postgres

# Check container logs
docker-compose logs postgres

# Restart the container
docker-compose restart
```

### Port Already in Use

**Problem:** Port 3000 is already in use
- Change `PORT=3001` in `.env` file
- Or stop the process using port 3000

### Migration Errors

**Problem:** Prisma migration fails
```bash
# Reset database (WARNING: deletes all data)
cd backend
npx prisma migrate reset

# Then run migrations again
npm run prisma:migrate
```

### Prisma Client Not Generated

**Problem:** `@prisma/client` not found
```bash
cd backend
npm run prisma:generate
```

## Next Steps

- See `docs/API.md` for complete API documentation
- See `docs/SETUP.md` for iOS app setup
- See `docs/DEPLOYMENT.md` for production deployment

