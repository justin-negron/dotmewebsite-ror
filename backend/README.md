# Portfolio Backend API

Ruby on Rails API backend for justinnegron.dev portfolio website.

## Tech Stack

- Ruby 3.2.2
- Rails 7.1
- PostgreSQL 15
- Redis 7
- Sidekiq (background jobs)

## Setup

### Prerequisites

- Ruby 3.2.2
- PostgreSQL 15+
- Redis 7+
- Bundler

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/portfolio-backend.git
cd portfolio-backend
```

2. Install dependencies
```bash
bundle install
```

3. Set up environment variables
```bash
cp .env.example .env.development
```

Edit `.env.development` and add your values:
- Database credentials
- Redis URL
- JWT secret (generate with `rails secret`)
- SMTP credentials (for contact form emails)

4. Create and migrate database
```bash
rails db:create
rails db:migrate
rails db:seed
```

5. Start Redis
```bash
redis-server
```

6. Start Rails server
```bash
rails server
```

API will be available at `http://localhost:3000`

## Environment Variables

See `.env.example` for all available environment variables.

### Required Variables

- `DATABASE_URL` - PostgreSQL connection string
- `REDIS_URL` - Redis connection string
- `JWT_SECRET` - Secret for JWT token generation (min 32 chars)
- `FRONTEND_URL` - Frontend application URL (for CORS)
- `SMTP_*` - Email configuration for contact form

### Optional Variables

- `AWS_*` - AWS credentials for S3 uploads
- `RATE_LIMIT_*` - API rate limiting configuration
- `ANALYTICS_ENABLED` - Enable/disable analytics tracking

## API Endpoints

### Public Endpoints

- `GET /api/v1/projects` - List all projects
- `GET /api/v1/projects/:id` - Get single project
- `GET /api/v1/experiences` - List work experiences
- `GET /api/v1/blog_posts` - List published blog posts
- `GET /api/v1/blog_posts/:slug` - Get single blog post
- `POST /api/v1/contacts` - Submit contact form
- `POST /api/v1/analytics/track` - Track page view

### Admin Endpoints (Authentication Required)

- Full CRUD for projects, experiences, blog posts
- Contact form submissions management
- Analytics dashboard

## Testing

```bash
bundle exec rspec
```

## Deployment

See `.env.production.example` for production environment variables.

### AWS ECS Deployment

1. Set environment variables in AWS Secrets Manager
2. Build and push Docker image to ECR
3. Update ECS task definition
4. Deploy to ECS cluster

Detailed deployment instructions in `/infrastructure/README.md`

## License

Private - All Rights Reserved