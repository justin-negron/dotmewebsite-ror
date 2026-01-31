# API Documentation

Base URL: `http://localhost:3000/api/v1` (development)
Base URL: `https://api.justinnegron.dev/api/v1` (production)

## Authentication

Currently, all endpoints are public. Admin endpoints (coming soon) will require JWT authentication.

## Response Format

All successful responses:
```json
{
  "success": true,
  "data": { ... },
  "meta": { ... }
}
```

All error responses:
```json
{
  "success": false,
  "message": "Error description",
  "errors": []
}
```

## Endpoints

### Projects

#### List Projects
```
GET /projects
```

Query Parameters:
- `featured=true` - Only featured projects
- `tech=Ruby` - Filter by technology
- `page=1` - Page number
- `per_page=10` - Items per page

Response:
```json
{
  "success": true,
  "data": {
    "projects": [
      {
        "id": 1,
        "title": "Project Name",
        "description": "Description",
        "tech_stack": ["Ruby", "Rails"],
        "github_url": "https://github.com/...",
        "live_url": "https://...",
        "featured": true,
        "created_at": "2026-01-31T12:00:00Z"
      }
    ]
  },
  "meta": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 5
  }
}
```

[Continue with all other endpoints...]