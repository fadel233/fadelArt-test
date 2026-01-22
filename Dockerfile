# ========= Base commune =========
FROM dunglas/frankenphp:1-php8.3-alpine AS base

WORKDIR /app

RUN apk add --no-cache \
    icu-dev oniguruma-dev libzip-dev zlib-dev libpng libpng-dev git bash \
 && docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql opcache \
 && apk del libpng-dev || true

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY ./Caddyfile /etc/caddy/Caddyfile

# ========= PROD =========
FROM base AS prod

ENV APP_ENV=prod
ENV APP_DEBUG=0

COPY app/ /app


RUN composer install \
    --no-dev \
    --optimize-autoloader \
    --no-interaction

RUN php bin/console cache:clear \
 && php bin/console cache:warmup

EXPOSE 8080
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

# ========= DEV =========
FROM base AS dev
ENV APP_ENV=dev
EXPOSE 8080
CMD sh -c "php bin/console doctrine:migrations:migrate --no-interaction || true && frankenphp run --config /etc/caddy/Caddyfile"

