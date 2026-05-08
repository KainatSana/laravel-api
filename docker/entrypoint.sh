#!/bin/sh
# Start PHP-FPM and nginx for Laravel

echo "Starting PHP-FPM with custom config..."
php-fpm -c /usr/local/etc/php-fpm.conf -D

echo "Waiting for PHP-FPM to initialize..."
sleep 2

echo "Starting nginx..."
exec nginx -g 'daemon off;'
