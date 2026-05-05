# ============================================================================
# CLOUD RUN - Single container with Nginx + PHP-FPM
# ============================================================================

FROM php:8.1-fpm-alpine AS builder

WORKDIR /app

RUN apk add --no-cache curl git

RUN docker-php-ext-install pdo_mysql

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

COPY . .

RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts 2>&1 || true

# ============================================================================
FROM php:8.1-fpm-alpine

WORKDIR /app

# Install Nginx
RUN apk add --no-cache nginx

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql opcache

# Copy from builder
COPY --from=builder /app /app

# Copy Nginx config
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Create nginx log directory
RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /app /var/log/nginx /var/lib/nginx

ENV APP_ENV=production
ENV APP_DEBUG=false
ENV PORT=8080

EXPOSE 8080

USER www-data

CMD ["/usr/local/bin/start.sh"]
