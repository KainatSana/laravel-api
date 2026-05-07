#!/bin/bash
set -e

if [ -f /var/run/secrets/cloud.google.com/service_account/identity ]; then
  echo "Cloud Run detected - loading secrets from Secret Manager..."

  # Get credentials from Cloud Run's mounted service account
  IDENTITY_TOKEN=$(cat /var/run/secrets/cloud.google.com/service_account/identity)
  PROJECT_ID=$(cat /var/run/secrets/cloud.google.com/service_account/project_id)

  # Access Secret Manager via REST API
  get_secret() {
    local secret_name=$1
    curl -s -H "Authorization: Bearer $IDENTITY_TOKEN" \
      "https://secretmanager.googleapis.com/v1/projects/$PROJECT_ID/secrets/$secret_name/versions/latest:access" \
      | jq -r '.payload.data' | base64 -d
  }

  export APP_KEY=$(get_secret "laravel-app-key")
  export DB_PASSWORD=$(get_secret "laravel-db-password")

  echo "Secrets loaded successfully"
else
  echo "Local development..."
  export DB_HOST="mysql"
  export APP_KEY="base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI="
  export DB_PASSWORD="laravel_password"
fi

php artisan migrate --force
php artisan config:cache
exec php-fpm
