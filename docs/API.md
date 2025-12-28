# Screen Budget - API Documentation

Complete API reference for the Screen Time Budget backend.

## Base URL

- **Development:** `http://localhost:3000/api/v1`
- **Production:** `https://your-domain.com/api/v1`

## Authentication

**Note:** MVP version doesn't include authentication. All endpoints are currently public.

For production, add JWT authentication:
- Include `Authorization: Bearer <token>` header
- Obtain token via login endpoint

---

## Budget Endpoints

### Create Budget

Create a new monthly screen time budget for a user.

**Endpoint:** `POST /screen-time/budgets`

**Request Body:**
```json
{
  "userId": "string (UUID)",
  "monthYear": "string (ISO date, first day of month)",
  "categories": [
    {
      "categoryType": "string (enum)",
      "categoryName": "string",
      "monthlyHours": "number",
      "isExcluded": "boolean"
    }
  ]
}
```

**Category Types:**
- `social_media`
- `entertainment`
- `gaming`
- `productivity`
- `shopping`
- `news_reading`
- `health_fitness`
- `other`

**Example Request:**
```bash
curl -X POST http://localhost:3000/api/v1/screen-time/budgets \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "monthYear": "2025-01-01",
    "categories": [
      {
        "categoryType": "social_media",
        "categoryName": "Social Media",
        "monthlyHours": 30.0,
        "isExcluded": false
      },
      {
        "categoryType": "entertainment",
        "categoryName": "Entertainment",
        "monthlyHours": 40.0,
        "isExcluded": false
      }
    ]
  }'
```

**Success Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "budget-uuid",
    "userId": "user-uuid",
    "monthYear": "2025-01-01T00:00:00.000Z",
    "isActive": true,
    "categories": [...],
    "createdAt": "2025-01-15T10:00:00.000Z",
    "updatedAt": "2025-01-15T10:00:00.000Z"
  }
}
```

**Error Response (500):**
```json
{
  "success": false,
  "error": "Error message"
}
```

---

### Get Current Budget

Get the current month's budget for a user.

**Endpoint:** `GET /screen-time/budgets/:userId/current`

**Parameters:**
- `userId` (path) - User's unique identifier

**Example Request:**
```bash
curl http://localhost:3000/api/v1/screen-time/budgets/550e8400-e29b-41d4-a716-446655440000/current
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "budget-uuid",
    "userId": "user-uuid",
    "monthYear": "2025-01-01T00:00:00.000Z",
    "isActive": true,
    "categories": [
      {
        "id": "category-uuid",
        "budgetId": "budget-uuid",
        "categoryType": "social_media",
        "categoryName": "Social Media",
        "monthlyHours": "30.00",
        "isExcluded": false,
        "createdAt": "2025-01-15T10:00:00.000Z",
        "updatedAt": "2025-01-15T10:00:00.000Z"
      }
    ],
    "createdAt": "2025-01-15T10:00:00.000Z",
    "updatedAt": "2025-01-15T10:00:00.000Z"
  }
}
```

**Not Found Response (404):**
```json
{
  "success": false,
  "error": "No budget found for current month"
}
```

---

### Update Category Budget

Update a specific category's budget settings.

**Endpoint:** `PUT /screen-time/budgets/categories/:categoryId`

**Parameters:**
- `categoryId` (path) - Category's unique identifier

**Request Body:**
```json
{
  "monthlyHours": "number (optional)",
  "isExcluded": "boolean (optional)"
}
```

**Example Request:**
```bash
curl -X PUT http://localhost:3000/api/v1/screen-time/budgets/categories/category-uuid \
  -H "Content-Type: application/json" \
  -d '{
    "monthlyHours": 25,
    "isExcluded": false
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "category-uuid",
    "budgetId": "budget-uuid",
    "categoryType": "social_media",
    "categoryName": "Social Media",
    "monthlyHours": "25.00",
    "isExcluded": false,
    "updatedAt": "2025-01-15T11:00:00.000Z"
  }
}
```

---

## Usage Endpoints

### Sync Usage Data

Sync app usage data from iOS device to backend.

**Endpoint:** `POST /screen-time/usage/sync`

**Request Body:**
```json
{
  "userId": "string (UUID)",
  "usageDate": "string (ISO date)",
  "apps": [
    {
      "bundleId": "string",
      "appName": "string",
      "totalMinutes": "number (integer)"
    }
  ]
}
```

**Example Request:**
```bash
curl -X POST http://localhost:3000/api/v1/screen-time/usage/sync \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "550e8400-e29b-41d4-a716-446655440000",
    "usageDate": "2025-01-15",
    "apps": [
      {
        "bundleId": "com.instagram.instagram",
        "appName": "Instagram",
        "totalMinutes": 65
      },
      {
        "bundleId": "com.netflix.Netflix",
        "appName": "Netflix",
        "totalMinutes": 120
      }
    ]
  }'
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "synced": 2,
    "budgetStatus": {
      "social_media": {
        "usedToday": 65,
        "dailyBudget": 58,
        "remaining": -7,
        "status": "over"
      },
      "entertainment": {
        "usedToday": 120,
        "dailyBudget": 77,
        "remaining": -43,
        "status": "over"
      }
    },
    "alertsTriggered": [
      {
        "category": "Social Media",
        "overageMinutes": 7
      },
      {
        "category": "Entertainment",
        "overageMinutes": 43
      }
    ]
  }
}
```

---

### Get Daily Usage

Get usage summary for a specific date.

**Endpoint:** `GET /screen-time/usage/:userId/daily`

**Parameters:**
- `userId` (path) - User's unique identifier
- `date` (query, optional) - ISO date string (defaults to today)

**Example Request:**
```bash
curl "http://localhost:3000/api/v1/screen-time/usage/550e8400-e29b-41d4-a716-446655440000/daily?date=2025-01-15"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "date": "2025-01-15T00:00:00.000Z",
    "totalMinutes": 185,
    "categories": {
      "social_media": {
        "totalMinutes": 65,
        "dailyBudget": 58,
        "monthlyBudget": 1800,
        "monthlyUsed": 450,
        "status": "over",
        "apps": [
          {
            "name": "Instagram",
            "minutes": 45
          },
          {
            "name": "Twitter",
            "minutes": 20
          }
        ]
      },
      "entertainment": {
        "totalMinutes": 120,
        "dailyBudget": 77,
        "monthlyBudget": 2400,
        "monthlyUsed": 1200,
        "status": "over",
        "apps": [
          {
            "name": "Netflix",
            "minutes": 90
          },
          {
            "name": "YouTube",
            "minutes": 30
          }
        ]
      }
    }
  }
}
```

---

## Alert Endpoints

### Get User Alerts

Get alert history for a user.

**Endpoint:** `GET /screen-time/alerts/:userId`

**Parameters:**
- `userId` (path) - User's unique identifier
- `limit` (query, optional) - Number of alerts to return (default: 10)

**Example Request:**
```bash
curl "http://localhost:3000/api/v1/screen-time/alerts/550e8400-e29b-41d4-a716-446655440000?limit=5"
```

**Success Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "alert-uuid",
      "userId": "user-uuid",
      "categoryType": "social_media",
      "alertDate": "2025-01-15",
      "overageMinutes": 7,
      "alertSentAt": "2025-01-15T14:30:00.000Z",
      "wasDismissed": false,
      "dismissedAt": null
    }
  ]
}
```

---

### Dismiss Alert

Mark an alert as dismissed.

**Endpoint:** `POST /screen-time/alerts/:alertId/dismiss`

**Parameters:**
- `alertId` (path) - Alert's unique identifier

**Example Request:**
```bash
curl -X POST http://localhost:3000/api/v1/screen-time/alerts/alert-uuid/dismiss
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "alert-uuid",
    "userId": "user-uuid",
    "categoryType": "social_media",
    "alertDate": "2025-01-15",
    "overageMinutes": 7,
    "wasDismissed": true,
    "dismissedAt": "2025-01-15T15:00:00.000Z"
  }
}
```

---

## Health Check

### Get Server Status

Check if the server is running.

**Endpoint:** `GET /health`

**Example Request:**
```bash
curl http://localhost:3000/health
```

**Success Response (200):**
```json
{
  "status": "ok",
  "timestamp": "2025-01-15T10:00:00.000Z"
}
```

---

## Error Responses

All endpoints may return these standard errors:

**400 Bad Request:**
```json
{
  "success": false,
  "error": "Invalid request parameters"
}
```

**404 Not Found:**
```json
{
  "success": false,
  "error": "Resource not found"
}
```

**500 Internal Server Error:**
```json
{
  "success": false,
  "error": "Internal server error message"
}
```

---

## Rate Limiting

**Note:** Rate limiting not implemented in MVP.

For production, consider:
- 100 requests per minute per IP
- 1000 requests per hour per user

---

## App Auto-Categorization

The backend automatically categorizes apps based on bundle ID and name:

| Category | Keywords |
|----------|----------|
| Social Media | instagram, tiktok, twitter, facebook, snapchat, reddit, discord |
| Entertainment | netflix, youtube, spotify, hulu, disney, twitch, video, music |
| Gaming | game |
| Productivity | notion, slack, zoom, teams, office, google, work |
| Shopping | amazon, shop, ebay |
| News & Reading | news, read |
| Health & Fitness | health, fitness, workout |
| Other | (default for unmatched) |

Apps can be manually recategorized via UI (future feature).

---

## Database Schema Reference

See [DATABASE.md](./DATABASE.md) for complete database schema documentation.

---

## Testing

### Test Data Setup

```bash
# Create test user budget
curl -X POST http://localhost:3000/api/v1/screen-time/budgets \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-123",
    "monthYear": "2025-01-01",
    "categories": [
      {
        "categoryType": "social_media",
        "categoryName": "Social Media",
        "monthlyHours": 10,
        "isExcluded": false
      }
    ]
  }'

# Sync over-budget usage
curl -X POST http://localhost:3000/api/v1/screen-time/usage/sync \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-123",
    "usageDate": "2025-01-15",
    "apps": [
      {
        "bundleId": "com.instagram.instagram",
        "appName": "Instagram",
        "totalMinutes": 100
      }
    ]
  }'

# Verify alert was triggered
curl http://localhost:3000/api/v1/screen-time/alerts/test-user-123
```

---

## Next Steps

- Implement JWT authentication
- Add request validation middleware
- Add rate limiting
- Add API versioning
- Add OpenAPI/Swagger documentation
- Add webhook support for real-time alerts
