# Portfolio Backend API

Ruby on Rails API backend for justinnegron.dev portfolio website.

## 📋 Table of Contents

- [Tech Stack](#tech-stack)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Deployment](#deployment)

## 🛠 Tech Stack

- **Ruby** 3.4.8
- **Rails** 7.1.6
- **PostgreSQL** 15+ (via Docker)
- **Redis** 7+ (via Docker)
- **Sidekiq** - Background job processing
- **RSpec** - Testing framework
- **Docker** - Containerized services

## ✨ Features

- RESTful API with versioning (v1)
- Portfolio projects management
- Work experience tracking
- Blog with view counting
- Contact form with email notifications
- Analytics (page view tracking)
- Background job processing
- Comprehensive test coverage (100%)
- CORS enabled for frontend integration

## 📦 Prerequisites

- Ruby 3.4.8
- Bundler
- Docker & Docker Compose
- Node.js 20+ (for frontend, later)

## 🚀 Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/portfolio-backend.git
cd portfolio-backend
```

### 2. Install Dependencies

```bash
bundle install
```

### 3. Set Up Environment Variables

```bash
cp .env.example .env.development
```

Edit `.env.development` and add your values:
- Database credentials (default works with Docker)
- Redis URL (default works with Docker)
- JWT secret (generate with `rails secret`)
- SMTP credentials (for contact form emails)

### 4. Start Docker Services

```bash
docker compose up -d
```

Verify services are running:
```bash
docker compose ps
```

### 5. Create and Migrate Database

```bash
rails db:create
rails db:migrate
rails db:seed
```

## 🎮 Running the Application

### Development Mode

**Terminal 1 - Rails Server:**
```bash
rails server
```

**Terminal 2 - Sidekiq Worker:**
```bash
bundle exec sidekiq
```

**Terminal 3 - Commands:**
```bash
# Run tests
bundle exec rspec

# Rails console
rails console

# Check routes
rails routes | grep api
```

### Access Points

- **API Base URL:** http://localhost:3000/api/v1
- **Sidekiq Dashboard:** http://localhost:3000/sidekiq
- **Email Previews:** http://localhost:3000/rails/mailers

## 📚 API Documentation

### Public Endpoints

#### Projects
```
GET    /api/v1/projects           # List all projects
GET    /api/v1/projects/:id       # Get single project
GET    /api/v1/projects?featured=true  # Filter featured
GET    /api/v1/projects?tech=Ruby      # Filter by technology
```

#### Experiences
```
GET    /api/v1/experiences        # List all experiences
GET    /api/v1/experiences?current=true  # Current job only
GET    /api/v1/experiences?past=true     # Past jobs only
```

#### Blog Posts
```
GET    /api/v1/blog_posts         # List published posts
GET    /api/v1/blog_posts/:slug   # Get single post
GET    /api/v1/blog_posts?tag=Ruby      # Filter by tag
```

#### Contact
```
POST   /api/v1/contacts           # Submit contact form
Body: {
  "contact": {
    "name": "John Doe",
    "email": "john@example.com",
    "subject": "Inquiry",
    "message": "Your message here"
  }
}
```

#### Analytics
```
POST   /api/v1/analytics/track    # Track page view
Body: { "path": "/projects" }
```

### Response Format

All responses follow this format:

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "current_page": 1,
    "total_pages": 1,
    "total_count": 10
  }
}
```

Error responses:

```json
{
  "success": false,
  "message": "Error description",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

## 🧪 Testing

### Run All Tests

```bash
bundle exec rspec
```

### Run Specific Tests

```bash
# Single file
bundle exec rspec spec/models/project_spec.rb

# Single test
bundle exec rspec spec/models/project_spec.rb:10

# By type
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/serializers
```

### Test Coverage

```bash
# Generate coverage report
bundle exec rspec

# View coverage
open coverage/index.html
```

**Current Coverage:**
- Line Coverage: 100%
- Branch Coverage: 100%

## 🔧 Development Tools

### Rails Console

```bash
rails console

# Test API response
Project.all
BlogPost.published.count
```

### Database Console

```bash
# Access PostgreSQL directly
docker compose exec db psql -U postgres -d portfolio_development

# List tables
\dt

# Query
SELECT * FROM projects;
```

### Background Jobs

Monitor Sidekiq: http://localhost:3000/sidekiq

### Email Testing

Preview emails: http://localhost:3000/rails/mailers

## 🚀 Deployment

### Environment Variables (Production)

Set these in your deployment platform:

```bash
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET=<generate with: rails secret>
SECRET_KEY_BASE=<generate with: rails secret>
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_USERNAME=apikey
SMTP_PASSWORD=<your_sendgrid_key>
FROM_EMAIL=hello@justinnegron.dev
FRONTEND_URL=https://justinnegron.dev
AWS_ACCESS_KEY_ID=<your_key>
AWS_SECRET_ACCESS_KEY=<your_secret>
RAILS_ENV=production
```

### Docker Production Build

```bash
docker build -t portfolio-backend .
docker run -p 3000:3000 portfolio-backend
```

### AWS ECS Deployment

See `infrastructure/README.md` for detailed deployment instructions.

## 📁 Project Structure

```
backend/
├── app/
│   ├── controllers/api/v1/    # API endpoints
│   ├── models/                # Data models
│   ├── serializers/           # JSON serializers
│   ├── mailers/               # Email templates
│   └── jobs/                  # Background jobs
├── config/
│   ├── routes.rb              # API routes
│   ├── database.yml           # DB config
│   └── initializers/          # App configuration
├── db/
│   ├── migrate/               # Database migrations
│   └── seeds.rb               # Sample data
├── spec/                      # Test suite
├── docker-compose.yml         # Docker services
└── Dockerfile                 # Production image

```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

Private - All Rights Reserved

## 🐛 Troubleshooting

### Database connection errors

```bash
# Restart Docker services
docker compose down
docker compose up -d

# Verify they're running
docker compose ps
```

### Redis connection errors

```bash
# Check Redis
docker compose exec redis redis-cli ping
# Should return: PONG
```

### Test failures

```bash
# Reset test database
RAILS_ENV=test rails db:drop db:create db:migrate
```

### Port already in use

```bash
# Kill process on port 3000
lsof -ti:3000 | xargs kill -9
```

## 📞 Support

For issues or questions, contact: your.email@example.com