#!/bin/bash
set -e

if [ -f /var/run/secrets/cloud.google.com/service_account/identity ]; then
  echo "Cloud Run detected - loading secrets from Secret Manager..."
  export APP_KEY=$(gcloud secrets versions access latest --secret="laravel-app-key")
  export DB_PASSWORD=$(gcloud secrets versions access latest --secret="laravel-db-password")
else
  echo "Local development..."
  export DB_HOST="mysql"
  export APP_KEY="base64:xIIBXqpGxb9O8VGYvZWZq/SkXQDNKSJpLIhLVwuJaPI="
  export DB_PASSWORD="laravel_password"
fi

php artisan migrate --force
php artisan config:cache
exec php-fpm
