#!/bin/sh

echo "[INIT] Container started at $(date)"
echo "[INIT] Running as user: $(whoami)"
echo "[INIT] Current directory: $(pwd)"

# Check if PHP-FPM exists
if ! command -v php-fpm > /dev/null 2>&1; then
  echo "[ERROR] PHP-FPM NOT found"
  exit 1
fi
echo "[INIT] ✓ PHP-FPM found: $(which php-fpm)"

# Check if nginx exists
if ! command -v nginx > /dev/null 2>&1; then
  echo "[ERROR] Nginx NOT found"
  exit 1
fi
echo "[INIT] ✓ Nginx found: $(which nginx)"

# Test nginx syntax
echo "[INIT] Validating nginx configuration..."
nginx -t || {
  echo "[ERROR] Nginx configuration validation failed"
  exit 1
}

# Start PHP-FPM in background
echo "[INIT] Starting PHP-FPM..."
php-fpm -D || {
  echo "[ERROR] Failed to start PHP-FPM"
  exit 1
}
echo "[INIT] ✓ PHP-FPM started successfully"

# Sleep briefly to ensure PHP-FPM is ready
sleep 1

# Verify PHP-FPM is listening
if ! netstat -tuln 2>/dev/null | grep -q 9000; then
  echo "[WARN] PHP-FPM port 9000 not detected, but continuing..."
fi

# Start nginx in foreground
echo "[INIT] Starting Nginx in foreground..."
exec nginx -g 'daemon off;'
