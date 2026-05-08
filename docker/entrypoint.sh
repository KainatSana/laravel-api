#!/bin/sh
# Start PHP-FPM and nginx for Laravel

echo "Starting PHP-FPM..."
php-fpm -D

echo "Waiting for PHP-FPM to initialize..."
sleep 2

echo "Starting nginx..."
exec nginx -g 'daemon off;'
