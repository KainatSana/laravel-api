# Stage 1: BUILDER - Install dependencies once
FROM php:8.1-fpm-alpine AS builder

WORKDIR /app

RUN apk add --no-cache curl git

RUN docker-php-ext-install pdo_mysql

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

COPY composer.json composer.lock ./

RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts

COPY . .

# Stage 2: DEVELOPMENT - For local development with debug tools
FROM php:8.1-fpm-alpine AS development

WORKDIR /app

RUN apk add --no-cache vim bash nginx

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

# Stage 3: STAGING - Production-like testing environment
FROM php:8.1-fpm-alpine AS staging

WORKDIR /app

RUN apk add --no-cache nginx

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

# Stage 4: PRODUCTION
FROM php:8.1-fpm-alpine AS production

WORKDIR /app

RUN apk add --no-cache nginx curl jq

RUN docker-php-ext-install pdo_mysql opcache

COPY --from=builder /app /app

COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

RUN mkdir -p /var/log/nginx /var/log/php-fpm /var/run/php-fpm && \
    chown -R www-data:www-data /app /var/log/nginx /var/log/php-fpm /var/lib/nginx

ENV APP_ENV=production
ENV APP_DEBUG=false
ENV LOG_CHANNEL=stackdriver
ENV PORT=8080

EXPOSE 8080

# Run as root to allow port binding
# USER www-data

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
