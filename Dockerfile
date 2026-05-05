# ============================================================================
# MULTI-STAGE DOCKERFILE - LARAVEL 8 API
# ============================================================================

# STAGE 1: BUILDER (Shared dependencies)
FROM php:8.1-fpm-alpine AS builder

WORKDIR /app

# Install system dependencies + composer download
RUN apk add --no-cache curl git

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Download and install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');" && \
    composer --version

# Copy application code
COPY . .

# Install dependencies (skip scripts to avoid artisan errors during build)
RUN composer install --no-dev --no-interaction --prefer-dist --no-scripts 2>&1 || true

# ============================================================================
# STAGE 2: DEVELOPMENT (With debug tools)
# ============================================================================
FROM php:8.1-fpm-alpine AS development

WORKDIR /app

# Install system packages + composer
RUN apk add --no-cache curl git vim bash

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

# Copy from builder
COPY --from=builder /app /app

# Development settings
ENV APP_ENV=local
ENV APP_DEBUG=true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:9000/health || exit 1

# ============================================================================
# STAGE 3: STAGING (Optimized)
# ============================================================================
FROM php:8.1-fpm-alpine AS staging

WORKDIR /app

# Install system packages
RUN apk add --no-cache curl git

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Install Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    php -r "unlink('composer-setup.php');"

# Copy from builder
COPY --from=builder /app /app

# Staging settings
ENV APP_ENV=staging
ENV APP_DEBUG=false

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:9000/health || exit 1

# ============================================================================
# STAGE 4: PRODUCTION (Minimal, optimized)
# ============================================================================
FROM php:8.1-fpm-alpine AS production

WORKDIR /app

# Install PHP extensions (OPcache for performance)
RUN docker-php-ext-install pdo_mysql opcache

# Copy from builder
COPY --from=builder /app /app

# Security: Run as non-root user
RUN chown -R www-data:www-data /app
USER www-data

# Production settings
ENV APP_ENV=production
ENV APP_DEBUG=false

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost:9000/health || exit 1
