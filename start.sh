#!/bin/sh

echo "Starting PHP-FPM..."
php-fpm -D

echo "PHP-FPM started. Starting Nginx..."
exec nginx -g "daemon off;"
