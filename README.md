# Simple Laravel 8 API - Multi-Stage Docker

A **minimal, easy-to-understand Laravel 8 API** with multi-stage Docker containerization for Dev/Staging/Production.

---

## Files Structure

```
laravel8-api-demo/
├── Dockerfile              ← Multi-stage build (dev/staging/prod)
├── docker-compose.yml      ← Run dev environment
├── docker/
│   └── nginx.conf          ← Web server config
├── config/
│   ├── app.php            ← App configuration
│   └── database.php       ← DB configuration
├── app/
│   └── Http/
│       └── Kernel.php
├── routes/
│   └── api.php            ← API endpoints
├── public/
│   └── index.php          ← Web entry point
├── bootstrap/
│   └── app.php            ← App bootstrap
├── storage/               ← Logs, cache
├── composer.json          ← PHP dependencies
├── .env.example           ← Environment template
├── .dockerignore          ← Exclude from Docker
└── README.md              ← This file
```

---

## Multi-Stage Dockerfile

One Dockerfile creates **three environments**:

```
Stage 1: Builder
└─ Install dependencies (shared by all stages)

Stage 2: Development
├─ Size: Larger
├─ Tools: vim, curl, debug
└─ For: Local development

Stage 3: Staging  
├─ Size: Smaller
├─ Optimized code cache
└─ For: Testing before production

Stage 4: Production
├─ Size: Smallest
├─ Non-root user
├─ OPcache optimization
└─ For: Live servers
```

---

## Quick Start

### Prerequisites
```bash
docker --version    # Should be 20.x or higher
docker-compose --version
```

### Setup (5 minutes)

```bash
# 1. Clone/navigate to project
cd /Users/dev/Documents/Repos/laravel8-api-demo

# 2. Start containers
docker-compose up -d

# 3. Install dependencies
docker-compose exec app composer install

# 4. Generate key
docker-compose exec app php artisan key:generate

# 5. Test health endpoint
curl http://localhost/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "environment": "local",
  "timestamp": "2024-05-04T10:30:45.000000Z"
}
```

---

## What's Included

### Services (docker-compose)
- **Laravel App** (PHP-FPM) on port 9000
- **Nginx** (Web server) on port 80
- **MySQL** (Database) on port 3306

### API Endpoints
```
GET  /api/health    ← Health check
GET  /api/ready     ← Readiness check
GET  /api/v1/status ← API status
```

### Environment Variables
```
APP_ENV=local|staging|production
APP_DEBUG=true|false
DB_CONNECTION=mysql
DB_HOST=mysql (Docker hostname)
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=laravel_password
```

---

## Building Images

### Build individual stages:

```bash
# Development
docker build --target=development -t laravel:dev .

# Staging
docker build --target=staging -t laravel:staging .

# Production
docker build --target=production -t laravel:prod .
```

### Compare sizes:
```bash
docker images laravel:*
```

Expected:
```
REPOSITORY  TAG        SIZE
laravel     dev        ~600MB
laravel     staging    ~450MB
laravel     prod       ~400MB
```

---

## Test the API

```bash
# Health check
curl http://localhost/health

# Readiness
curl http://localhost/api/ready

# Status
curl http://localhost/api/v1/status
```

---

## Common Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose stop

# Remove everything
docker-compose down

# View logs
docker-compose logs -f app

# Run artisan commands
docker-compose exec app php artisan config:cache

# Access database
docker-compose exec mysql mysql -u laravel_user -p laravel
```

---

## Dockerfile Stages Explained

### Stage 1: Builder
```dockerfile
FROM php:8.1-fpm-alpine AS builder
# Installs dependencies once
# Other stages copy from here
```

### Stage 2: Development
```dockerfile
FROM php:8.1-fpm-alpine AS development
COPY --from=builder /app/vendor ./vendor
# Includes: vim, curl, debug tools
# Size: ~600MB
```

### Stage 3: Staging
```dockerfile
FROM php:8.1-fpm-alpine AS staging
# Optimized with config:cache and route:cache
# Size: ~450MB
```

### Stage 4: Production
```dockerfile
FROM php:8.1-fpm-alpine AS production
RUN useradd www-data  # Non-root user
RUN docker-php-ext-install opcache  # Performance
# Size: ~400MB
# Most secure and optimized
```

---

## Cloud Run Deployment

### Live Service
```
URL: https://laravel-api-184947282681.us-central1.run.app
Health Check: /health.php
Environment: Production
```

### Health Check
```bash
curl https://laravel-api-184947282681.us-central1.run.app/health.php
```

Expected response:
```json
{
  "status": "healthy",
  "environment": "production",
  "timestamp": "2026-05-05T20:55:47+00:00"
}
```

---

## Deploy to Production

### 1. Build production image
```bash
docker build --target=production -t laravel:v1.0.0 .
```

### 2. Tag for registry
```bash
docker tag laravel:v1.0.0 docker.io/username/laravel:v1.0.0
```

### 3. Push
```bash
docker push docker.io/username/laravel:v1.0.0
```

### 4. Run on server
```bash
docker run -d \
  -p 9000:9000 \
  -e APP_ENV=production \
  -e DB_HOST=db.prod \
  -e DB_PASSWORD=secure_pass \
  docker.io/username/laravel:v1.0.0
```

---

## Key Concepts

### Multi-Stage Builds
- One Dockerfile creates multiple images
- Each stage optimized for its purpose
- Later stages copy from earlier stages
- **Benefit:** Reuse dependencies, optimize each environment

### Builder Pattern
- Stage 1 installs dependencies once
- Stages 2-4 copy from Stage 1
- Avoids installing packages multiple times
- **Benefit:** Faster builds, smaller images

### Environment Optimization
- **Dev:** Debug tools, verbose logging
- **Staging:** Production-like, cache enabled
- **Prod:** Minimal, non-root user, OPcache

### Health Checks
- Monitors container health
- Kubernetes uses for auto-restart
- API endpoints: `/health`, `/ready`

---

## Environment Configuration

### .env.example
```
APP_NAME="Laravel API"
APP_ENV=local
APP_DEBUG=true
DB_HOST=127.0.0.1
DB_DATABASE=laravel
DB_USERNAME=laravel_user
DB_PASSWORD=laravel_password
```

Copy to `.env`:
```bash
cp .env.example .env
```

Generate key:
```bash
docker-compose exec app php artisan key:generate
```

---

## Features

[DONE] Multi-stage Docker build  
[DONE] Three environments (dev/staging/prod)  
[DONE] Health checks for monitoring  
[DONE] Environment configuration with .env  
[DONE] Security hardening (non-root user in prod)  
[DONE] Performance optimization (OPcache)  
[DONE] Docker Compose for local development  
[DONE] Nginx reverse proxy  
[DONE] MySQL database  

---

## Troubleshooting

### Port already in use
```bash
# Change port in docker-compose.yml
ports:
  - "8080:80"  # Use 8080 instead of 80
```

### Cannot connect to database
```bash
# Check MySQL is running
docker-compose ps

# Restart MySQL
docker-compose restart mysql
```

### Composer permission denied
```bash
# Run as www-data user
docker-compose exec -u www-data app composer install
```

### Storage directory permissions
```bash
docker-compose exec app chmod -R 755 storage
docker-compose exec app chown -R www-data:www-data storage
```

---

## Official Documentation

- **Laravel**: https://laravel.com/docs/8.x
- **Docker**: https://docs.docker.com/
- **Docker Compose**: https://docs.docker.com/compose/
- **PHP**: https://www.php.net/manual/

---

## What You Learned

- Multi-stage Docker builds  
- Building for dev/staging/prod  
- Image size optimization  
- Health checks in Docker  
- Environment configuration  
- Security best practices  
- Docker Compose usage  
- Laravel 8 API basics

---

**Ready to use! Happy coding!**
