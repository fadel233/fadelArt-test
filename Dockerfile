# ========= Base commune =========
FROM dunglas/frankenphp:1-php8.3-alpine AS base
WORKDIR /app

# Paquets système
RUN apk add --no-cache \
    icu-dev oniguruma-dev libzip-dev zlib-dev libpng libpng-dev git bash \
 && docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) intl pdo_mysql opcache \
 && apk del libpng-dev || true

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Xdebug optionnel
ARG INSTALL_XDEBUG=false
RUN if [ "$INSTALL_XDEBUG" = "true" ]; then \
      apk add --no-cache $PHPIZE_DEPS \
      && pecl install xdebug \
      && docker-php-ext-enable xdebug ; \
    fi

# Caddyfile
COPY ./Caddyfile /etc/caddy/Caddyfile

# ========= Image Dev =========
FROM base AS dev

# ✅ COPIER LE CODE SYMFONY
COPY ./app /app

# ✅ INSTALLER LES DÉPENDANCES
RUN composer install --no-dev --optimize-autoloader --no-interaction

# ✅ CRÉER LES DOSSIERS NÉCESSAIRES
RUN mkdir -p /app/var/cache /app/var/log \
    && chown -R www-data:www-data /app/var

EXPOSE 8080
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
