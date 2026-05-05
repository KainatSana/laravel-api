# ============================================================================
# MULTI-STAGE DOCKERFILE - Laravel 8 API
# Build: docker build --target=development -t laravel:dev .
#        docker build --target=staging -t laravel:staging .
#        docker build --target=production -t laravel:prod .
# ============================================================================

# STAGE 1: BUILDER (Shared dependencies)
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
# STAGE 2: DEVELOPMENT (With debug tools, Nginx on port 8080)
# ============================================================================
FROM php:8.1-fpm-alpine AS development

WORKDIR /app

RUN apk add --no-cache curl git vim bash nginx

RUN docker-php-ext-install pdo_mysql

COPY --from=builder /app /app

COPY docker/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /app /var/log/nginx /var/lib/nginx

ENV APP_ENV=local
ENV APP_DEBUG=true
ENV PORT=8080

EXPOSE 8080

USER www-data

CMD sh -c "php-fpm -D && exec nginx -g 'daemon off;'"

# ============================================================================
# STAGE 3: STAGING (Optimized, production-like)
# ============================================================================
FROM php:8.1-fpm-alpine AS staging

WORKDIR /app

RUN apk add --no-cache curl git nginx

RUN docker-php-ext-install pdo_mysql

COPY --from=builder /app /app

COPY docker/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /app /var/log/nginx /var/lib/nginx

ENV APP_ENV=staging
ENV APP_DEBUG=false
ENV PORT=8080

EXPOSE 8080

USER www-data

CMD sh -c "php-fpm -D && exec nginx -g 'daemon off;'"

# ============================================================================
# STAGE 4: PRODUCTION (Minimal, optimized, secure)
# ============================================================================
FROM php:8.1-fpm-alpine AS production

WORKDIR /app

RUN apk add --no-cache nginx

RUN docker-php-ext-install pdo_mysql opcache

COPY --from=builder /app /app

COPY docker/nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /app /var/log/nginx /var/lib/nginx

ENV APP_ENV=production
ENV APP_DEBUG=false
ENV PORT=8080

EXPOSE 8080

USER www-data

CMD sh -c "php-fpm -D && exec nginx -g 'daemon off;'"
