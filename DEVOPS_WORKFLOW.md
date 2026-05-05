# Complete DevOps Workflow: From Analysis to Deployment

**A Step-by-Step Guide to Understanding Our DevOps Process for Laravel 8 API Containerization**

---

## Overview: The Complete Journey

```
START: Raw Laravel 8 API Application
  ↓
STEP 1: Analyze Application
  ↓
STEP 2: Identify Dependencies
  ↓
STEP 3: Make Architecture Decisions
  ↓
STEP 4: Design Multi-Stage Dockerfile
  ↓
STEP 5: Create Docker Compose Setup
  ↓
STEP 6: Test and Verify
  ↓
STEP 7: Deploy to Production
  ↓
END: Running Production Application
```

---

## STEP 1: Application Analysis

### What We Started With

We had a Laravel 8 API project with these files:

```
laravel8-api-demo/
├── composer.json          ← PHP dependencies definition
├── app/                   ← Application code
├── config/                ← Configuration files
├── routes/                ← API routes definition
├── public/                ← Web root
├── storage/               ← Logs, cache
├── bootstrap/             ← Bootstrap configuration
└── database/              ← Database files
```

### Questions We Asked

**1. What language and framework?**
```
Answer: PHP 8.1 with Laravel 8
Source: composer.json (shows laravel/framework)
Found in: composer.json line 14
```

**2. What database?**
```
Answer: MySQL (PDO driver)
Source: composer.json (shows laravel/framework which uses MySQL)
Found in: config/database.php
Decision Impact: Need PDO MySQL PHP extension
```

**3. What web server?**
```
Answer: Nginx (reverse proxy)
Reason: Modern standard, separates concerns
Decision Impact: Need separate Nginx container
```

**4. How many environments?**
```
Answer: Development, Staging, Production
Why: Different needs for each phase
Development: Full debugging
Staging: Production simulation
Production: Optimized, secure
```

**5. What dependencies from composer.json?**

```json
{
  "require": {
    "php": "^8.1",
    "laravel/framework": "^8.0"
  }
}
```

**Implications:**
- PHP 8.1+ is REQUIRED
- Laravel 8 framework is REQUIRED
- These must be in Docker image

---

## STEP 2: Identify All Dependencies

### File-by-File Dependency Analysis

#### composer.json
```
File: composer.json
Purpose: Lists all PHP dependencies
Content: 
  - php: ^8.1 (PHP version requirement)
  - laravel/framework: ^8.0 (Laravel version)
  - Other packages for API functionality

Dependency Impact:
  ✓ PHP 8.1 must be in Dockerfile
  ✓ Composer must install dependencies
  ✓ Vendor folder will be created
```

#### config/database.php
```
File: config/database.php
Purpose: Database connection configuration
Key Settings:
  - default: 'mysql' (uses MySQL)
  - mysql:
    - host: env('DB_HOST')
    - database: env('DB_DATABASE')
    - username: env('DB_USERNAME')
    - password: env('DB_PASSWORD')

Dependency Impact:
  ✓ Need pdo_mysql PHP extension
  ✓ Need MySQL container
  ✓ Need environment variables in docker-compose
```

#### routes/api.php
```
File: routes/api.php
Purpose: Defines API endpoints
Key Routes:
  - /health (health check)
  - /api/ready (readiness check)
  - /api/v1/status (API status)

Dependency Impact:
  ✓ Need health check endpoint in Dockerfile
  ✓ Needed for monitoring
```

#### .env.example
```
File: .env.example
Purpose: Environment variable template
Key Variables:
  - APP_NAME=Laravel API
  - APP_ENV=local
  - APP_DEBUG=true
  - DB_HOST=127.0.0.1
  - DB_DATABASE=laravel
  - DB_USERNAME=laravel_user
  - DB_PASSWORD=laravel_password

Dependency Impact:
  ✓ Must be set in docker-compose.yml
  ✓ Different values per environment
```

#### docker/ (if exists)
```
File: docker/nginx.conf (or similar)
Purpose: Nginx configuration
Key Settings:
  - upstream php_backend { server app:9000; }
  - listen 80
  - fastcgi_pass php_backend

Dependency Impact:
  ✓ Nginx needs this config
  ✓ Defines how Nginx talks to PHP-FPM
```

---

## STEP 3: Architecture Decisions & Why

### Decision 1: Base Image

**What We Chose:** `php:8.1-fpm-alpine`

**Decision Process:**

```
Requirement: PHP 8.1
         ↓
Available Options:
  - php:8.1 (Debian) ────→ 200MB ❌ Too large
  - php:8.1-apache ───→ 300MB ❌ Wrong web server
  - php:8.1-cli ──────→ 100MB ❌ No web server
  - php:8.1-fpm-alpine → 70MB  ✅ PERFECT
         ↓
Why FPM?
  - FastCGI Process Manager
  - Works with Nginx separately
  - Lightweight memory usage
  - Industry standard
         ↓
Why Alpine?
  - Only 70MB (vs 200MB Debian)
  - Minimal = more secure
  - Faster to download
  - Faster to deploy
```

**File References:**
- composer.json: Line 14 specifies "php": "^8.1"
- Decision made based on: PHP version requirement

---

### Decision 2: Database Container

**What We Chose:** `mysql:8.0`

**Decision Process:**

```
config/database.php says:
  'default' => 'mysql'
         ↓
Check available MySQL versions:
  - 5.7 (old, deprecated) ❌
  - 8.0 (latest stable) ✅
  - 8.1 (too new, less tested) ⚠️
         ↓
Decision: MySQL 8.0
  - Latest stable
  - Well-tested
  - Security patches
  - Good performance
```

**File References:**
- config/database.php: Shows MySQL is required
- .env.example: Shows DB configuration variables

---

### Decision 3: Multi-Stage Dockerfile

**What We Chose:** 4 stages (builder, dev, staging, prod)

**Decision Process:**

```
Need: Three different environments
         ↓
Option A: Three separate Dockerfiles
  - Dockerfile.dev
  - Dockerfile.staging
  - Dockerfile.prod
  Problem: Code duplication ❌
         ↓
Option B: One Dockerfile with multiple stages
  - Stage 1: Builder (shared)
  - Stage 2: Development
  - Stage 3: Staging
  - Stage 4: Production
  Benefit: No duplication ✅
         ↓
Decision: Multi-stage
  Why: Easier to maintain
       Smaller images
       Consistent codebase
       Industry standard
```

**File References:**
- composer.json: Tells us what to install
- config/database.php: Tells us what extensions needed
- routes/api.php: Tells us what endpoints exist

---

### Decision 4: PHP Extensions

**What We Chose:** pdo_mysql

**Decision Process:**

```
From config/database.php:
  'default' => 'mysql'
         ↓
This means: Need MySQL driver
         ↓
In PHP, MySQL driver is: pdo_mysql
         ↓
Decision: docker-php-ext-install pdo_mysql
  - Required for database connection
  - Used by Laravel PDO
```

**File References:**
- config/database.php: Shows MySQL requirement

---

### Decision 5: Environment Variables

**What We Chose:** .env files + docker-compose.yml

**Decision Process:**

```
From .env.example:
  DB_HOST=127.0.0.1
  DB_DATABASE=laravel
  DB_USERNAME=laravel_user
  DB_PASSWORD=laravel_password
         ↓
Problem: Hardcoding secrets in Dockerfile is dangerous
         ↓
Solution: Use environment variables
         ↓
Implementation:
  - .env.example → committed to git (template)
  - .env → local only (not committed)
  - docker-compose.yml → references .env variables
         ↓
Decision Rationale:
  - Secrets stay out of images
  - Different values per environment
  - Easy to change per deployment
```

**File References:**
- .env.example: Template for environment variables
- docker-compose.yml: How to pass variables

---

## STEP 4: Design & Create Dockerfile

### Dockerfile Design Process

**Stage 1: Builder**

```dockerfile
FROM php:8.1-fpm-alpine AS builder
# Why this base?
#   - composer.json requires PHP 8.1
#   - Alpine is 70MB (minimal)
#   - FPM works with Nginx

WORKDIR /app
# Why /app?
#   - Standard Laravel convention
#   - Clean, organized structure

RUN apk add --no-cache curl git
# Why?
#   - curl: needed for composer
#   - git: might be needed for packages

RUN docker-php-ext-install pdo_mysql
# Why?
#   - config/database.php requires MySQL
#   - Need PDO driver for Laravel

COPY . .
# Why?
#   - Copy application code
#   - Need it for all stages
```

**Purpose of Builder Stage:**
```
Problem: Installation repeated in each stage
Solution: Install once in builder, reuse in all stages

Result:
  - Faster builds (no duplication)
  - Smaller final images (no duplication)
  - Single source of truth
```

---

**Stage 2: Development**

```dockerfile
FROM php:8.1-fpm-alpine AS development

# Base image again because:
#   - Docker stages are independent
#   - Can't inherit directly
#   - Must start fresh

RUN apk add --no-cache curl git vim bash
# Why these tools?
#   - curl: test endpoints (from routes/api.php)
#   - git: version control in container
#   - vim: edit files in container
#   - bash: better shell for developers

COPY --from=builder /app /app
# Why from builder?
#   - Reuse code and dependencies
#   - Avoid duplicating installations
#   - Faster builds

ENV APP_ENV=local
ENV APP_DEBUG=true
# Why?
#   - .env.example shows development values
#   - Developers need error details
#   - APP_DEBUG=true shows full errors

HEALTHCHECK --interval=30s CMD curl -f http://localhost:9000/health || exit 1
# Why?
#   - routes/api.php has /health endpoint
#   - Docker needs to know if app is healthy
#   - Auto-restart on failure
```

**Purpose of Development Stage:**
```
For: Developers working locally
Has:
  - Debugging tools (vim, bash)
  - Full error output (APP_DEBUG=true)
  - All utilities for development
Size: 175MB (tools are OK here)
```

---

**Stage 3: Staging**

```dockerfile
FROM php:8.1-fpm-alpine AS staging

RUN apk add --no-cache curl git
# Why less than dev?
#   - Staging should be production-like
#   - No vim (not needed in testing)
#   - Keep curl for health checks

COPY --from=builder /app /app
# Same as development (reuse)

ENV APP_ENV=staging
ENV APP_DEBUG=false
# Why?
#   - .env.example pattern
#   - Test production conditions
#   - Don't expose errors to testers

HEALTHCHECK --interval=30s CMD curl -f http://localhost:9000/health || exit 1
```

**Purpose of Staging Stage:**
```
For: Testing environment
Has:
  - Production-like configuration
  - Limited debugging (realistic)
  - Performance tuned
Size: 129MB (optimized)
```

---

**Stage 4: Production**

```dockerfile
FROM php:8.1-fpm-alpine AS production

RUN docker-php-ext-install pdo_mysql opcache
# Why opcache here?
#   - Production needs 2-3x speed boost
#   - Bytecode caching (faster execution)
#   - Not needed in dev (need fresh code)

COPY --from=builder /app /app
# Same as others (reuse builder)

RUN chown -R www-data:www-data /app
USER www-data
# Why non-root user?
#   - Security hardening
#   - If compromised, limited damage
#   - Industry best practice
#   - www-data already exists in php:8.1-fpm-alpine

ENV APP_ENV=production
ENV APP_DEBUG=false
# Why?
#   - .env.example pattern
#   - Hide errors from users
#   - Production security

HEALTHCHECK --interval=30s CMD curl -f http://localhost:9000/health || exit 1
```

**Purpose of Production Stage:**
```
For: Live servers
Has:
  - OPcache (2-3x faster)
  - Non-root user (security)
  - Minimal tools (smaller)
  - No debug output (secure)
Size: 118MB (minimal & optimized)
```

---

## STEP 5: Create Docker Compose Setup

### Why Docker Compose?

```
Problem: Need 3 services to work together
  - PHP-FPM (app)
  - Nginx (web server)
  - MySQL (database)

Solution: Docker Compose
  - One file defines all 3
  - One command starts all 3
  - Networking automatic
  - Volumes managed
```

### docker-compose.yml Design

```yaml
services:
  app:
    build:
      target: development      # Use dev stage
    # Why dev stage?
    #   - Development image has debugging tools
    #   - Developers work locally

    ports:
      - "9000:9000"
    # Why port 9000?
    #   - PHP-FPM standard port
    #   - Not HTTP, just application

    environment:
      DB_HOST: mysql           # Service name from docker-compose
      DB_DATABASE: laravel     # From .env.example
      DB_USERNAME: laravel_user
      DB_PASSWORD: laravel_password
    # Why these?
    #   - config/database.php reads these
    #   - Must match .env.example

    depends_on:
      - mysql
    # Why?
    #   - App needs database running first

  nginx:
    image: nginx:1.25-alpine
    # Why separate?
    #   - Nginx not in app container
    #   - Can scale independently
    #   - Clear separation of concerns

    ports:
      - "80:80"
    # Why port 80?
    #   - HTTP traffic from users
    #   - Nginx listens here

    volumes:
      - ./docker/nginx.conf:/etc/nginx/nginx.conf
    # Why?
    #   - Nginx needs config
    #   - Maps local config to container

    depends_on:
      - app
    # Why?
    #   - Nginx needs app running first

  mysql:
    image: mysql:8.0
    # Why mysql:8.0?
    #   - config/database.php requires MySQL
    #   - 8.0 is latest stable

    environment:
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel_user
      MYSQL_PASSWORD: laravel_password
    # Why these?
    #   - Must match app environment variables
    #   - From .env.example

    volumes:
      - mysql_data:/var/lib/mysql
    # Why?
    #   - Persist data between restarts
    #   - Database survives container restart
```

---

## STEP 6: Build & Verify

### Build Commands

```bash
# Build development image
docker build --target=development -t laravel:dev .
# Why:
#   - --target=development builds only dev stage
#   - Uses dev image (175MB with tools)
#   - For local development

# Build staging image
docker build --target=staging -t laravel:staging .
# Why:
#   - Tests production configuration
#   - Smaller than dev (129MB)
#   - No debug tools

# Build production image
docker build --target=production -t laravel:prod .
# Why:
#   - Optimized for live servers
#   - Smallest (118MB)
#   - OPcache enabled
```

### Verification Steps

```bash
# Check images created
docker images | grep laravel
# Expect:
#   laravel:dev      175MB
#   laravel:staging  129MB
#   laravel:prod     118MB

# Start services
docker-compose up -d
# Expect:
#   ✔ Container app Running
#   ✔ Container nginx Running
#   ✔ Container mysql Running

# Test health endpoint
curl http://localhost/health
# From: routes/api.php /health endpoint
# Expect: { "status": "healthy", ... }

# Check logs
docker-compose logs app
# Look for: Laravel boot messages, no errors
```

---

## STEP 7: Deploy to Production

### Production Deployment Workflow

```
Build for Production
  ├─ docker build --target=production -t laravel:v1.0.0 .
  └─ Result: 118MB production image

Push to Registry
  ├─ docker tag laravel:v1.0.0 registry.com/laravel:v1.0.0
  ├─ docker push registry.com/laravel:v1.0.0
  └─ Result: Image in registry

Deploy to Servers
  ├─ docker run -e DB_HOST=prod-db laravel:v1.0.0
  └─ Result: Running in production

Monitor
  ├─ Health checks every 30 seconds
  ├─ Auto-restart on failure
  └─ Result: High uptime
```

---

## Complete File Dependencies Map

```
composer.json
  ├─ Specifies: PHP 8.1, Laravel 8
  ├─ Impact: Docker base image must be php:8.1-fpm-alpine
  └─ Used in: Dockerfile FROM statement

config/database.php
  ├─ Specifies: MySQL database with PDO
  ├─ Impact: Must install pdo_mysql extension
  ├─ Impact: Need mysql:8.0 container
  └─ Used in: docker-compose.yml environment variables

.env.example
  ├─ Specifies: Environment variable template
  ├─ Impact: Environment values for each stage
  ├─ Impact: APP_ENV and APP_DEBUG values
  └─ Used in: docker-compose.yml environment section

routes/api.php
  ├─ Specifies: /health endpoint exists
  ├─ Impact: Health check endpoint available
  └─ Used in: Dockerfile HEALTHCHECK command

docker/nginx.conf (if custom)
  ├─ Specifies: Nginx configuration
  ├─ Impact: How Nginx talks to PHP-FPM
  └─ Used in: docker-compose.yml volume mount
```

---

## Decision Tree: Why Each Choice

```
START: Containerize Laravel 8 API
  │
  ├─ Choose PHP version
  │  └─ composer.json says PHP 8.1
  │     └─ Choose php:8.1-fpm-alpine (70MB, best)
  │
  ├─ Choose database
  │  └─ config/database.php says MySQL
  │     └─ Choose mysql:8.0 (latest stable)
  │
  ├─ Choose architecture
  │  └─ Need 3 environments
  │     └─ Choose multi-stage (no duplication)
  │
  ├─ Choose web server
  │  └─ Best practice: separate from app
  │     └─ Choose nginx:1.25-alpine (separate container)
  │
  ├─ Choose orchestration
  │  └─ Need to run 3 services locally
  │     └─ Choose Docker Compose (one command)
  │
  ├─ Choose configuration
  │  └─ .env.example shows environment variables
  │     └─ Use .env + docker-compose.yml (secure)
  │
  └─ Choose optimization
     ├─ Development: Add debugging tools (vim, bash)
     ├─ Staging: Remove tools, keep debuggable
     └─ Production: Add OPcache, security hardening
```

---

## Summary: The Complete Workflow

| Phase | Input | Process | Output | Why |
|-------|-------|---------|--------|-----|
| **Analysis** | composer.json, config/ | Identify requirements | PHP 8.1, MySQL, 3 envs | Know what to containerize |
| **Design** | Requirements | Choose technologies | Alpine, multi-stage, compose | Best options available |
| **Build** | Design, code | Create Dockerfile | 4-stage image | Implement design |
| **Compose** | Image | Define services | 3 containers running | Local development |
| **Test** | Running app | Verify functionality | Health checks passing | Ensure it works |
| **Deploy** | Tested image | Push to registry | Production running | Live for users |

---

## Key Learnings

**1. Files Drive Architecture**
```
composer.json  → PHP 8.1
config/database.php → MySQL
.env.example → Environment setup
routes/api.php → Health check endpoint
```

**2. Decisions Based on Requirements**
```
Requirement + Best Practice = Decision
PHP 8.1 + Container best practice = php:8.1-fpm-alpine
Three environments + No duplication = Multi-stage
Debugging needed + Security needed = Different stages
```

**3. Everything Has a Purpose**
```
No unnecessary tools
No duplicate installations
No hardcoded secrets
No oversized images
No complex configurations
```

**4. Each Stage Optimized**
```
Builder: Minimal, shared
Development: Full debugging
Staging: Production-like
Production: Minimal, fast, secure
```

---

## Conclusion

Your DevOps workflow is:

1. **Analyze** - Read application files
2. **Decide** - Choose best technologies
3. **Design** - Plan architecture
4. **Build** - Create Dockerfile
5. **Test** - Verify locally
6. **Deploy** - Run in production

Each decision is backed by file analysis and best practices. The result is a professional, production-ready containerization solution.

**This is how experienced DevOps engineers approach containerization!** 🚀
