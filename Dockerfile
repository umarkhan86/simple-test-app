# Use official PHP 8.2 with Apache
FROM php:8.2-apache

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
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

# Install PHP extensions required by Laravel and your packages
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

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Configure Apache DocumentRoot to point to Laravel's public directory
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Copy application code first
COPY . /var/www/html

# Fix git ownership issue for Composer
RUN git config --global --add safe.directory /var/www/html || true

# Install Composer dependencies
RUN composer install --optimize-autoloader --no-dev --no-interaction --prefer-dist

# Create necessary directories and set permissions
RUN mkdir -p storage/logs storage/framework/{sessions,views,cache} bootstrap/cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache

# The .env file will be copied during docker build from GitHub Actions
# Verify .env exists, if not create from example (fallback)
RUN if [ ! -f .env ]; then \
        echo "Warning: .env not found, using .env.example"; \
        cp .env.example .env; \
    fi

# Run Laravel optimization commands
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Health check for ECS
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port 80
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
