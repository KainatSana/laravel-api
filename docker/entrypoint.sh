#!/bin/sh

echo "[INIT] Container started at $(date)"
echo "[INIT] Running as user: $(whoami)"
echo "[INIT] Current directory: $(pwd)"

# Verify PHP-FPM and nginx exist
command -v php-fpm >/dev/null 2>&1 || { echo "[ERROR] PHP-FPM not found"; exit 1; }
command -v nginx >/dev/null 2>&1 || { echo "[ERROR] nginx not found"; exit 1; }

echo "[INIT] ✓ PHP and nginx found"

# Create required directories
mkdir -p /var/run/php-fpm /var/log/nginx /var/lib/nginx /app/storage/logs

# Validate nginx config
echo "[INIT] Validating nginx configuration..."
if ! nginx -t >/dev/null 2>&1; then
  echo "[ERROR] Nginx config validation failed:"
  nginx -t
  exit 1
fi
echo "[INIT] ✓ Nginx config valid"

# Start PHP-FPM in daemon mode
echo "[INIT] Starting PHP-FPM (daemon mode)..."
php-fpm -D
sleep 1

# Verify PHP-FPM started
if ps aux | grep -v grep | grep -q 'php-fpm: master'; then
  echo "[INIT] ✓ PHP-FPM is running"
else
  echo "[ERROR] PHP-FPM failed to start"
  echo "[DEBUG] Process list:"
  ps aux
  echo "[DEBUG] Recent logs:"
  tail -20 /var/log/nginx/error.log 2>/dev/null || echo "No error log"
  exit 1
fi

# Start nginx in foreground
echo "[INIT] Starting nginx..."
exec nginx -g 'daemon off;'
