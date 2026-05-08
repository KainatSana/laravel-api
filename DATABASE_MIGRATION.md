# PitCrew Database Migration: MySQL → PostgreSQL + Cloud SQL

**Date:** May 8, 2026  
**Status:** ✅ Infrastructure Ready | ⏳ Pending Initial Setup

---

## 📊 Migration Overview

### Current State
- **Previous**: MySQL on Cloud SQL  
- **New**: PostgreSQL 15 on Cloud SQL  
- **Infrastructure**: Cloud SQL instances already provisioned (dev & prod)  
- **ORM**: Laravel with Eloquent  
- **Auth**: Passport OAuth2

### Infrastructure
| Environment | Instance | Database | User | Port |
|-------------|----------|----------|------|------|
| **Dev** | `pitcrew-db-dev` | `pitcrew_db` | `postgres` | 5432 |
| **Prod** | `pitcrew-db-prod` | `pitcrew_db` | `postgres` | 5432 |

---

## 🗄️ Database Schema

### Tables Created
Created 8 comprehensive migrations covering:

#### 1. **Users & Authentication** (Passport OAuth2)
- `users` - User accounts with role support
- `oauth_clients` - OAuth applications
- `oauth_access_tokens` - Bearer tokens for API access
- `oauth_refresh_tokens` - Token refresh mechanism
- `oauth_auth_codes` - Authorization code flow

#### 2. **Access Control**
- `roles` - User roles (admin, manager, user)
- `permissions` - Permission definitions
- `role_permissions` - Role-permission associations
- `user_roles` - User-role assignments

#### 3. **Business Domain**
- `customers` - Customer records with contact info
- `vehicles` - Customer vehicles (VIN, license plate, model, etc.)
- `repair_orders` - Service orders with status tracking
- `campaigns` - Marketing campaigns (email, SMS, offers)
- `reward_cards` - Loyalty program cards with balance

---

## 🔗 Cloud SQL Configuration

### Connection Details

**Development:**
```
Instance: watchful-force-495414-t4:us-east4:pitcrew-db-dev
Host: 127.0.0.1 (via Cloud SQL Auth Proxy)
Socket: /cloudsql/watchful-force-495414-t4:us-east4:pitcrew-db-dev
Database: pitcrew_db
User: postgres
```

**Production:**
```
Instance: watchful-force-495414-t4:us-east4:pitcrew-db-prod
Host: 127.0.0.1 (via Cloud SQL Auth Proxy)
Socket: /cloudsql/watchful-force-495414-t4:us-east4:pitcrew-db-prod
Database: pitcrew_db
User: postgres
```

### Cloud SQL Auth Proxy
- **Purpose**: Secure encrypted connection from Cloud Run to Cloud SQL
- **Mechanism**: Unix socket at `/cloudsql/{INSTANCE_CONNECTION_NAME}`
- **Advantages**: Zero-trust, IAM-based, no exposed ports, encrypted SSL/TLS
- **Configured**: `--add-cloudsql-instances` flag in Cloud Build

---

## 📝 Laravel Configuration

### Updated Files
- `config/database.php` - Added PostgreSQL driver configuration
- `.env` - Updated to use pgsql, Cloud SQL connection details
- `cloudbuild.yaml` - Development pipeline with PostgreSQL + Cloud SQL
- `cloudbuild-prod.yaml` - Production pipeline with PostgreSQL + Cloud SQL

### Environment Variables
```env
DB_CONNECTION=pgsql
DB_HOST=/cloudsql/watchful-force-495414-t4:us-east4:pitcrew-db-dev
DB_PORT=5432
DB_DATABASE=pitcrew_db
DB_USERNAME=postgres
DB_PASSWORD=<SECRET> (from Secret Manager)
DB_SSLMODE=prefer
```

---

## 🚀 Deployment Flow

### How It Works
1. **Developer pushes code** → Git webhook triggers Cloud Build
2. **Cloud Build:**
   - Builds Docker image (Laravel 8 with PostgreSQL support)
   - Pushes to Artifact Registry
   - Deploys to Cloud Run with `--add-cloudsql-instances` flag
   - Injects secrets (APP_KEY, DB_PASSWORD)
3. **Cloud Run startup:**
   - Cloud SQL Auth Proxy automatically starts (managed by Cloud Run)
   - Creates Unix socket at `/cloudsql/{INSTANCE_CONNECTION_NAME}`
   - PHP-FPM connects via socket
   - nginx routes requests to PHP-FPM
4. **Application:**
   - Laravel connects via PostgreSQL driver
   - Uses Cloud SQL Auth Proxy socket
   - Executes migrations (if configured)

### Cloud Build Integration
Both pipelines updated:
- Development (`cloudbuild.yaml`): Automatic on `git push origin main`
- Production (`cloudbuild-prod.yaml`): Manual on `git tag v*.*.* && git push origin v*.*.*`

---

## ⚙️ Database Initialization

### Prerequisites
- Cloud SQL PostgreSQL instances created (✅ Done via Terraform)
- Laravel migrations created (✅ 8 migrations ready)
- Cloud Build configured (✅ Updated to use PostgreSQL)

### Initial Setup Steps

**Step 1: Create PostgreSQL User** (One-time)
```bash
# Connect to Cloud SQL instance (via Cloud Shell or proxy)
psql -h /cloudsql/watchful-force-495414-t4:us-east4:pitcrew-db-dev \
     -U postgres \
     -d postgres

# Create user with password
CREATE USER laravel_user WITH PASSWORD 'secure_password';

# Grant privileges
GRANT CREATE ON DATABASE pitcrew_db TO laravel_user;
GRANT USAGE ON SCHEMA public TO laravel_user;
GRANT CREATE ON SCHEMA public TO laravel_user;
```

**Step 2: Run Laravel Migrations** (After deployment)
```bash
# Option A: Local testing
php artisan migrate --database=pgsql

# Option B: Via Cloud Run service
gcloud run services exec laravel-api --command="php artisan migrate"

# Option C: In Cloud Build (add migration step)
# (Requires database connection during build)
```

**Step 3: Seed Initial Data** (Optional)
```bash
php artisan db:seed
```

---

## 🔐 Security

### Best Practices Implemented
✅ Cloud SQL Auth Proxy (zero-trust network access)  
✅ Secrets Manager for credentials (not in code)  
✅ SSL/TLS encryption in transit  
✅ IAM-based authentication (service account)  
✅ Separate dev/prod databases  

### Credentials Management
- `APP_KEY` → Secret Manager (`laravel-app-key`)
- `DB_PASSWORD` → Secret Manager (`laravel-db-password`)
- Injected at runtime via Cloud Build `--set-secrets`

---

## 📊 Migration Progress

| Task | Status | Details |
|------|--------|---------|
| Cloud SQL Provisioning | ✅ | Terraform deployed (PostgreSQL 15) |
| Laravel Migrations | ✅ | 8 schema migrations created |
| Database Config | ✅ | PostgreSQL driver configured |
| Cloud Build Updates | ✅ | Dev & Prod pipelines updated |
| Cloud SQL Auth Proxy | ✅ | Configured in Cloud Run deployment |
| Database Initialization | ⏳ | User creation & initial migrations pending |
| Data Migration | ⏳ | Migrate existing MySQL data (if applicable) |
| Validation & Testing | ⏳ | Verify connectivity and schema |

---

## 🧪 Testing & Validation

### Connectivity Test
```bash
# After Cloud Run deployment
curl https://laravel-api-<ID>.us-central1.run.app/health

# Expected response
{
  "status": "healthy",
  "environment": "production",
  "timestamp": "2026-05-08T02:25:08+00:00"
}
```

### Migration Verification
```bash
# Check schema creation
php artisan migrate:status

# Verify tables exist
psql -h <cloud-sql-host> -U postgres -d pitcrew_db -c "\dt"
```

---

## 🔄 Next Steps

1. **Create PostgreSQL user** in Cloud SQL instance
2. **Test Cloud Run ↔ Cloud SQL connectivity**
3. **Run initial migrations** to create schema
4. **Load seed data** (if applicable)
5. **Validate all endpoints** with new database
6. **Monitor Cloud Run logs** for any issues
7. **Plan data migration** from AWS RDS (if needed)

---

## 📚 References

- [Cloud SQL PostgreSQL Documentation](https://cloud.google.com/sql/docs/postgres)
- [Cloud SQL Auth Proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy)
- [Laravel PostgreSQL Driver](https://laravel.com/docs/8.x/database#introduction)
- [Passport OAuth2 Documentation](https://laravel-passport.readthedocs.io/)

---

**Last Updated:** May 8, 2026  
**Next Review:** After initial deployment and validation
