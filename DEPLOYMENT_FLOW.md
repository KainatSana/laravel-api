# Laravel 8 API - CI/CD Deployment Pipeline Flow

## 📊 High-Level Architecture

```
GitHub Repository
       ↓
    ┌──────────────────────────────────────┐
    │      Git Webhook Trigger             │
    └──────┬───────────────────────────────┘
           │
    ┌──────┴─────────────────────────────────────────┐
    │                                                 │
    ▼                                                 ▼
DEVELOPMENT PIPELINE                         PRODUCTION PIPELINE
(Automatic on main push)                     (Manual on git tag)
    │                                                 │
    └─ trigger: main branch                         └─ trigger: v*.*.* tags
    │                                                 │
    ▼                                                 ▼
Cloud Build Job                              Cloud Build Job
(cloudbuild.yaml)                            (cloudbuild-prod.yaml)
```

---

## 🔄 DEVELOPMENT PIPELINE (Continuous Deployment)

**Trigger:** `git push origin main`

### Step-by-Step Flow:

```
1. DETECT PUSH
   └─ GitHub detects push to main branch
   └─ Webhook notifies Cloud Build

2. BUILD DOCKER IMAGE
   └─ Cloud Build pulls latest code
   └─ Builds Docker image with target=production
   └─ Tags: :latest and :dev-{SHORT_SHA}
   └─ Pushes to Artifact Registry
   └─ ⏱️ Takes ~3-5 minutes

3. DEPLOY TO CLOUD RUN
   └─ Updates laravel-api service with :latest image
   └─ Sets environment variables:
      ├─ APP_ENV=development
      ├─ APP_DEBUG=true
      ├─ LOG_CHANNEL=stackdriver
      ├─ DB_CONNECTION=mysql
      ├─ DB_HOST=pitcrew-db-dev
      ├─ DB_DATABASE=laravel
      └─ ... (all required variables)
   └─ ⏱️ Takes ~1-2 minutes

4. SERVICE UPDATED
   └─ New version live immediately
   └─ Old traffic gracefully shifted
   └─ Ready for testing

⏱️ TOTAL TIME: ~5-7 minutes
```

### Development Features:
- 🔍 **Debug Mode ON**: `APP_DEBUG=true` shows detailed errors
- 🗄️ **Dev Database**: `pitcrew-db-dev` for isolated testing
- 📝 **Logs**: Sent to Google Cloud Logging (Stackdriver)
- 🔄 **Auto-Deploy**: Every main branch push automatically deploys

---

## 🚀 PRODUCTION PIPELINE (Controlled Release)

**Trigger:** `git tag v1.0.0 && git push origin v1.0.0`

### Step-by-Step Flow:

```
1. CREATE VERSION TAG
   └─ git tag v1.0.0
   └─ git push origin v1.0.0
   └─ GitHub recognizes version tag pattern

2. BUILD DOCKER IMAGE
   └─ Cloud Build pulls tagged commit
   └─ Builds Docker image with target=production
   └─ Tags: :{TAG_NAME} and :latest
   └─ Example: :v1.0.0 and :latest
   └─ Pushes to Artifact Registry
   └─ ⏱️ Takes ~3-5 minutes

3. DEPLOY TO CLOUD RUN
   └─ Updates laravel-api service with :{TAG_NAME} image
   └─ Sets environment variables:
      ├─ APP_ENV=production
      ├─ APP_DEBUG=false (STRICT mode)
      ├─ LOG_CHANNEL=stackdriver
      ├─ DB_CONNECTION=mysql
      ├─ DB_HOST=pitcrew-db-prod (Production DB!)
      ├─ DB_DATABASE=laravel
      └─ ... (all required variables)
   └─ ⏱️ Takes ~1-2 minutes

4. SERVICE UPDATED
   └─ Replaces current production with new version
   └─ Database operations on prod database
   └─ Traffic immediately routed to new version

⏱️ TOTAL TIME: ~5-7 minutes
```

### Production Features:
- 🔒 **Debug Mode OFF**: `APP_DEBUG=false` hides internals
- 🗄️ **Production Database**: `pitcrew-db-prod` (separate from dev)
- 📝 **Logs**: Sent to Google Cloud Logging for monitoring
- 🎯 **Controlled Release**: Only deploy when ready (manual tagging)
- ⚠️ **No Auto-Deploy**: Must explicitly create and push tag

---

## 📋 Key Differences: Dev vs Prod

| Aspect | Development | Production |
|--------|-------------|-----------|
| **Trigger** | `git push origin main` | `git tag v*.*.* && git push origin v*.*.*` |
| **Automation** | Automatic | Manual (tag-based) |
| **Frequency** | Every push | On release |
| **Debug Mode** | ON (`true`) | OFF (`false`) |
| **Database** | `pitcrew-db-dev` | `pitcrew-db-prod` |
| **Error Display** | Detailed errors | Generic errors |
| **Image Tags** | `:latest`, `:dev-{SHA}` | `:v1.0.0`, `:latest` |
| **Deployment Time** | ~5-7 minutes | ~5-7 minutes |

---

## 🔐 Environment Variables Configuration

Both pipelines use **substitutions** defined in the YAML files:

### Development (cloudbuild.yaml)
```yaml
substitutions:
  _DB_HOST: "watchful-force-495414-t4:us-east4:pitcrew-db-dev"
  _DB_NAME: "laravel"
  _DB_USER: "laravel_user"
  _APP_KEY: "base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI="
```

### Production (cloudbuild-prod.yaml)
```yaml
substitutions:
  _DB_HOST: "watchful-force-495414-t4:us-east4:pitcrew-db-prod"
  _DB_NAME: "laravel"
  _DB_USER: "laravel_user"
  _APP_KEY: "base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI="
```

**Note:** Same APP_KEY for both environments (in production, use different keys per environment)

---

## 🛠️ How to Use

### Deploy to Development:
```bash
# Make changes, commit, and push to main
git commit -m "Your changes"
git push origin main
# ✅ Automatic deployment starts immediately
```

### Deploy to Production:
```bash
# Create a version tag
git tag v1.0.0
git push origin v1.0.0
# ✅ Production deployment starts
```

### View Deployment Status:
- Cloud Build Console: Check build logs and progress
- Cloud Run Console: See active revisions and traffic splits
- Cloud Logging: Monitor application logs

---

## 📊 Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                        │
│  • Code (Laravel 8 API)                                     │
│  • cloudbuild.yaml (Dev pipeline)                          │
│  • cloudbuild-prod.yaml (Prod pipeline)                    │
│  • Dockerfile (Multi-stage build)                          │
│  • docker/php-fpm.conf                                     │
│  • docker/nginx.conf                                       │
└──────────┬──────────────────────────────────────────────────┘
           │
           ├─────────────────────────────────────────┐
           │                                         │
           ▼                                         ▼
    ┌─────────────┐                         ┌─────────────┐
    │ Cloud Build │                         │ Cloud Build │
    │ (Dev)       │                         │ (Prod)      │
    └──────┬──────┘                         └──────┬──────┘
           │                                       │
           ▼                                       ▼
    ┌──────────────────┐                  ┌──────────────────┐
    │ Artifact Registry │                  │ Artifact Registry │
    │ (Docker images)   │                  │ (Docker images)   │
    └──────┬───────────┘                  └──────┬───────────┘
           │                                      │
           ▼                                      ▼
    ┌──────────────────┐                  ┌──────────────────┐
    │  Cloud Run Dev   │                  │ Cloud Run Prod    │
    │  (laravel-api)   │                  │ (laravel-api)     │
    │  • App DEBUG=ON  │                  │ • App DEBUG=OFF   │
    └──────┬───────────┘                  └──────┬───────────┘
           │                                      │
           ▼                                      ▼
    ┌──────────────────┐                  ┌──────────────────┐
    │  Cloud SQL Dev   │                  │ Cloud SQL Prod    │
    │  (pitcrew-db-dev)│                  │(pitcrew-db-prod)  │
    └──────────────────┘                  └──────────────────┘
```

---

## ✅ Health Check & Monitoring

Both environments have `/health` endpoint available:

```bash
# Check application health
curl https://laravel-api-[SERVICE-ID].us-central1.run.app/health

# Expected response (200 OK):
{
  "status": "healthy",
  "environment": "production",
  "timestamp": "2026-05-08T02:25:08+00:00"
}
```

The health check:
- ✅ Verifies PHP-FPM is running
- ✅ Verifies nginx is running
- ✅ Verifies database connection
- ✅ Returns timestamp for monitoring

---

## 🚨 Troubleshooting

| Issue | Dev Pipeline | Prod Pipeline |
|-------|--------------|---------------|
| Deployment doesn't start | Check main branch push | Check version tag format |
| Slow build | Normal (5-7 min) | Normal (5-7 min) |
| Wrong database | Check `_DB_HOST` substitution | Check `_DB_HOST` substitution |
| Health check fails | Check dev database connection | Check prod database connection |

---

## 📚 Files Structure

```
laravel8-api/
├── cloudbuild.yaml           ← Dev pipeline (main branch)
├── cloudbuild-prod.yaml      ← Prod pipeline (version tags)
├── Dockerfile                 ← Multi-stage Docker build
├── docker/
│   ├── entrypoint.sh         ← Container startup script
│   ├── php-fpm.conf          ← PHP-FPM configuration
│   └── nginx.conf            ← Nginx configuration
├── routes/
│   └── api.php               ← API routes (includes /health)
└── .env                      ← Local environment (reference)
```

---

**Last Updated:** May 8, 2026  
**Status:** ✅ Production Ready
