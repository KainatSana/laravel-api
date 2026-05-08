#!/bin/sh
set -e

echo "=========================================="
echo "[INIT] Container startup - $(date)"
echo "=========================================="

# Verify required binaries exist
echo "[INIT] Checking required binaries..."
command -v php-fpm >/dev/null 2>&1 || { echo "[ERROR] php-fpm not found"; exit 1; }
command -v nginx >/dev/null 2>&1 || { echo "[ERROR] nginx not found"; exit 1; }
echo "[INIT] ✓ php-fpm and nginx found"

# Create required directories
echo "[INIT] Creating required directories..."
mkdir -p /var/run/php-fpm /var/log/php-fpm /var/log/nginx /var/lib/nginx/tmp
echo "[INIT] ✓ Directories created"

# Validate nginx configuration
echo "[INIT] Validating nginx configuration..."
if ! nginx -t 2>&1 | head -5; then
    echo "[ERROR] Nginx configuration invalid"
    exit 1
fi
echo "[INIT] ✓ Nginx configuration valid"

# Start PHP-FPM
echo "[INIT] Starting PHP-FPM..."
if php-fpm -y /usr/local/etc/php-fpm.conf -D; then
    echo "[INIT] ✓ PHP-FPM started"
else
    echo "[ERROR] PHP-FPM failed to start"
    echo "[DEBUG] Trying direct invocation..."
    php-fpm -D || true
    sleep 1
fi

# Verify PHP-FPM is running
echo "[INIT] Verifying PHP-FPM..."
if ps aux | grep -v grep | grep -q 'php-fpm: master'; then
    echo "[INIT] ✓ PHP-FPM is running"
else
    echo "[WARN] PHP-FPM might not be running, continuing anyway..."
fi

# Wait for PHP-FPM to be ready
echo "[INIT] Waiting for PHP-FPM to initialize..."
sleep 2

# Start nginx in foreground
echo "[INIT] Starting nginx in foreground..."
echo "[INIT] =========================================="
echo "[INIT] Application ready on port 8080"
echo "[INIT] =========================================="
exec nginx -g 'daemon off;'
