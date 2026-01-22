# ========= BASE =========
FROM dunglas/frankenphp:1-php8.3-alpine AS base

WORKDIR /app

RUN apk add --no-cache \
    icu-dev oniguruma-dev libzip-dev zlib-dev git bash \
 && docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql opcache

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY Caddyfile /etc/caddy/Caddyfile


# ========= PROD =========
FROM base AS prod

ENV APP_ENV=prod
ENV APP_DEBUG=0

# ⚠️ Symfony est à la racine /app
COPY app/ /app

RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

RUN php bin/console cache:clear \
 && php bin/console cache:warmup

EXPOSE 8080

CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
