#!/bin/bash
set -e

echo "[$(date)] Starting Laravel container initialization..."

if [ -f /var/run/secrets/cloud.google.com/service_account/identity ]; then
  echo "[$(date)] Cloud Run detected - loading secrets from Secret Manager..."

  # Get credentials from Cloud Run's mounted service account
  IDENTITY_TOKEN=$(cat /var/run/secrets/cloud.google.com/service_account/identity)
  PROJECT_ID=$(cat /var/run/secrets/cloud.google.com/service_account/project_id)

  # Access Secret Manager via REST API with timeout
  get_secret() {
    local secret_name=$1
    curl -s --connect-timeout 5 --max-time 10 \
      -H "Authorization: Bearer $IDENTITY_TOKEN" \
      "https://secretmanager.googleapis.com/v1/projects/$PROJECT_ID/secrets/$secret_name/versions/latest:access" \
      | jq -r '.payload.data' | base64 -d
  }

  echo "[$(date)] Fetching APP_KEY from Secret Manager..."
  export APP_KEY=$(get_secret "laravel-app-key")

  echo "[$(date)] Fetching DB_PASSWORD from Secret Manager..."
  export DB_PASSWORD=$(get_secret "laravel-db-password")

  echo "[$(date)] Secrets loaded successfully"
else
  echo "[$(date)] Local development mode - using default credentials"
  export DB_HOST="mysql"
  export APP_KEY="base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI="
  export DB_PASSWORD="laravel_password"
fi

echo "[$(date)] Running database migrations..."
php artisan migrate --force || echo "[$(date)] WARNING: Migrations failed or already applied"

echo "[$(date)] Caching Laravel configuration..."
php artisan config:cache

echo "[$(date)] Laravel initialization complete - starting PHP-FPM"
exec php-fpm
