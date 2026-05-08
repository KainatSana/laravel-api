#!/bin/sh

echo "[TEST] Container started at $(date)"
echo "[TEST] Running as user: $(whoami)"
echo "[TEST] Current directory: $(pwd)"

# Test 1: Check if nginx exists
if command -v nginx > /dev/null 2>&1; then
  echo "[TEST] ✓ Nginx found: $(which nginx)"
else
  echo "[TEST] ✗ Nginx NOT found"
  exit 1
fi

# Test 2: Try to start nginx with a test
echo "[TEST] Testing nginx syntax..."
nginx -t

# Test 3: Start nginx
echo "[TEST] Starting nginx..."
exec nginx -g 'daemon off;'
