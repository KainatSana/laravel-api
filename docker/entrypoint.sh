#!/bin/bash

echo "[$(date)] Entrypoint script started"
echo "[$(date)] Bash version: $BASH_VERSION"
echo "[$(date)] Working directory: $(pwd)"
echo "[$(date)] USER: $(whoami)"
echo "[$(date)] Starting Laravel container initialization..."

# Don't exit on error - we want to start Nginx even if secrets fail
set +e

if [ -f /var/run/secrets/cloud.google.com/service_account/identity ]; then
  echo "[$(date)] Cloud Run detected - attempting to load secrets from Secret Manager..."

  # Get credentials from Cloud Run's mounted service account
  IDENTITY_TOKEN=$(cat /var/run/secrets/cloud.google.com/service_account/identity 2>/dev/null)
  PROJECT_ID=$(cat /var/run/secrets/cloud.google.com/service_account/project_id 2>/dev/null)

  if [ -z "$IDENTITY_TOKEN" ] || [ -z "$PROJECT_ID" ]; then
    echo "[$(date)] WARNING: Could not read service account credentials"
  else
    # Access Secret Manager via REST API with timeout
    get_secret() {
      local secret_name=$1
      curl -s --connect-timeout 5 --max-time 10 \
        -H "Authorization: Bearer $IDENTITY_TOKEN" \
        "https://secretmanager.googleapis.com/v1/projects/$PROJECT_ID/secrets/$secret_name/versions/latest:access" \
        2>/dev/null | jq -r '.payload.data' 2>/dev/null | base64 -d 2>/dev/null
    }

    echo "[$(date)] Attempting to fetch APP_KEY..."
    APP_KEY_VALUE=$(get_secret "laravel-app-key")
    if [ ! -z "$APP_KEY_VALUE" ]; then
      export APP_KEY="$APP_KEY_VALUE"
      echo "[$(date)] APP_KEY loaded successfully"
    else
      echo "[$(date)] WARNING: Failed to load APP_KEY from Secret Manager"
    fi

    echo "[$(date)] Attempting to fetch DB_PASSWORD..."
    DB_PASSWORD_VALUE=$(get_secret "laravel-db-password")
    if [ ! -z "$DB_PASSWORD_VALUE" ]; then
      export DB_PASSWORD="$DB_PASSWORD_VALUE"
      echo "[$(date)] DB_PASSWORD loaded successfully"
    else
      echo "[$(date)] WARNING: Failed to load DB_PASSWORD from Secret Manager"
    fi
  fi
else
  echo "[$(date)] Local development mode - using default credentials"
  export DB_HOST="mysql"
  export APP_KEY="base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI="
  export DB_PASSWORD="laravel_password"
fi

# Ensure defaults are set if secrets failed to load
export APP_KEY="${APP_KEY:-base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI=}"
export DB_PASSWORD="${DB_PASSWORD:-laravel_password}"

# Re-enable exit on error
set -e

if [ "$SKIP_MIGRATIONS" != "true" ]; then
  echo "[$(date)] Running database migrations..."
  php artisan migrate --force || echo "[$(date)] WARNING: Migrations failed or already applied"
else
  echo "[$(date)] Skipping migrations (SKIP_MIGRATIONS=true)"
fi

echo "[$(date)] Caching Laravel configuration..."
php artisan config:cache

echo "[$(date)] Laravel initialization complete - starting services"

echo "[$(date)] Checking if php-fpm exists..."
which php-fpm && echo "[$(date)] php-fpm found" || echo "[$(date)] ERROR: php-fpm NOT found"

echo "[$(date)] Checking if nginx exists..."
which nginx && echo "[$(date)] nginx found" || echo "[$(date)] ERROR: nginx NOT found"

echo "[$(date)] Starting PHP-FPM in background..."
php-fpm -D
FPM_PID=$!
echo "[$(date)] PHP-FPM started with PID: $FPM_PID"

# Start Nginx in foreground (this becomes the main process)
echo "[$(date)] Starting Nginx on port 8080..."
echo "[$(date)] About to execute: nginx -g 'daemon off;'"
exec nginx -g 'daemon off;'
echo "[$(date)] ERROR: This line should never be reached!"
