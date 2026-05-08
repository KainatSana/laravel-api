#!/bin/sh
set -e

echo "[INIT] Container started at $(date)"
echo "[INIT] Running as user: $(whoami)"
echo "[INIT] Current directory: $(pwd)"
echo "[INIT] PHP version: $(php -v | head -n1)"

# Check if PHP-FPM exists
if ! command -v php-fpm > /dev/null 2>&1; then
  echo "[ERROR] PHP-FPM NOT found"
  exit 1
fi
echo "[INIT] ✓ PHP-FPM found"

# Check if nginx exists
if ! command -v nginx > /dev/null 2>&1; then
  echo "[ERROR] Nginx NOT found"
  exit 1
fi
echo "[INIT] ✓ Nginx found"

# Validate nginx configuration
echo "[INIT] Validating nginx configuration..."
if ! nginx -t 2>&1; then
  echo "[ERROR] Nginx configuration validation failed"
  exit 1
fi
echo "[INIT] ✓ Nginx configuration valid"

# Ensure log directories exist and are writable
mkdir -p /var/log/nginx /var/run/php-fpm
chmod 755 /var/log/nginx /var/run/php-fpm

# Start PHP-FPM in background (non-daemon mode, but in background)
echo "[INIT] Starting PHP-FPM..."
php-fpm -F &
FPM_PID=$!
echo "[INIT] PHP-FPM started with PID $FPM_PID"

# Wait for PHP-FPM to be ready
sleep 2

# Check if PHP-FPM is still running
if ! kill -0 $FPM_PID 2>/dev/null; then
  echo "[ERROR] PHP-FPM failed to start or exited immediately"
  exit 1
fi
echo "[INIT] ✓ PHP-FPM is running"

# Start nginx in foreground (this will block, keeping container alive)
echo "[INIT] Starting Nginx in foreground..."
exec nginx -g 'daemon off;'
