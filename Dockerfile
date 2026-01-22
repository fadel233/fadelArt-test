# ========= Base commune =========
FROM dunglas/frankenphp:1-php8.3-alpine AS base
WORKDIR /app

RUN apk add --no-cache \
    icu-dev oniguruma-dev libzip-dev zlib-dev libpng libpng-dev \
    postgresql-dev git bash \
 && docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql pdo_pgsql opcache \
 && apk del libpng-dev || true

ARG INSTALL_XDEBUG=false
RUN if [ "$INSTALL_XDEBUG" = "true" ]; then \
      apk add --no-cache $PHPIZE_DEPS \
      && pecl install xdebug \
      && docker-php-ext-enable xdebug ; \
    fi

COPY ./Caddyfile /etc/caddy/Caddyfile
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# ========= Image Dev =========
FROM base AS dev
ENV APP_ENV=dev
EXPOSE 8080
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]

# ========= Image Prod =========
FROM base AS prod
ENV APP_ENV=prod

COPY ./app /app

RUN composer install --no-dev --optimize-autoloader \
 && php bin/console cache:clear --env=prod \
 && php bin/console cache:warmup --env=prod

EXPOSE 8080
CMD ["sh", "-c", "php bin/console doctrine:migrations:migrate --no-interaction && frankenphp run --config /etc/caddy/Caddyfile"]

# ========= Default pour Railway =========
FROM prod