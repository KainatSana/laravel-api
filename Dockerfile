# ============================================================================
# MULTI-STAGE DOCKERFILE - SIMPLIFIED FOR LARAVEL 8 API
# ============================================================================
# 4 Stages: builder, development, staging, production
# Build: docker build --target=development -t laravel:dev .
# ============================================================================

# STAGE 1: BUILDER (Shared dependencies)
FROM php:8.1-fpm-alpine AS builder

WORKDIR /app

# Install minimal required packages
RUN apk add --no-cache curl git

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Copy application code
COPY . .

# ============================================================================
# STAGE 2: DEVELOPMENT (With debug tools)
# ============================================================================
FROM php:8.1-fpm-alpine AS development

WORKDIR /app

# Install system packages + debug tools
RUN apk add --no-cache curl git vim bash

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Copy from builder
COPY --from=builder /app /app

# Development settings
ENV APP_ENV=local
ENV APP_DEBUG=true

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# ============================================================================
# STAGE 3: STAGING (Optimized, production-like)
# ============================================================================
FROM php:8.1-fpm-alpine AS staging

WORKDIR /app

# Install minimal packages
RUN apk add --no-cache curl git

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql

# Copy from builder
COPY --from=builder /app /app

# Staging settings
ENV APP_ENV=staging
ENV APP_DEBUG=false

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# ============================================================================
# STAGE 4: PRODUCTION (Minimal, secure, optimized)
# ============================================================================
FROM php:8.1-fpm-alpine AS production

WORKDIR /app

# Install OPcache for performance
RUN docker-php-ext-install pdo_mysql opcache

# Copy from builder
COPY --from=builder /app /app

# Security: Run as non-root user (www-data user already exists in php:8.1-fpm-alpine)
RUN chown -R www-data:www-data /app
USER www-data

# Production settings
ENV APP_ENV=production
ENV APP_DEBUG=false

# Health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD curl -f http://localhost/health || exit 1
