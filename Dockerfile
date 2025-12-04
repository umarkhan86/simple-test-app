# Use official PHP 8.2 with Apache
FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies (includes all packages needed for client's composer.json)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions (required by Laravel 9 + client packages)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mbstring \
        exif \
        pcntl \
        bcmath \
        gd \
        zip \
        intl \
        opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure Apache DocumentRoot to point to Laravel's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Configure Apache for Laravel (allow .htaccess)
RUN echo '<Directory /var/www/html/public>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' > /etc/apache2/conf-available/laravel.conf \
    && a2enconf laravel

# Copy application code
COPY . /var/www/html

# Fix git ownership issue
RUN git config --global --add safe.directory /var/www/html || true

# Install Composer dependencies
# Note: Uses --no-scripts to avoid .env parsing issues during build
RUN composer install --optimize-autoloader --no-dev --no-interaction --prefer-dist --no-scripts \
    && composer dump-autoload --optimize --no-dev

# Create necessary directories and set permissions
RUN mkdir -p storage/logs \
             storage/framework/sessions \
             storage/framework/views \
             storage/framework/cache \
             storage/app/public \
             bootstrap/cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Create startup script to handle runtime tasks
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "Starting Laravel Application..."\n\
\n\
# Ensure .env exists\n\
if [ ! -f /var/www/html/.env ]; then\n\
    echo "Warning: .env not found, copying from .env.example"\n\
    cp /var/www/html/.env.example /var/www/html/.env\n\
    php /var/www/html/artisan key:generate --force\n\
fi\n\
\n\
# Create storage link if it does not exist\n\
if [ ! -L /var/www/html/public/storage ]; then\n\
    php /var/www/html/artisan storage:link || true\n\
fi\n\
\n\
# Run Laravel optimization (only if .env is valid)\n\
php /var/www/html/artisan config:cache || echo "Config cache failed, continuing..."\n\
php /var/www/html/artisan route:cache || echo "Route cache failed, continuing..."\n\
php /var/www/html/artisan view:cache || echo "View cache failed, continuing..."\n\
\n\
# Fix permissions one more time\n\
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache\n\
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache\n\
\n\
echo "Laravel Application Ready!"\n\
\n\
# Start Apache in foreground\n\
exec apache2-foreground\n\
' > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

# Health check for ALB/ECS
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port 80
EXPOSE 80

# Use custom startup script
CMD ["/usr/local/bin/start.sh"]
