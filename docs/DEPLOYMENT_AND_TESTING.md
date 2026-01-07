# Deployment and Testing Guide

Complete guide for deploying the Screen Budget API and running tests.

---

## 📋 Table of Contents

1. [Running Tests](#running-tests)
2. [Deployment Script](#deployment-script)
3. [GitHub Actions CI/CD](#github-actions-cicd)
4. [Manual Deployment](#manual-deployment)
5. [Test Coverage](#test-coverage)

---

## 🧪 Running Tests

### Quick Start

Run all tests:
```bash
./scripts/test.sh
```

Or from the backend directory:
```bash
cd backend
npm test
```

### Test Options

```bash
# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run a specific test file
npm test -- auth.test.ts
```

### Test Structure

Tests are organized by feature:
- `api.test.ts` - Screen time budget endpoints (existing)
- `auth.test.ts` - Authentication endpoints
- `subscription.test.ts` - Subscription management
- `weekly-goals.test.ts` - Weekly goals
- `break-reminders.test.ts` - Break reminders
- `weekly-insights.test.ts` - Weekly insights
- `helpers.ts` - Test utilities and helpers

### Environment Setup

Tests require a database connection. Set `DATABASE_URL` environment variable:

```bash
export DATABASE_URL="postgresql://user:password@localhost:5432/test_db"
npm test
```

For local development, you can use Docker:
```bash
docker-compose up -d  # Starts PostgreSQL
```

---

## 🚀 Deployment Script

### Usage

Deploy to production:
```bash
./scripts/deploy.sh
```

Deploy to preview:
```bash
./scripts/deploy.sh --preview
```

Skip tests (not recommended):
```bash
./scripts/deploy.sh --skip-tests
```

Skip build:
```bash
./scripts/deploy.sh --skip-build
```

### What the Script Does

1. **Prerequisites Check**
   - Verifies Node.js and npm are installed
   - Checks if Vercel CLI is installed
   - Verifies Vercel login status

2. **Install Dependencies**
   - Runs `npm install` in backend directory

3. **Generate Prisma Client**
   - Runs `npx prisma generate`

4. **Run Tests** (unless `--skip-tests`)
   - Runs all test suites
   - Aborts deployment if tests fail

5. **Build Project** (unless `--skip-build`)
   - Compiles TypeScript to JavaScript
   - Verifies build succeeds

6. **Deploy to Vercel**
   - Deploys to production or preview environment
   - Uses Vercel CLI

7. **Verify Deployment**
   - Tests health endpoint
   - Confirms deployment is live

### Prerequisites

- Node.js 18+
- npm
- Vercel CLI (`npm install -g vercel`)
- Vercel account and project linked
- `DATABASE_URL` environment variable (for tests)

---

## 🔄 GitHub Actions CI/CD

### Setup

1. **Add Vercel Secrets to GitHub**
   - Go to your GitHub repository
   - Settings → Secrets and variables → Actions
   - Add these secrets:
     - `VERCEL_TOKEN` - Get from Vercel dashboard → Settings → Tokens
     - `VERCEL_ORG_ID` - Get from Vercel project settings
     - `VERCEL_PROJECT_ID` - Get from Vercel project settings

2. **Workflow Triggers**
   - Tests run on every push and pull request
   - Deployment runs only on pushes to `main` or `master` branch
   - Tests must pass before deployment

### Workflow Steps

1. **Test Job**
   - Sets up PostgreSQL service
   - Installs dependencies
   - Generates Prisma client
   - Runs database migrations
   - Executes all tests
   - Uploads coverage reports

2. **Deploy Job** (only on main/master)
   - Runs after tests pass
   - Deploys to Vercel production
   - Verifies deployment health

### Viewing Results

- Go to your GitHub repository
- Click "Actions" tab
- View workflow runs and results

---

## 📝 Manual Deployment

If you prefer to deploy manually:

### 1. Run Tests Locally

```bash
cd backend
export DATABASE_URL="your-database-url"
npm test
```

### 2. Build Project

```bash
cd backend
npm run build
```

### 3. Deploy to Vercel

```bash
# From project root
vercel --prod
```

### 4. Verify Deployment

```bash
curl https://your-app.vercel.app/health
```

---

## 📊 Test Coverage

### Current Coverage

Tests cover:

- ✅ **Authentication** (signup, login, Apple Sign In, profile, account deletion)
- ✅ **Subscriptions** (status, receipt validation, cancellation, webhooks)
- ✅ **Screen Time Budgets** (create, get, update categories)
- ✅ **Usage Tracking** (sync, daily usage, alerts)
- ✅ **Weekly Goals** (create, get current, get history)
- ✅ **Break Reminders** (get, update settings)
- ✅ **Weekly Insights** (get insights with usage data)
- ✅ **Health Check** (server status)

### Running Coverage Report

```bash
cd backend
npm run test:coverage
```

Open `backend/coverage/index.html` in your browser to view detailed coverage.

### Adding New Tests

1. Create test file in `backend/src/tests/`
2. Import helpers from `./helpers`
3. Use `authenticatedRequest` for protected endpoints
4. Clean up test data in `afterAll` hook

Example:
```typescript
import { authenticatedRequest, createTestUser, cleanupTestUser } from './helpers';

describe('My New Feature', () => {
  let testUserId: string;
  let authToken: string;

  beforeAll(async () => {
    const user = await createTestUser();
    testUserId = user.id;
    authToken = generateTestToken(user.id, user.email!);
  });

  afterAll(async () => {
    await cleanupTestUser(testUserId);
  });

  it('should test my feature', async () => {
    const response = await authenticatedRequest(
      'get',
      '/api/v1/my-endpoint',
      authToken
    );
    expect(response.status).toBe(200);
  });
});
```

---

## 🐛 Troubleshooting

### Tests Fail with Database Connection Error

- Verify `DATABASE_URL` is set correctly
- Check database is running and accessible
- Ensure database has required tables (run migrations)

### Deployment Fails

- Check Vercel logs: `vercel logs`
- Verify environment variables in Vercel dashboard
- Ensure Prisma client is generated before build
- Check build output for errors

### Vercel CLI Not Found

```bash
npm install -g vercel
vercel login
```

### Tests Timeout

- Increase Jest timeout in `jest.config.js`
- Check database connection pool settings
- Verify test database isn't locked

---

## 📚 Additional Resources

- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [Vercel CLI Documentation](https://vercel.com/docs/cli)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## ✅ Best Practices

1. **Always run tests before deploying**
   - Use `./scripts/deploy.sh` which runs tests automatically
   - Never skip tests in production deployments

2. **Keep tests isolated**
   - Each test should be independent
   - Clean up test data after each test suite

3. **Use test helpers**
   - Don't duplicate test setup code
   - Use `helpers.ts` for common operations

4. **Test edge cases**
   - Invalid input
   - Missing authentication
   - Non-existent resources
   - Boundary conditions

5. **Monitor test coverage**
   - Aim for >80% coverage
   - Focus on critical paths first
   - Add tests for new features

---

**Happy Testing! 🎉**

